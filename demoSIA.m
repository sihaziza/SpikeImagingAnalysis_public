       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% DUPLEX Paper - Spike Imaging Analysis Pipeline %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
% This script runs a demo raw file (.dcimg; proprietary format) and proeed
% with the following steps:
%   > gather metadata and create all diagnostic paths. (see metadata
%   > loading .dcimg file based off the metadata file and save as .h5
%   > motion correction (based off NoRMcorr - github package)
%   > demixing (based off EXTRACT - Inan, NIPS 2017)
%   > spike-timing estimation (based off MLspikes - Deneux, NatureCom 2016) 
% At the end, a .mat file is saved with the spatiotemporal filters for each
% detected neurons with estimated spike trains.

% Follow the workspace prompt as user input will be required... ;-)

% Pipeline created by Simon Haziza, PhD - Stanford University 2021

%% INPUT PATH TO .dcimg FILE

mainFolder=[where you store .dcimg data];

% find all dcimg path and remove duplicates at G&R dcimg are in the same folder
dcimgFileList = dir(fullfile(mainFolder, '**\*.dcimg'));
a= {dcimgFileList.folder}';
[~,idx]=unique(a,'stable');
dcimgFileList=dcimgFileList(idx);

if isempty(dcimgFileList)
    error('no extract output file detected in any subfolder')
end

for i=1:numel(dcimgFileList)
    try
        dcimgPath=fullfile(dcimgFileList(i).folder);
        
        % GENERATING ALL PATH
        [allPaths]=setExportPath(dcimgPath);
        
        % GENERATING ALL METADATA
        [metadata]=getRawMetaData(allPaths,...
            'frameRange',[1 inf],...
            'softwareBinning',2,...
            'loadTTL',true);%
    catch
    end
    close all;
end


%% PREPROCESSING .dcimg RAW MOVIE based off METADATA file

mainFolder=[where you saved metadata.mat];

% find all dcimg path and remove duplicates at G&R dcimg are in the same folder
metaFileList = dir(fullfile(mainFolder, '**\*metadata.mat'));

if isempty(metaFileList)
    error('no metadata file has been generate > run getRawMetaData.m')
end

for iMeas=1:numel(metaFileList)
    try
        metaPath=fullfile(metaFileList(iMeas).folder,metaFileList(iMeas).name);
        load(metaPath);
        
        % Load & Convert .dcimg data
        loading(metadata.allPaths);
        
        % GENERATE THE BANDPASS MOVIE FOR MOTION CORRECTION
        bandPassMovieChunk(metadata.allPaths.h5PathG);
        
        % CORRECT THE MOVIE FROM MOTION ARTEFACTS
        path=strrep(metadata.allPaths.h5PathG,'.h5', '_bp.h5');
        motionCorr1Movie(path,'nonRigid', false,'isRawInput',false,'dcRemoval',false);

        % DETREND the movie
        path=strrep(metadata.allPaths.h5PathG, '.h5','_bp_moco.h5');
        detrending(path,'samplingRate',metadata.fps,'lpCutOff',0.5,'spatialChunk',true,'binning',2);

        % DEMIX THE MOVIE TO FIND SINGLE NEURONS
        path=strrep(metadata.allPaths.h5PathG,'.h5','_bp_moco_dtr.h5');
        tic;runEXTRACT(path,'polarityGEVI','neg','cellRadius',20);toc;
        
    catch ME
    end
end

%% MANUAL CURING OF EXTRACT OUTPUT
% the function will run recursively through all EXTRACT output file found
% in all subfolders from the parent path 'mainFolder'

mainFolder=[where you saved the extract cleaned .mat structure];
mainFolder='F:\GEVI_Spike\Preprocessed\Spontaneous\m915';
cleanExtractFiles(mainFolder);

%% INFER SPIKE TRAIN
% !!! manual clean should have been done before-hand !!!

mainFolder=[where you saved the extract cleaned .mat structure];

% find all dcimg path and remove duplicates at G&R dcimg are in the same folder
metaFileList = dir(fullfile(mainFolder, '**\*_clean.mat'));

if isempty(metaFileList)
    error('no metadata file has been generate > run getRawMetaData.m')
end

for iFile=1:numel(metaFileList)
    try
        path=fullfile(metaFileList(iFile).folder,metaFileList(iFile).name);
        
        [output]=getSpikesAllNeurons(path);
    catch
    end
end
%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% DUPLEX Paper - Spike Imaging Analysis Pipeline %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
        