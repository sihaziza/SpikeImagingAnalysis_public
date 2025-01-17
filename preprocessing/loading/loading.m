function [summaryLoading] = loading(allPaths,varargin)
% converting two dcimg movies to h5 files and passing all metadata
% this is a high-level functions outputting diagnostic data too!
%
% SYNTAX
% [movieG,movieR,summary] = loadingMovies(dcimgpathG,dcimgpathR,varargin)
% [movieG,movieR,summary] = loadingMovies(dcimgpathG,dcimgpathR,varargin)
%
% INPUT
%
% OPTIONS
%
% OUTPUT
% summary     = Extra outputs, validation and diagnostic


%% GET DEFAULT OPTIONS

% Key parameters
% options.binning=metadata.softwareBinning;
% options.scale_factor=1/options.binning; % downsampling factor. allows values such as 0.3 rather than integer binning values.
options.cropROI=[];
options.ChunkSize = []; % if empty, this will be calculated based on RAM
options.maxRAM=0.1;
options.computeTimestamps=false;

% Control display
options.frameRange = [1 1000]; % by default, load all frames
options.plot=true;
options.verbose=true; % 0 - supress displaying state of execution

% Export data
options.diary=true;
options.diary_name='log.txt';
options.export_folder=[]; % if empty than created automatically, vide code
options.diagnostic_folder=fullfile('Diagnostic','loading');
options.suffix='bin'; % added to the file name
options.loadRed=true;

%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%% CONVERT DCIMG to H5 files
disps('Starting conversion of two DCIMG to H5 files');

temp=load(allPaths.metadataPath);
metadata=temp.metadata; clear temp;

% if metadata.chunking
disps('Loading data in chunks')
% Loading green channel
[~,movieG,~]= loadDCIMGchunks(allPaths.dcimgPathG,...
    'binning',metadata.softwareBinning,...
    'cropROI',metadata.ROI,...
    'frameRange',metadata.frameRange,...
    'h5Path',allPaths.h5PathG);

if ~isfile(allPaths.h5PathG)
    error('H5 conversion failed')
end

disps('One movie loaded')

if ~isempty(allPaths.dcimgPathR)&& options.loadRed
    % Loading red channel
   [~,movieR,~]= loadDCIMGchunks(allPaths.dcimgPathR,...
        'binning',metadata.softwareBinning,...
        'cropROI',metadata.ROI,...
        'frameRange',metadata.frameRange,...
        'h5Path',allPaths.h5PathR);
    
    if ~isfile(allPaths.h5PathR)
        error('H5 conversion failed')
    end
    disps('Second movie loaded')
end

    function disps(string) %overloading disp for this function - this function should be nested
        FUNCTION_NAME='loading';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end
end

