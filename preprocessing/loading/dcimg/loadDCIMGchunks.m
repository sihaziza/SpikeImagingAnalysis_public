function [movie,summary]=loadDCIMGchunks(filePath,varargin)
% Loading DCIMG in chunks, clearing mex buffer inbetween chunk loading.
% This function makes sense when you want to resize the file on the fly
% while loading. Otherwise, there is no memory benefit. Loding to H5
% possible too.
%
% SYNTAX
% [movietotalframes,summary]= loadDCIMGchunks(filepath,scale_factor) -
% [movietotalframes,summary]= loadDCIMGchunks(filepath,scale_factor,frameRange)
% [movietotalframes,summary]= loadDCIMGchunks(filepath,scale_factor,frameRange,'optionName',optionValue,...)
%
% INPUTS:
% - filepath - path to DCIMG file
% - scale_factor - resize scale factor e.g. scale_factor=0.5 for 2x2 binning
% - frameRange - range of frames to load in the format
% 'frameRange=maxnumberOfFrmaes' or 'frameRange=[firstFrame,lastFrame]'
%
%
% OUTPUTS:
% - movie - loaded movie or path to h5 file
% - summary - structure containing an internal configuration
% of the function that includes all input options as well as the imporant parameters characterizing the function configuration, performance and execution.
%
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning.
%
% DEPENDENCIES
% - loadDCIMG, checkRAM, chunkFrames on the path along with their dependencies.

% HISTORY
% - 2020-06-02 13:28:42 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-06-05 15:25:12 - total number of frames just in the summary
% - 2020-06-21 19:34:22 - add saving h5 option, J.Li
% - 2020-06-27 18:44:13 - accepting scalefactor as empty parameter RC
% - 2020-06-28 01:35:59 - saving h5 using h5append for simplicity; getting back to the chunk size based on RAM or options without manipulating in the middle RC
% - 2020-06-28 03:08:37 - leaving just h5Path option without having both h5save option  RC
% - 2020-07-16 13:41:15 - put non-filepath input variable into varargin (binning, frameRange) SH
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% OPTIONS

% Key parameters
options.binning=8;
options.scale_factor=[];
options.frameRange=[];
options.cropROI=[];
% ADVANCED: not recommended to change unless you are sure what you are doing:
options.chunkSize=[]; % on default empty and not overwriting the one found based on the available RAM size
options.firstnFrames=10;% loading this many frames to estimate the speed transfer. Should never exceed the nubmer of frames in the file!
options.maxRAM=0.1; % relative, factor outomatically adjusting the chunk size based on the available amount of RAM
options.parallel=true;

% Control display
options.verbose=true;
options.imshow=true; % for displaying the first frame after loading, disable on default

% Export data
options.h5Path=[]; % if not empty doing convertion into h5 file instead of loading to memory (obsolete and deleted: options.saveh5 = false ) RC
options.dataset='mov';

%% VARIABLE CHECK

if nargin>=2
    options=getOptions(options,varargin); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
options.scale_factor=1/options.binning;
input_options=options; % saving orginally passed options to output them in the original form for potential next use

%% Summary preparation
summary1.function_path=mfilename('fullpath'); % will be repalced by summary after loading summary from the first batch
summary1.execution_started=datetime('now');
summary1.execution_duration=tic;
summary1.firstframe = 0;

%% CORE
disps('Starting loading file in chunks');
disps(filePath);

% first frames info
firstbatch_loading_start=tic;
disps('Getting info from the first frames');
try % we don't know yet how many frames are in this file so error can be expected...
    [movie,totalframes,summary_1frame]=...
        loadDCIMG(filePath,[1 1],'resize',true,'scale_factor',options.scale_factor,...
        'cropROI',options.cropROI,'parallel',options.parallel,'verbose',0,'imshow',options.imshow);
%     summary.firstframe_original=summary_1frame.firstframe_original; %
%     this will be probably overwritten % - 2020-06-28 04:05:05 -   RC
catch err
    getReport(err)
    error('Can'' even load first %d frames! Isn''t %d exceeding the number of frames in this file?',options.firstnFrames,options.firstnFrames);
end
summary=getOptions(summary_1frame,{'options',summary1},'showWarnings',false); % overwritting this functions summary with data fetched from initial loading


summary.firstframe = double(movie(:,:,1));
summary.firstbatch_loading_duration=toc(firstbatch_loading_start);
summary.datatype = class(summary.firstframe);

