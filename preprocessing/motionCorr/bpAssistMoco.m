function [output,options]=bpAssistMoco(input,varargin)
% perform motion correction in 2 steps, with a band-pass spatial filtering
% first. User can input as a variable arguemnt a computed shift

options.findBestBP=false;
options.vectorBandPassFilter=[2 20];
options.applyshit=[];
options.windowSize=1000;
options.spatialChunk=false;
options.dataset='mov';
options.ranks=100;
options.dataChunking=false;

%% GET OPTIONS
if nargin>=2
    options = getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

%% CHECK INPUT FORMAT

if ischar(input)
    [~,~,ext]=fileparts(input);
    if strcmpi(ext,'.h5')
        h5Path=input;
        meta=h5info(h5Path);
        disp('h5 file detected')
        dim=meta.Datasets.Dataspace.Size;
        mx=dim(1);my=dim(2);numFrame=dim(3);
        dataset=strcat(meta.Name,meta.Datasets.Name);
        
        bpMoviePath=strrep(h5Path,'.h5','_bp.h5');

    elseif istensor(input)
        disp('working with data in workspace')
    else
        error('input data type not accepted - only h5path or workspace')
    end
end

%% CORE FUNCTION
if isempty(options.applyshit)
% GENERATE THE BANDPASS MOVIE FOR MOTION CORRECTION
% Find the best filter frequency bands - [2 20] is good
if options.findBestBP
[bpFilter]=findBestFilterParameters(input);
options.vectorBandPassFilter=bpFilter;
end
bandPassMovieChunk(h5Path,options.vectorBandPassFilter);

% CORRECT THE MOVIE FROM MOTION ARTEFACTS
try
motionCorr1Movie(bpMoviePath,'nonRigid', false);
catch
end

end