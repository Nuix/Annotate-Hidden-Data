Annotate Hidden Data
====================

![Last tested in Nuix 7.4](https://img.shields.io/badge/Nuix-7.4-green.svg)

View the GitHub project [here](https://github.com/Nuix/Annotate-Hidden-Data) or download the latest release [here](https://github.com/Nuix/Annotate-Hidden-Data/releases).

# Overview

**Written By:** Jason Wells

This script annotates items in a case with hidden data.  The script first locates items with at least one metadata property with a name containing the word `hidden`.  For each of these items each metadata property is checked for:

- Contains the word `hidden`
- Does not contain the word `count`
- Has a value of `true`

If at least one metatdata property is found to meet these conditions, the item is considered to have hidden data.  If applying tags a tag for each qualifying hidden property will be applied to the item.  If applying custom metadata a listing of all qualified fields, delimited by `; ` will be recorded on the item.

# Getting Started

## Setup

Begin by downloading the latest release.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

# License

```
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
