function [metadata]=getRawMetaData(allPaths,varargin)
% [metadata]=getMetaData(folderpath)
% [metadata]=getMetaData(folderpath,'parameter',value,...)
%
%
% HISTORY
% - by SH 2020
% - adopted for preprocessing by RC 06/23/2020
%
% RC changes:
% - don't change the working directory with cd, it messes up the
% availability of the functions/ script on the path
% - options parsing added
% - simplified and logically restricted to the content of the raw meta data
% without conflating with processing.
% - added depth detection


%% OPTIONS

[options]=MetadataStructure();

options.LVSettingsFile='allsettings.txt';
options.autoCropping=true;
options.savePath=[];
options.verbose=true;
options.plot=true;
options.guessBandPassFilter=true;

%% VARIABLE CHECK

if nargin>=2
    options=getOptions(options,varargin);
end


%% CORE

metadata=options;
metadata.dataPath=allPaths.dcimgPath;
metadata.allPaths=allPaths;
metadata.totalBinning=metadata.softwareBinning*metadata.hardwareBinning;

% Find Green & Red DCIMG files
filename=dir(fullfile(allPaths.dcimgPath,'*.dcimg')); % G always comes before R
% By default, Voltage is in Green Channel.
[green, red]=filename.name;
if ~strcmpi(metadata.voltageChannel,'green')
    metadata.voltageChannel='Red'; % default for AcemNeon
    metadata.referenceChannel='Green'; % default for mRuby3
    [red, green]=filename.name;
end
metadata.voltageFileName=green;
metadata.referenceFileName=red;

% Read just the 32-bit header information
filename=fullfile(allPaths.dcimgPath,metadata.voltageFileName);
fid = fopen(filename,'rb');
dcimgMeta = fread(fid,202,'uint32=>uint32');
fclose(fid);
width = double(dcimgMeta(147)); % index 47: x dim
height = double(dcimgMeta(148)); % index 48: y dim
nFrame = double(dcimgMeta(144)); % index 44: number of frames

metadata.frameDimension=[width height]; % in pixel
metadata.totalFrames=nFrame;
metadata.dimension=[metadata.frameDimension metadata.totalFrames];
fprintf('Movie Dimension: %1.0f x %1.0f x %1.0f pixels \n', metadata.dimension);

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
    warning('Cannot detect Hardware Binning');
end

% Detect depth of imaging RC added
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

% % Memory Settings
% [userview,~] = memory;
% metadata.MemoryAvailable=userview.MaxPossibleArrayBytes/(1024^3);
% metadata.FileSizeRaw=prod(metadata.DimensionRaw)*16/8/(1024)^3;
% metadata.FileSizeLoaded=prod(metadata.DimensionLoaded)*16/8/(1024)^3;
% 
% % Chunking option by assessing loading capability with 20% margin.
% if metadata.FileSizeLoaded>=0.8*metadata.MemoryAvailable
%     metadata.Chunking=true;
%     metadata.ChunksNumber=3*ceil((metadata.FileSizeLoaded/metadata.MemoryAvailable));
%     metadata.ChunksVector=uint32(linspace(metadata.FramesRequested(1)-1,metadata.FramesRequested(2),metadata.ChunksNumber+1));
%     metadata.LoadedFramesperChunk=metadata.ChunksVector(2)-metadata.ChunksVector(1)+1; % full or chunk window
%     metadata.DimensionLoadedperChunk=[metadata.FrameDimension metadata.LoadedFramesperChunk];
%     metadata.FileSizeLoadedperChunk=prod(metadata.DimensionLoadedperChunk)*16/8/(1024)^3;
% end

% Compute the best ROI to remove useless dark portion of the movie
if options.autoCropping
    
    metadata.autoCropping=options.autoCropping;
    
    % Auto-crop green and red channel independently prior to registration
    filename=fullfile(metadata.dataPath,green);
    [imGreen,~]= dcimgmatlab(metadata.totalFrames-1, filename); %dcimg counts from 0
    % always transpose to make it consistent with ORCA
    % always single to reach better resolution
    imGreen=single(imGreen');
    imGreen=imresize(imGreen,1/metadata.softwareBinning,'Method','box','Antialiasing',true);
    [imGreenCrop, metadata.ROI.greenChannel] = autoCropImage(imGreen);
    
    filename=fullfile(metadata.dataPath,red);
    [imRed,~]= dcimgmatlab(metadata.totalFrames-1, filename); %dcimg counts from 0
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

if options.guessBandPassFilter
    metadata.vectorBandPassFilter=getBandPassVector(metadata.softwareBinning);
end
% save_summary(metadata,allPaths.metadataPath,'name',allPaths.metadataName); %>> bug here!!
save(fullfile(allPaths.metadataPath,[allPaths.metadataName '.mat']),'metadata');

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

function [metadata]=MetadataStructure()

% Channels Settings
metadata.dataPath=[];
metadata.voltageChannel='Green'; % default for AcemNeon
metadata.referenceChannel='Red'; % default for mRuby3
metadata.voltageFileName=[];
metadata.referenceFileName=[];

% Acquisition Settings
metadata.fps=[]; % in Hz
metadata.frameDimension=[]; % in pixel
metadata.totalFrames=[];
metadata.dimension=[];
metadata.depth=[];
metadata.hardwareBinning=1; %usually

% Loading Settings
metadata.softwareBinning=8; % by default
metadata.totalBinning=[];
metadata.autoCropping=true;
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


