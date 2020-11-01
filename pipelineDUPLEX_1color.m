%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% DUPLEX Paper - Spike Imaging Analysis Pipeline %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script runs a demo raw file (.dcimg; proprietary format) and proeed
% with the following steps:
%   > gather metadata and create all diagnostic paths. (see metadata
%   > loading .dcimg file based off the metadata file and save as .h5
%   > motion correction (based off NoRMcorr - github package)
%   > demixing (based off PCA/ICA - Mukamel, Neuron 2009)
% At the end, a .mat file is saved with the spatiotemporal filters for each
% detected neurons.

% Follow the workspace prompt as user input will be required... ;-)

%% INPUT PATH TO .dcimg FILE
dcimgPath='C:\Users\Simon\Desktop\GitHub\SpikeImagingAnalysis\demo\1color';

[allPaths]=setExportPath(dcimgPath);

%% GENERATING ALL METADATA
[metadata]=getRawMetadata(allPaths,'softwareBinning',2);

%% LOAD AND CONVERT .dcimg RAW MOVIE
loading(allPaths,'frameRange',[100 inf]);

%% GENERATE THE BANDPASS MOVIE FOR MOTION CORRECTION

% Find the best filter frequency bands - [2 20] is good
[bpFilter]=findBestFilterParameters(allPaths.h5PathG);

bandPassMovieChunk(allPaths.h5PathG,bpFilter);

%% CORRECT THE MOVIE FROM MOTION ARTEFACTS
path=strrep(allPaths.h5PathG,'.h5', '_bp.h5');
motionCorr1Movie(path);

%% DEMIX THE MOVIE TO FIND SINGLE NEURONS
path=strrep(allPaths.h5PathG, '.h5','_moco.h5');
runPCAICA(path,metadata.fps)



