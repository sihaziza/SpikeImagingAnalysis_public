function [movie_dtr]=detrending(h5Path,varargin)
% [movie_dtr]=detrending(h5Path,varargin)
% h5Path can also be a local workspace variable.
% Variable input arguments:
% options.spatialChunk=false;
% options.methods='lowpass';
% options.samplingRate=[];
% options.lpCutOff=0.5;
% options.binning=[];
% options.frameRange=[];
%
% TO DO > setup spatial chunking...
%% OPTIONS

options.spatialChunk=false;
options.methods='lowpass';
options.samplingRate=[];
options.lpCutOff=0.1;
options.binning=[];
options.frameRange=[];
options.saveData=true;
options.dfof=false; %F/F0 or (F-F0)/F0 

options.verbose=1;
options.plot=true;
options.dataset='mov';
options.diary=false;

%% UPDATE OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE

if options.diary
    diary(fullfile(allPaths.pathDiagMotionCorr,options.diary_name));
end

%% CORE OF THE FUNCTION
disps('Starting Detrending ')

if ischar(h5Path)
    [~,~,ext]=fileparts(h5Path);
    
    if strcmpi(ext,'.h5')
        disps('h5 file detected')
    else
        error('not a h5 file...')
    end
    
    meta=h5info(h5Path);
    dim=meta.Datasets.Dataspace.Size;
    mx=dim(1);my=dim(2);numFrame=dim(3);
    dataset=strcat(meta.Name,meta.Datasets.Name);
    
    options.detrendMoviePath=strrep(h5Path,'.h5','_dtr.h5');
    if exist(options.detrendMoviePath,'file')==2
        delete(options.detrendMoviePath)
    end
    
    if isempty(options.frameRange)
        options.frameRange=[1 numFrame];
    end
    
    % Load the data
    M=h5read(h5Path,dataset,[1 1 options.frameRange(1)],[mx my diff(options.frameRange)+1]);
    
    if ~isempty(options.binning)
        M=imresize3(M,[mx/options.binning my/options.binning diff(options.frameRange)+1],'box');
    end
    
else
    disps('Using movie from workspace')
    M=h5Path;
    dim=size(M);
end

fs=options.samplingRate;
lpCutOff=options.lpCutOff;
% frameRange=options.frameRange;

if options.spatialChunk % if too many pixels > detrending is pixel-independent
    disps('sorry not ready yet... ask for implementation')
    
%     % find the shortest dimension to operate
%     if mx<my
%         parfor i=1:mx
%             Mtemp=h5read(h5Path,dataset,[i 1 frameRange(1)],[1 my diff(frameRange)+1]);            
%             [temp]=runPhotoBleachingRemoval(Mtemp,'samplingRate',fs,'lpCutOff',lpCutOff);
%             h5append(options.detrendMoviePath, temp,options.dataset);
%             h5write(options.detrendMoviePath,options.dataset, temp,[i 1 options.frameRange(1)],[1 my diff(options.frameRange)+1]); % movie size needs to have 3 elements RC
%         end
%     end
   
else
    
    tic;
    [movie_dtr]=runPhotoBleachingRemoval(M,'samplingRate',fs,'lpCutOff',lpCutOff);
    toc; disps('Data succesfully detrended')
    
    if options.dfof
        movie_dtr=movie_dtr-ones(size(movie_dtr));
    end
    
    if options.saveData
    disps('Saving data as h5 file')
    h5create(options.detrendMoviePath,dataset,size(movie_dtr),'Datatype','single');
    h5write(options.detrendMoviePath, dataset, single(movie_dtr)); toc;
    toc; disps('Data succesfully saved')
    end
end


if options.diary
    diary off
end

function disps(string) %overloading disp for this function
if options.verbose
    fprintf('%s detrending: %s\n', datetime('now'),string);
end
end

end
