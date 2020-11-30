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

mainFolder='B:\GEVI_Spike\Raw\Whiskers';
mouse={'m83' 'm84' 'm85'};

% date='20200416';
for iMouse=1:length(mouse)
    dcimgPathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(dcimgPathMain,'2020*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(dcimgPathMain,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
        for iFolder=1:length(folderName)
            try
                dcimgPath=fullfile(dcimgPathMain,date,folderName{iFolder});

% GENERATING ALL PATH               
[allPaths]=setExportPath(dcimgPath);

% GENERATING ALL METADATA
[metadata]=getRawMetadata(allPaths,...
    'frameRange',[100 inf],...
    'softwareBinning',1,...
    'croppingMethod','manual',... 
    'loadTTL',true);
            end
        end
    end
end

%% LOAD AND CONVERT .dcimg RAW MOVIE

mainFolder='F:\GEVI_Spike\Preprocessed\Whiskers';
mouse={'m83' 'm84' 'm85'};
fail=[];
% date='20200416';
for iMouse=1%:length(mouse)
    metaPathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(metaPathMain,'2020*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(metaPathMain,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
        for iFolder=1%:length(folderName)
            try
metaPath=fullfile(metaPathMain,date,folderName{iFolder});
temp=load(fullfile(metaPath,'metadata.mat'));
metadata=temp.metadata; clear temp;

loading(metadata.allPaths);

% GENERATE THE BANDPASS MOVIE FOR MOTION CORRECTION
% Find the best filter frequency bands - [2 20] is good
% [bpFilter]=findBestFilterParameters(allPaths.h5PathG);
bandPassMovieChunk(metadata.allPaths.h5PathG,metadata.vectorBandPassFilter);
bandPassMovieChunk(metadata.allPaths.h5PathR,metadata.vectorBandPassFilter);

% CORRECT THE MOVIE FROM MOTION ARTEFACTS
pathG=strrep(metadata.allPaths.h5PathG,'.h5', '_bp.h5');
pathR=strrep(metadata.allPaths.h5PathR,'.h5', '_bp.h5');
motionCorr1Movie(pathG);
motionCorr1Movie(pathR);

% DEMIX THE MOVIE TO FIND SINGLE NEURONS 
pathG=strrep(metadata.allPaths.h5PathG, '.h5','_moco.h5');
pathR=strrep(metadata.allPaths.h5PathR, '.h5','_moco.h5');
runPCAICA(pathG,metadata.fps)
runPCAICA(pathR,metadata.fps)

            catch ME
                fail(iFolder)={ME};
            end
        end
    end
end

%% Denoising

mainFolder='F:\GEVI_Spike\Preprocessed\Whiskers';
mouse={'m83' 'm84' 'm85'};
fail=[];
% date='20200416';
for iMouse=1:length(mouse)
    metaPathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(metaPathMain,'2020*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(metaPathMain,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
        for iFolder=1:length(folderName)
            try
metaPath=fullfile(metaPathMain,date,folderName{iFolder});
temp=load(fullfile(metaPath,'metadata.mat'));
metadata=temp.metadata; clear temp;

% DENOISING the Movie
pathG=strrep(metadata.allPaths.h5PathG,'.h5', '_moco.h5');
pathR=strrep(metadata.allPaths.h5PathR,'.h5', '_moco.h5');
denoising1Movie(pathG);
denoising1Movie(pathR);

% DEMIX THE MOVIE TO FIND SINGLE NEURONS - same on denoised movie
pathG=strrep(metadata.allPaths.h5PathG, '.h5','_dns.h5');
pathR=strrep(metadata.allPaths.h5PathR, '.h5','_dns.h5');
runPCAICA(pathG,metadata.fps)
runPCAICA(pathR,metadata.fps)

            catch ME
                fail(iFolder)={ME};
            end
        end
    end
end
