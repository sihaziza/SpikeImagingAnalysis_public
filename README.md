# SpikeImagingAnalysis
Software for analysis of voltage imaging data acquired by BFM- relevant for dual-color and or dual-polarity in vivo spike recordings

# Updates
- 2020-10-27 - creation of the SpikeImagingAnalysis repository by Simon Haziza, based off of the VoltageImagingAnalysis developed by 
Radek Chrapkievicz, Jizhou Li and Simon Haziza.

# Structure of this repository
## Philosophy of the structure:
- the core function exist independently and have clear input - output definitions.
- the core functions should be grouped and have specific name spaces unless they 
are super frequently used or don't logicially belong to any of the name spaces.
- They may be part of packages with a specific name space such as `+unmixing.standarize`
- they may be Static methods of some parent master class.
## To avoid:
- We should be avoiding putting functions in subfolders that should be added manually to the path. 
- We can do it further down the road, but it should come with the `installBFM.m` function that will do it 
automatically when someone will be installing the whole package.
- adding all the subfolders to the path is a bad practice. 
It often ends up with getting the .git function there too...

# Naming convention

# Branches
- master - currently working version. Merges only through pull requests. 
- develop - feel free to commit on a regular basis

To use it in _develop_ mode:
pull the newest `develop` branch from `SpikeImagingAnalysis`

# Folders
All in-progress scripts and pieces of code may be in the `private` folder.

## Packages
folders with "+" prefix 

## Classes 
folders with "@" prefix

## Rules for new functions
- Use functionTemplateSIA to generate new functions,
- Clear description in the Help section with some examples,
- Author (who to ask for more information and debugging).


