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
% created by Simon Haziza, PhD - Stanford University 2021

%% OPTIONS

options.spatialChunk=false;
options.methods='lowpass';
options.samplingRate=[];
options.lpCutOff=0.5;
options.binning=[];
options.frameRange=[];
options.saveData=true;
options.dfof=false; %F/F0 or (F-F0)/F0

options.verbose=1;
options.plot=true;
options.dataset='mov';

%% UPDATE OPTIONS
if nargin>1
    options=getOptions(options,varargin);
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
    % to accomodate Radek h5 formating
    if size(meta.Datasets,1)>1
        dim=meta.Datasets(2,1).Dataspace.Size;
        mx=dim(1);my=dim(2);numFrame=dim(3);
        dataset=strcat(meta.Name,meta.Datasets(2,1).Name);
    else
        dim=meta.Datasets.Dataspace.Size;
        mx=dim(1);my=dim(2);numFrame=dim(3);
        dataset=strcat(meta.Name,meta.Datasets.Name);
    end
    
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
end

if ndims(M)~=3
    error('Input movie must be a 3D array [x y t].');
end
[mx,my,numFrame]=size(M);

fs=options.samplingRate;
lpCutOff=options.lpCutOff;
% frameRange=options.frameRange;
% If output matrix will be less than GPU memory for extract than no
% chunking
s=whos('M');
% if movie size less than 10GB > load everything in RAM
if (s.bytes)/1024^3<10
    options.spatialChunk=false;
end

if options.spatialChunk % if too many pixels > detrending is pixel-independent
    disps('Detrending in spatial chunks')
    nSpatialChunks=min(10,mx);
    chunkEdges=round(linspace(0,mx,nSpatialChunks+1));
    chunkEdges=unique(chunkEdges);

    if options.saveData
        disps('Saving data as h5 file')
        h5create(options.detrendMoviePath,dataset,[mx my numFrame],'Datatype','single');
    end

    for i=1:numel(chunkEdges)-1
        xStart=chunkEdges(i)+1;
        xEnd=chunkEdges(i+1);
        if xEnd<xStart
            continue
        end

        tic;
        movie_dtr=runPhotoBleachingRemoval(M(xStart:xEnd,:,:),'samplingRate',fs,'lpCutOff',lpCutOff);
        toc; disps('Data succesfully detrended')
        
        if options.dfof
            movie_dtr=movie_dtr-ones(size(movie_dtr));
        end
        
        if options.saveData
            h5write(options.detrendMoviePath, dataset, single(movie_dtr),[xStart 1 1],size(movie_dtr));
            disps(sprintf('Data succesfully saved (%d/%d spatial chunks)',i,numel(chunkEdges)-1))
        end
    end

    if options.saveData
        infoOut=h5info(options.detrendMoviePath,dataset);
        if ~isequal(double(infoOut.Dataspace.Size),double([mx my numFrame]))
            error('Detrended file dimensions do not match input dimensions.');
        end
    end
    
else
    disps('No spatial chunking. We can do it!')
    
    tic;
   disp('applying abs value'); M=M+abs(min(M,[],'all'))+1; %SH_20230802 to remove negative value after spatial filtering
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

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s detrending: %s\n', datetime('now'),string);
        end
    end

end
