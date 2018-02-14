# Menu Title: Annotate Hidden Data
# Needs Case: true
# Needs Selected Items: false

script_directory = File.dirname(__FILE__)
require File.join(script_directory,"Nx.jar")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.CustomDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

# Build settings dialog
dialog = TabbedCustomDialog.new("Annotate Hidden Data")

main_tab = dialog.addTab("main_tab","Main")
main_tab.appendCheckBox("apply_tags","Apply Tags",true)
main_tab.appendTextField("tag_prefix","Tag Prefix","HiddenData|")
main_tab.enabledOnlyWhenChecked("tag_prefix","apply_tags")
main_tab.appendCheckBox("apply_custom_metadata","Apply Custom Metadata",true)
main_tab.appendTextField("custom_field_name","Field Name","Hidden Data")
main_tab.enabledOnlyWhenChecked("custom_field_name","apply_custom_metadata")

# Define settings dialog validations
dialog.validateBeforeClosing do |values|
	if values["apply_custom_metadata"] && values["custom_field_name"].strip.empty?
		CommonDialogs.showWarning("Please provide a field name for custom metadata.")
		next false
	end

	# Get user confirmation about closing all workbench tabs
	if values["apply_custom_metadata"] && CommonDialogs.getConfirmation("The script needs to close all workbench tabs, proceed?") == false
		next false
	end

	next true
end

# Display settings dialog
dialog.display

# Do work
if dialog.getDialogResult == true
	# Tagging and custom metadata may perform better when all workbench tab
	# have first been closed
	$window.closeAllTabs
	
	# Get settings dialog values and store them in more convenient variables
	values = dialog.toMap
	apply_tags = values["apply_tags"]
	tag_prefix = values["tag_prefix"]
	apply_custom_metadata = values["apply_custom_metadata"]
	custom_field_name = values["custom_field_name"]
	
	annotater = $utilities.getBulkAnnotater

	hidden_regex = /hidden/i
	count_regex = /count/i
	delimiter = "; "

	# We will be grouping items by tag and custom metadata value to be
	# applied so we can do this in bulk later
	grouped_by_hidden_properties = Hash.new{|h,k|h[k] = []}
	grouped_by_hidden_property = Hash.new{|h,k|h[k] = []}

	ProgressDialog.forBlock do |pd|
		pd.setTitle("Annotate Hidden Data")
		break if pd.abortWasRequested

		pd.setMainStatusAndLogIt("Locating items which might have hidden data...")
		potential_hidden_data_items = $current_case.searchUnsorted("properties:\"hidden\"")

		pd.setMainStatusAndLogIt("Scanning items for hidden data properties...")
		pd.setMainProgress(0,potential_hidden_data_items.size)
		potential_hidden_data_items.each_with_index do |item,index|
			# Get properties hash/map for this item
			item_properties = item.getProperties

			# Track names that match our criteria
			name_matches = []

			# Look through property names on this item for ones we're interested in
			item_properties.each do |name,value|
				next if value.nil?           # Ignore properties with nil value
				next if name !~ hidden_regex # Only properties with 'hidden' in name
				next if name =~ count_regex  # Ignore properties like 'Excel Hidden Sheets Count'

				if value == true
					name_matches << name
				end
			end

			# If we had some properties with a matching name and appropriate value
			# then lets record this as having hidden data
			if name_matches.size > 0
				if apply_custom_metadata
					# We will record the actual custom metadata later in bulk
					key = name_matches.sort.join(delimiter)
					grouped_by_hidden_properties[key] << item
				end
				if apply_tags
					# We will record the tags later in bulk
					name_matches.each do |match|
						grouped_by_hidden_property[match] << item
					end
				end
			end
			pd.setMainProgress(index+1)
		end

		if apply_custom_metadata
			# Apply custom metadata in bulk
			pd.setMainStatusAndLogIt("Applying custom metadata...")
			current = 0
			total = grouped_by_hidden_properties.size
			pd.setMainProgress(0,total)
			grouped_by_hidden_properties.each do |key,items|
				pd.setSubStatusAndLogIt("Applying '#{key}' to #{items.size} items...")
				pd.setSubProgress(0,items.size)
				annotater.putCustomMetadata(custom_field_name,key,items) do |info|
					pd.setSubProgress(info.getStageCount)
				end
				current += 1
				pd.setMainProgress(current)
			end
		end

		if apply_tags
			# Apply tags in bulk
			pd.setMainStatusAndLogIt("Applying tags...")
			grouped_by_hidden_property.each do |property,items|
				pd.setSubProgress(0,items.size)
				tag = "#{tag_prefix}#{property}"
				pd.setSubStatusAndLogIt("Applying tag '#{tag}' to #{items.size} items...")
				annotater.addTag(tag,items) do |info|
					pd.setSubProgress(info.getStageCount)
				end
			end
		end

		pd.setCompleted

		# Since we closed all the workbench tabs we should open a new one for the user
		query = ""
		if apply_tags
			query = "tag:\"#{tag_prefix}*\""
		elsif apply_custom_metadata
			query = "custom-metadata:\"#{custom_field_name}\":*"
		end

		$window.openTab("workbench",{:search=>query})
	end
end