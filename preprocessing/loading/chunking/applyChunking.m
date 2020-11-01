function [filepathVout,filepathRout,summary]=applyChunking(filepathV,filepathR,functionHandle,varargin)
%
% HELP
% Universal operation of chunking on two movies, given the 'functionHandle' that accepts two inputs plus options.
% SYNTAX
%[filepathVoutfilepathRout,summary]= applyChunking(filepathV,filepathR,functionHandle) - use 4, etc.
%[filepathVoutfilepathRout,summary]= applyChunking(filepathV,filepathR,functionHandle,varargin) - use 4, etc.
%
% INPUTS:
% - filepathV - ...
% - filepathR - ...
% - functionHandle - ...
% - varargin - omore inputs to functionHandle
% OUTPUTS:
% - filepathVout - ...
% - filepathRout - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning.
%
% HISTORY
% - 27-Jun-2020 03:23:52 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% % - 2020-07-01 00:33:02 -   RC finished and tested
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!

%% CONSTANTS (never change, use OPTIONS instead)

%% OPTIONS 
% these are as a matter of fact constanct here as there is not a neat way
% currently to pass both input arguments ane local optoins. RC

options.maxRAM=0.1;
options.ChunkSize=[]; % if empt, determined based on available RAM
options.dataset='/mov';

%% VARIABLE CHECK

% te
input_options=options; % saving orginally passed options to output them in the original form for potential next use


%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE
%The core of the function should just go here.

% determining the chunk size i.e. max number of frames to load at once

[summary.chunkSize]=chunkh5(filepathV,options.maxRAM);
summary.movsize=h5moviesize(filepathV,'dataset',options.dataset);
summary.frame_range=[1, summary.movsize(3)];

%% chunking loop



chunksFirstLast=double(chunkFrames(summary.chunkSize,summary.frame_range)); % preparing the chunk frame numbers array
summary.chunksFirstLast=chunksFirstLast;

summary.funcname=func2str(functionHandle);
suff=['_', summary.funcname];

filepathVout=suffix.add(filepathV,suff,'f');
filepathRout=suffix.add(filepathR,suff,'f');

if isfile(filepathVout)
    disp([filepathVout, ' already exists, deleting]']);
end

if isfile(filepathRout)
    disp([filepathRout, ' already exists, deleting]']);
end






for ichunk=1:size(chunksFirstLast,1) % this should be regular for loop as the inside DCIMG loading might be parallel already
    disp(sprintf('Loading %d/%d chunks',ichunk,size(chunksFirstLast,1)));
    [movieVchunk,summary_readV]=h5readchunk(filepathV,chunksFirstLast(ichunk,:));
    [movieRchunk,summary_readR]=h5readchunk(filepathR,chunksFirstLast(ichunk,:));
    
    disp(sprintf('Applying %s function on loaded movies.',summary.funcname));
    [movieVchunk_processed,movieRchunk_processed,summary_chunk_process]=functionHandle(movieVchunk,movieRchunk,varargin{:});
    disp('Appending h5 files')
    h5append(filepathVout,movieVchunk_processed,options.dataset);
    h5append(filepathRout,movieRchunk_processed,options.dataset);
    
    summary.summary_readV(ichunk)=summary_readV;
    summary.summary_readR(ichunk)=summary_readR;
    summary.summary_chunk_process(ichunk)=summary_chunk_process;
end

disp('Finished')


%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);

    function disp(string) %overloading disp for this function
        FUNCTION_NAME=sprintf('applyChunking@%s',func2str(functionHandle));
        fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
    end

end


