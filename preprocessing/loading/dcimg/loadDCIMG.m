function [movie,totalframes,summary]=loadDCIMG(filepath,varargin)
% Loading DCIMG file as a movie
% SYNTAX
% movie=loadDCIMG(filepath)
% movie=loadDCIMG(filepath,maxframe,...)  - loading from 1 to maxframe
% movie=loadDCIMG(filepath,[frameFirst, frameLast]) - loading selected
% range of frames
% movie=loadDCIMG(filepath,framerange,'Parameter',Value) - passing extra
% options with the 'Parameter', Value, Matlab style.
%
% INPUTS
% - filepath - path to the DCIMG file
% - maxframe, [frameFirst, frameLast] - frame indices
%
% OUTPUTS
% - movie - loaded movie
% - totalframes - total number of frames in the file
% - summary - extra information about the file and execution of this
% function.
%
% OPTIONS
% - 'resize' - enable spatial downsampling/binning
% - 'binning' - combine pixel is binning x binning fashion
% - see other available options in the code below
%
% DEPENDENCIES
% - Hamamatsu DCAM API installed
% - dcimgmatlab.mexw64 on a path
%
% Created by Radek, Jizhou Li and Simon Haziza, Stanford University 2019

%% OPTIONS
options.resize=false; % down sample spatially the file while loading? It speeds up loading especially combined with a parallel pool
options.parallel=true; % for parallel computing
options.scale_factor=1; % default: no binning (scale factor for spatial downsampling (binning).
options.type='single'; % 'uint16', 'double' - changing data type of the output movie but ONLY if you bin it spatially.

% display options
options.imshow=true; % for displaying the first frame after loading, disable on default
options.verbose=1; % 0 - nothing passed to command window, 1 (default) passing messages about state of the execution.

% not recommended to change below:
options.transpose=true; % we always transposed the original file to make
%it compatible with Matlab displays but it is swapping camera rows with columns
options.cropROI=[];

%% VARIABLE CHECK

% setting up a first frame
if nargin>=2
    switch length(varargin{1})
        case 0 % empty frame range
            startframe=int32(0); % indexing starts from 0 for the mex file!!!
            maxframe=int32(0);
        case 1 % movie=LoadDCIMG(filepath,maxframe) TODO
            startframe=int32(0); % indexing starts from 0 for the mex file!!!
            maxframe=int32(varargin{1});
        case 2 % movie=LoadDCIMG(filepath,[frameFirst, frameLast]) TODO
            startframe=int32(varargin{1}(1)-1); % indexing starts from 0 for the mex file!!!
            maxframe=int32(varargin{1}(2));
        otherwise
            error('Wrong format of a second argument of loadDCIMG function')
    end
else
    startframe=int32(0); % indexing starts from 0 for the mex file!!!
end

if nargin>=3 % - 2020-07-18 16:17:24 - SH : should be 2 here...
    options=getOptions(options,varargin(2:end)); % parsing options
end

if isempty(filepath)
    error('Empty DCMIMG path, somethign went wrong');
end

switch options.type
    case 'single'
    case 'double'
    case 'uint16'
    case 'uint8'
    otherwise
        error('Data type %s not supported for movie cast typing',options.type)
end

%% SUMMARY PREPARATION
summary.input_options=options;
summary.execution_duration=tic;
summary.execution_started=datetime('now');

%%
if options.verbose; fprintf('\n'); disps('Start'); end

% loading first frame
disps('Loading first frame and file info.')
[framedata,totalframes]=  dcimgmatlab(startframe, filepath); % that's the mex file that should be on a path
framedata=cast(framedata,options.type); % cast typing to preserve more information upon averaging

if options.transpose
    framedata=framedata'; % this transposition is to make it compatible with imshow, but flips camera rows with columns
    % adding to summary file size information
end

% adding frame info to the summary at this point
frame_info=whos('framedata');
summary.totalframes=totalframes;
summary.frame_size_original=size(framedata);
summary.firstframe_original=framedata;
% - 2020-07-18 16:17:24 - SH > should be done after imcrop and imresize...

if options.resize && options.scale_factor~=1
    framedata=cast(framedata,options.type); % cast typing to preserve more information upon averaging
    framedata=imresize(framedata,options.scale_factor,'box');
    summary.frame_size_resized=size(framedata);
    summary.scale_factor=options.scale_factor;
else
    summary.frame_size_resized=size(framedata);
    summary.scale_factor=1;
end

% Done after imresize > ROI detected after resizing
if ~isempty(options.cropROI)
    % ORCA and matlab different XY convention
    framedata = imcrop(framedata, options.cropROI);
    summary.frame_size_postCropping=size(framedata);
    summary.cropROI=options.cropROI;
end

summary.frame_MB=frame_info.bytes/2^20;
summary.file_GB=frame_info.bytes*double(totalframes)/2^30;


if options.imshow
    imshow(framedata,[])
    title(filepath,'Interpreter','none','FontWeight','normal','FontSize',8);
end

% setting up the end frame, in the C indexing (starting from 0).
if ((maxframe==0)||(maxframe>=totalframes))
    endframe = int32(totalframes(1,1)-1);
else
    endframe=int32(maxframe-1);
end

numFrames = endframe - startframe+1;

summary.nframes2load=double(numFrames);
summary.frame_range=[startframe+1,endframe+1];
summary.loadedMB_fromDisk=double(numFrames)*summary.frame_MB;

if numFrames>totalframes
    error('Wrong frame indices!');
end

sizeFrame=size(framedata);

% % Preallocate the array
% movie = zeros(sizeFrame(1),sizeFrame(2),numFrames, class(framedata));
% movie(:,:,1) = framedata;
movie=[];
%% parallel loading
dataType=options.type;
if options.parallel % for parallel computing
    
    disps('Starting loading DCIMG using PARALLEL mode (no progress will be reported).')
    
    %     % - 2020-07-18 15:05:33 - SH > get the option outside the parfor
    %     transpose=options.transpose;
    %     autoCrop=options.autoCrop;
    %     resize=options.resize; % they are redundant > remove resize...?
    %     scale_factor=options.scale_factor;
    %     type=options.type;
    % ROI=options.cropROI;
    % - 2020-07-18 15:05:33 - SH > why int32 here?
    parfor ii=int32(1:numFrames) % indexing starts from 0 for the mex file!!!
        % Read each frame into the appropriate frame in memory.
        [framedata,~]=  dcimgmatlab(ii+startframe-1, filepath);
        framedata=cast(framedata,dataType); % cast typing to preserve more information upon averaging
        
        if options.transpose
            framedata=framedata';
        end
        
        if options.resize && options.scale_factor~=1
            framedata=imresize(framedata,options.scale_factor,'box'); % this suprisingly gives speed up !
        end
%         imshow(framedata,[])
        % Done after imresize > ROI detected after resizing
        if ~isempty(options.cropROI)
            % detect if red channel > to flip it to be in the same ref as
            % green channel - SH 20201129
            if strfind(filepath,'cR.dcimg')>0
            framedata=fliplr(framedata);
            end
            % ORCA and matlab different XY convention
            framedata = imcrop(framedata, options.cropROI);
        end
        
        movie(:,:,ii)  = framedata; % for chunks loading it has to be frameidx not frame
    end
    disps('File loaded')
else
  disps('did not load without parfor...')  
end %% end choose if sequential of parallel
%%%%%%%%%%%%%%%%%%%

disps(sprintf('Loading DCIMG finished: %s',filepath));

%% Clearing MEX to immediately release RAM
clear mex;

    function disps(string) %overloading disp for this function - this function should be nested
        FUNCTION_NAME='loadDCIMG';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end

end % END of loadDCIMG






