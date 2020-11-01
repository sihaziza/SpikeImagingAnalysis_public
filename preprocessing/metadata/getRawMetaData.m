function [metadata]=getRawMetadata(allPaths,varargin)
% [metadata]=getMetaData(folderpath)
% [metadata]=getMetaData(folderpath,'parameter',value,...)
%
% Created by Simon Haziza & Radek Chrapkiewicz, Stanford University, 2019

%% SET ALL OPTIONS
[options]=metadataStructure();

%% CHECK FOR USER-DEFINED OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end

%% GATHER ALL METADATA

metadata=options;
metadata.allPaths=allPaths;

% Find DCIMG files
fileName=dir(fullfile(allPaths.dcimgPath,'*.dcimg')); % G always comes before R
if size(fileName.name,1)==2
    [green, red]=fileName.name;
elseif size(fileName.name,1)==1
    [green]=fileName.name;
else
    error('Oups... no dcimg file detected');
end
metadata.fileName=fileName;

% Read just the 32-bit header information of HAMAMATSU .dcimg file
fileName=fullfile(allPaths.dcimgPath,green);
fid = fopen(fileName,'rb');
dcimgMeta = fread(fid,202,'uint32=>uint32');
fclose(fid);
% Compatible with ORCA Flash and ORCA Fusion
width = max(dcimgMeta(49),dcimgMeta(147)); % index 47: x dim
height = max(dcimgMeta(48),dcimgMeta(148)); % index 48: y dim
nFrame = max(dcimgMeta(44),dcimgMeta(144)); % index 44: number of frames

metadata.frameDimension=[width height]; % in pixel
metadata.totalFrames=nFrame;
metadata.rawDimension=[metadata.frameDimension metadata.totalFrames];
fprintf('Movie Dimension: %1.0f x %1.0f x %1.0f pixels \n', metadata.rawDimension);

% Detect Sampling Rate
try
    A=fileread(fullfile(allPaths.dcimgPath,options.LVSettingsFile)); 
    B=strfind(A, 'Internal frame rate');
    metadata.fps=round(str2double(A(B+38:B+42))); % in Hz
    fprintf('Frame Rate: %1.0f Hz \n', metadata.fps);
catch
    warning('Cannot detect sampling rate');
end

% Detect Hardware Binning
try
    A=fileread(fullfile(allPaths.dcimgPath,options.LVSettingsFile)); B=strfind(A, 'Binning (px)');
    metadata.hardwareBinning=str2double(A(B+26:B+26));
    fprintf('Hardware Binning: %1.0f \n',metadata.hardwareBinning);
catch
    warning('Cannot detect Hardware Binning - use 1 by default...');
end

metadata.totalBinning=metadata.softwareBinning*metadata.hardwareBinning;

% Detect depth of imaging
try
    strpattern='Depth (um)</Name>';
    A=fileread(fullfile(allPaths.dcimgPath,options.LVSettingsFile)); B=strfind(A, strpattern);
    metadata.depth=str2double(A(B+length(strpattern)+7:B+length(strpattern)+13));
    fprintf('Depth: %1.0f %sm \n',metadata.depth,char(181));
catch
    warning('Cannot detect depth of imaging');
end

% Load TTL file if needed
if metadata.loadTTL
    try
        Nametemp=dir('*_framestamps 0.txt');
        [TTL]=importdata(Nametemp.name);
        metadata.TTL=TTL(metadata.FramesRequested,4);
    catch
        warning('Cannot detect TTL file');
    end
end

% Memory Settings
[userview,~] = memory;
metadata.availableRAM=userview.MaxPossibleArrayBytes/(1024^3);
metadata.rawFileSize=prod(metadata.rawDimension)*16/8/(1024)^3;

% Determine whether to load in chunk or not
if metadata.rawFileSize>0.5*metadata.availableRAM
    metadata.chunking=true;
    warning('File too big for the RAM - loading in chunk')
