%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% DUPLEX Paper - Spike Imaging Analysis Pipeline %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script runs a demo raw file (.dcimg; proprietary format) and proeed
% with the following steps:
%   > gather metadata and create all diagnostic paths. (see metadata
%   > loading .dcimg file based off the metadata file and save as .h5
%   > motion correction (based off NoRMcorr - github package)
%   > demixing (EXTRACT - Dinc et al, BioRxiv 2021)
% At the end, a .mat file is saved with the spatiotemporal filters for each
% detected neurons.

% Follow the workspace prompt as user input will be required... ;-)

%% INPUT PATH TO .dcimg FILE

mainFolder='D:\GEVI_Spike\Raw\Spontaneous\mRL000';

% find all dcimg path and remove duplicates at G&R dcimg are in the same folder
dcimgFileList = dir(fullfile(mainFolder, '**\*.dcimg'));
a= {dcimgFileList.folder}';
[~,idx]=unique(a,'stable');
dcimgFileList=dcimgFileList(idx);

if isempty(dcimgFileList)
    error('no extract output file detected in any subfolder')
end

for i=1%:numel(dcimgFileList)
    try
        dcimgPath=fullfile(dcimgFileList(i).folder);
        
        % GENERATING ALL PATH
        [allPaths]=setExportPath(dcimgPath);
        
        % GENERATING ALL METADATA
        [metadata]=getRawMetaData(allPaths,...
            'frameRange',[100 inf],...
            'softwareBinning',2,...
            'loadTTL',true);%
        
%    	metadata.frameRange(1)=round(0.5*metadata.fps);
    save(allPaths.metadataPath,'metadata');
         
    catch
    end
    close all;
end

%% LOAD AND CONVERT .dcimg RAW MOVIE

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
        bandPassMovieChunk(metadata.allPaths.h5PathG,metadata.vectorBandPassFilter);
        
        % CORRECT THE MOVIE FROM MOTION ARTEFACTS
        pathG=strrep(metadata.allPaths.h5PathG,'.h5', '_bp.h5');
        motionCorr1Movie(pathG);
        
        % DETREND the movie
        pathG=strrep(metadata.allPaths.h5PathG, '.h5','_bp_moco.h5');
        detrending(pathG,'samplingRate',metadata.fps,'spatialChunk',true);
        
        % DEMIX THE MOVIE TO FIND SINGLE NEURONS
        pathG=strrep(metadata.allPaths.h5PathG,'.h5','_bp_moco.h5');
        tic;runEXTRACT(pathG,'polarityGEVI','neg','cellRadius',7,'removeBackground',true,'method','robust');toc;
        
    catch ME
    end
end

%% MANUAL CURING OF EXTRACT OUTPUT
% the function will run recursively through all EXTRACT output file found
% in all subfolders from the parent path 'mainFolder'

cleanExtractFiles(mainFolder);

%%