% parsing frame range
frameRange=options.frameRange;
if isempty(frameRange)
    firstframe=1;
    lastframe=totalframes;
elseif length(frameRange)==1
    firstframe=1;
    lastframe=frameRange;
elseif length(frameRange)==2
    firstframe=frameRange(1);
    lastframe=frameRange(2);
else
    error('Wrong format of frame range');
end
lastframe=min(lastframe,totalframes);

summary.frame_range=[firstframe,lastframe];
summary.nframes2load=lastframe-firstframe+1;

% getting estimates about the loading
summary.estimated_MB_per_sec=summary_1frame.MB_per_sec;
summary.MB_per_sec=[]; % will be populated in the end
summary.estimated_loading_time=(summary.nframes2load*summary_1frame.frame_MB/summary.estimated_MB_per_sec);
disps(sprintf('Estimated loading time: %.1fs with the speed %.2fMB/s',summary.estimated_loading_time,summary.estimated_MB_per_sec));



% determining the chunk size i.e. max number of frames to load at once
if ~isempty(options.chunkSize)
    summary.chunkSize=options.chunkSize;
    summary.availableRAM=[]; % not checking the RAM at all, hopefully user knows what he is doing
else
    % determining the chunk size
    summary.availableRAM=checkRAM; % that is calling our external function that should be on the path
    summary.chunkSize=round(options.maxRAM*summary.availableRAM/summary.frame_MB/2^20);
end



%% actual loading in chunks

chunksFirstLast=double(chunkFrames(summary.chunkSize,summary.frame_range)); % preparing the chunk frame numbers array
summary.chunksFirstLast=chunksFirstLast;

if ~isempty(options.h5Path)
    disps('Converting DCIMG to H5 rather than loading to memory')
    h5Path = options.h5Path;   
    
    if isfile(h5Path)
        disps(['Already found h5 file:' h5Path 'deleting!']);
        delete(h5Path);
    end
    
    for ichunk=1:size(chunksFirstLast,1) % this should be regular for loop as the inside DCIMG loading might be parallel already
        [movie_batch,~,summary_batch]=loadDCIMG(filePath,chunksFirstLast(ichunk,:),'resize',true,'scale_factor',options.scale_factor,...
            'parallel',options.parallel,'verbose',0,'imshow',options.imshow);
        
        [~,summary_append]=h5append(h5Path, movie_batch, options.dataset); % and that's enough an covers creation too. Don't convert to single yet. RC
        disps(sprintf('Chunk %d/%d loaded with a speed %.1fMB/s and saved with %.1fMB/s',...
            ichunk,size(chunksFirstLast,1),summary_batch.MB_per_sec,summary_append.MB_per_sec));
    end
    
    movie = h5Path;
    
else
    
    % allocating the memory movie was already preloaded from the first batch
    % but we will discarded for simplicity. Also with the syme data type.
    movie=zeros(size(movie,1),size(movie,2),summary.nframes2load,class(movie));
    
    nframes_loaded=0;
    for ichunk=1:size(chunksFirstLast,1) % this should be regular for loop as the inside DCIMG loading might be parallel already
        [movie_batch,~,summary_batch]=loadDCIMG(filePath,chunksFirstLast(ichunk,:),'resize',true,'scale_factor',options.scale_factor,...
            'parallel',options.parallel,'verbose',0,'imshow',options.imshow);
        
        movie(:,:,nframes_loaded+(1:size(movie_batch,3)))=movie_batch;
        nframes_loaded=nframes_loaded+size(movie_batch,3);
        disps(sprintf('Chunk %d/%d loaded with a speed %.1fMB/s',ichunk,size(chunksFirstLast,1),summary_batch.MB_per_sec));
    end
    
    disps('File loaded');
    
end

%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);


movie_info=whos('movie');
summary.loadedMB_toRAM=movie_info.bytes/2^20;
summary.execution_duration=toc(summary1.execution_duration);

summary.frames_per_sec=summary.nframes2load/summary.execution_duration;
summary.MB_per_sec=summary.loadedMB_fromDisk/summary.execution_duration;
summary.movie_class=class(movie);
summary.filepath=filePath;
summary.function_path=mfilename('fullpath');

summary.contact='Radek Chrapkiewicz (radekch@stanford.edu)';



    function disps(string) %overloading disp for this function - this function should be nested
        FUNCTION_NAME='loadDCIMGchunks';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end

end  %%% END LOADDCIMGCHUNKS

