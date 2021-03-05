function [metadata]=getRawMetadata(allPaths,varargin)
% [metadata]=getMetaData(folderpath)
% [metadata]=getMetaData(folderpath,'parameter',value,...)
%
% Created by Simon Haziza, Stanford University, 2019
% To Do > save the file name as well. Usefull for downstream analysis

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
if size(fileName,1)==2
    [green, red]=fileName.name;
elseif size(fileName.name,1)==1
    [green]=fileName.name;
else
    error('Oups... no dcimg file detected');
end
% metadata.fileName=fileName;

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

% parsing frame range
if isempty(metadata.frameRange)
    firstFrame=1;
    lastFrame=metadata.totalFrames;
elseif length(metadata.frameRange)==1
    firstFrame=1;
    lastFrame=metadata.frameRange;
elseif length(metadata.frameRange)==2
    firstFrame=metadata.frameRange(1);
    lastFrame=metadata.frameRange(2);
    if strcmpi(num2str(lastFrame),'inf')
        lastFrame=metadata.totalFrames; 
    end
else
    error('Wrong format of frame range');
end

if lastFrame>metadata.totalFrames
warning('requested last frame exceeds movie length. Truncated to last frame.')   
lastFrame=min(lastFrame,totalFrames);
end

metadata.frameRange=double([firstFrame lastFrame]);

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
        Nametemp=dir(fullfile(allPaths.dcimgPath,'*_framestamps 0.txt'));
        [TTL]=importdata(fullfile(Nametemp.folder,Nametemp.name));
        metadata.TTL=TTL.data(metadata.frameRange(1):metadata.frameRange(2),4);
        metadata.Locomotion=TTL.data(metadata.frameRange(1):metadata.frameRange(2),2);
    catch
        warning('Cannot detect TTL file');
    end
end

% Memory Settings
[userview,~] = memory;
metadata.availableRAM=userview.MaxPossibleArrayBytes/(1024^3);
metadata.rawFileSize=prod(metadata.rawDimension)*16/8/(1024)^3;

% % Determine whether to load in chunk or not
% if metadata.rawFileSize>0.5*metadata.availableRAM
%     metadata.chunking=true;
%     warning('File too big for the RAM - loading in chunk')
% %     metadata.chunksNumber=3*ceil((metadata.rawFileSize/metadata.availableRAM));
% %     metadata.ChunksVector=uint32(linspace(metadata.FramesRequested(1)-1,metadata.FramesRequested(2),metadata.ChunksNumber+1));
% end

% save at this stage for follwing function to find the metadata file
save(allPaths.metadataPath,'metadata');

% Compute the best ROI to remove useless dark portion of the movie
if ~isempty(metadata.croppingMethod)
    switch metadata.croppingMethod
        case 'auto'
            disp('TODO - no autoCropping included yet')
        case 'manual'
            [h5cropIndex,imcropRect,figHandle]=manualCropping(allPaths);
            if ~isempty(figHandle)
                savePDF(figHandle,'manualCropping',allPaths.pathDiagLoading)
                close;
            end
            metadata.h5cropIndex=h5cropIndex;
            metadata.ROI=imcropRect;
            metadata.loadedDimension=[h5cropIndex.Count(2) h5cropIndex.Count(1) diff(metadata.frameRange)+1];
            metadata.loadedFileSize=prod(metadata.loadedDimension)*16/8/(1024)^3;
        case 'center'
            % ROI is a square of size 100 pixels / could be tuned by user
            metadata.ROI=[round(metadata.rawDimension(1)/2)-51 round(metadata.rawDimension(2)/2)-51 100 100];
        otherwise
        disp('Method not recognized. Ignoring cropping - auto or manual only');
    end

end

% Find the best filter frequency bands - [2 20] is good
if metadata.findBestFilter
[bpFilter]=findBestFilterParameters(allPaths.dcimgPathG);
metadata.vectorBandPassFilter=bpFilter;
else
metadata.vectorBandPassFilter=[2 50];
end

% save again to update the file 
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
metadata.allPaths=[];

% Acquisition Settings
metadata.fps=[]; % in Hz
metadata.frameDimension=[]; % in pixel
metadata.totalFrames=[];
metadata.dimension=[];
metadata.frameRange=[];
metadata.depth=[];
metadata.hardwareBinning=1; % usually - taken as default

% Loading Settings
metadata.softwareBinning=1; % by default
metadata.totalBinning=[];
metadata.croppingMethod=[]; % manual and auto available
metadata.h5cropIndex=[];% if to load specific section of h5 file
metadata.ROI=[]; % [xmin ymin width height] Matlab convention (dcimg XY inverted) - can be used directly with imcrop
metadata.findBestFilter=false;
metadata.vectorBandPassFilter=[1 20];% default if previous false - for reg & moco

% TTL for behavior sync
metadata.loadTTL=false;
metadata.TTL=[];
metadata.Locomotion=[];

% Memory Settings
metadata.memoryAvailable=[];
metadata.FileSizeRaw=[];
metadata.FileSizeLoaded=[];
metadata.FileSizeLoadedperChunk=[];
metadata.FileSizeProcessed=[];

% Chunking option, all auto-determined
metadata.Chunking=false; % no chunking by default
metadata.ChunksNumber=[];
metadata.ChunksVector=[];
metadata.LoadedFramesperChunk=[]; % full or chunk window
metadata.DimensionLoadedperChunk=[];


% % Export settings
% metadata.dcimgPath=[];
% metadata.h5Path=[];
% metadata.diagnosticLoading=[];
% metadata.diagnosticRegistration=[];
% metadata.diagnosticMotionCorr=[];
% metadata.diagnosticUnmixing=[];
end