%     metadata.chunksNumber=3*ceil((metadata.rawFileSize/metadata.availableRAM));
%     metadata.ChunksVector=uint32(linspace(metadata.FramesRequested(1)-1,metadata.FramesRequested(2),metadata.ChunksNumber+1));
end

% Compute the best ROI to remove useless dark portion of the movie
if options.autoCropping
    
    metadata.autoCropping=options.autoCropping;
    % Auto-crop green and red channel independently prior to registration
    fileName=fullfile(metadata.dataPath,green);
    [imGreen,~]= dcimgmatlab(metadata.totalFrames-1, fileName); %dcimg counts from 0
    % always transpose to make it consistent with ORCA
    % always single to reach better resolution
    imGreen=single(imGreen');
    imGreen=imresize(imGreen,1/metadata.softwareBinning,'Method','box','Antialiasing',true);
    [imGreenCrop, metadata.ROI.greenChannel] = autoCropImage(imGreen);
    
    fileName=fullfile(metadata.dataPath,red);
    [imRed,~]= dcimgmatlab(metadata.totalFrames-1, fileName); %dcimg counts from 0
    imRed=single(imRed');
    imRed=imresize(imRed,1/metadata.softwareBinning,'Method','box','Antialiasing',true);
    [imRedCrop,metadata.ROI.redChannel] = autoCropImage(imRed);
    
    % Diagnostic Output
    if options.plot
        h=figure;
        subplot(2,2,1)
        imshow(imGreen,[])
        title('Green Raw')
        subplot(2,2,2)
        imshow(imRed,[])
        title('Red Raw')
        
        subplot(2,2,3)
        imshow(imGreenCrop,[])
        title('Green Cropped')
        subplot(2,2,4)
        imshow(imRedCrop,[])
        title('Red Cropped')
        
        suptitle('Auto-Cropping quality on the last requested frame')
        if options.savePath
            export_figure(h,'autoCrop',options.savePath);close;
        end
    end   
    
end

save(allPaths.metadataPath,'metadata');

disps('Metadata succesfully loaded')

    function disps(string) %overloading disp for this function - this function should be nested
        %         temp=mfilename('fullpath');
        %         [~,FUNCTION_NAME,~]=fileparts(temp);
        FUNCTION_NAME='getRawMetaData';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end
end

function [metadata]=metadataStructure()

metadata.LVSettingsFile='allsettings.txt';
metadata.savePath=[];
metadata.verbose=true;
metadata.plot=true;

% Channels Settings
metadata.dataPath=[];
metadata.fileName=[];

% Acquisition Settings
metadata.fps=[]; % in Hz
metadata.frameDimension=[]; % in pixel
metadata.totalFrames=[];
metadata.dimension=[];
metadata.depth=[];
metadata.hardwareBinning=1; % usually - taken as default

% Loading Settings
metadata.softwareBinning=1; % by default
metadata.totalBinning=[];
metadata.autoCropping=false;
metadata.ROI=[]; % for autocroping; DCIMG and Matlab XY convention inverted
metadata.vectorBandPassFilter=[];% to estime best filer for reg & moco

% TTL for behavior sync
metadata.loadTTL=false;
metadata.TTL=[];

% % Chunking option, all auto-determined
% metadata.Chunking=false; % no chunking by default
% metadata.ChunksNumber=[];
% metadata.ChunksVector=[];
% metadata.LoadedFramesperChunk=[]; % full or chunk window
% metadata.DimensionLoadedperChunk=[];
%
% % Memory Settings
% metadata.memoryAvailable=[];
% metadata.FileSizeRaw=[];
% metadata.FileSizeLoaded=[];
% metadata.FileSizeLoadedperChunk=[];
% metadata.FileSizeProcessed=[];

% % Export settings
% metadata.dcimgPath=[];
% metadata.h5Path=[];
% metadata.diagnosticLoading=[];
% metadata.diagnosticRegistration=[];
% metadata.diagnosticMotionCorr=[];
% metadata.diagnosticUnmixing=[];
end


