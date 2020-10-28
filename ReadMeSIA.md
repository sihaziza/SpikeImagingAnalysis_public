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
pull the newest `develop` branch from `VoltageImagingAnalysis`
pull the newest `develop` branch from the our standard dependency which is `MicroscopesRecording` repo.

# Folders
All in-progress scripts and pieces of code may be in the `private` folder.

## Packages
folders with "+" prefix 

## Classes 
folders with "@" prefix

## Rules for new functions
- Use functionTemplate to generate new functions
- clear description how to use with some examples
- author (who to blame for bugs :) )

## Frame dropping
For now to deal with single files (you can make your loop for batch processing) just execute:
             obj=Timestamps() - opens a file open dialog for DCIMG file
or
             obj=Timestamps(dcimg_filepath)

a class will make a quick analysis:
             dcimg_filepath: 'D:\recData.dcimg'
         timestamp_filepath: 'D:\recData.dcimg.txt'
                 timestamps: [3550×1 double]
                     fpsvec: [3549×1 double]
                 median_fps: 200.4410
                     jitter: 4.1755e-04
         frames_dropped_vec: [3549×1 double]
           frames_dropped_n: 23
    frames_dropped_fraction: 0.0065

and make a summary plot and export. 

obj.frames_dropped_vec > 0 - will give you the frame indices where frame dropping occurred and how many frames has been dropped. 

You don't have use the class itself and you may generate a time stamp file executing a command:
`Timestamps.generate_stamps(dcimg_filepath)`

then you can import a generated file using `time_stamp_vector=Timestamps.import_stamps(time_stamps_filepath)`

you can also do a batch conversion in the whole hard drive or folder using Timestamps.convertDCIMGInFolder(folderpath)

