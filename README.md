# SpikeImagingAnalysis
Software to analyze single color, dual-color and dual-polarity in vivo spike imaging.

Run `installSIA.m` to install all relevant folders for a functionnal package.

# Structure of this repository
## Philosophy of the structure:
- the core function exist independently and have clear input - output definitions.
- the core functions should be grouped and have specific name spaces unless they 
are super frequently used or don't logicially belong to any of the name spaces.
- They may be part of packages with a specific name space such as `+unmixing.standarize`
- they may be Static methods of some parent master class.
## To avoid:
- putting functions in subfolders that should be added manually to the path. 
- adding all the subfolders to the path is a bad practice. 

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

# Updates
- 2020-11-01 - creation of the SpikeImagingAnalysis repository by Simon Haziza, based off of the VoltageImagingAnalysis developed by 
Radek Chrapkievicz, Jizhou Li and Simon Haziza. 
