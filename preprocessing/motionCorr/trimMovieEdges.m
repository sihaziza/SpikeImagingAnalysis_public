function [movie_trim]=trimMovieEdges(h5Path,varargin)

% [movie_trim]=trimMovieEdges(h5Path)
% trimMovieEdges(h5Path)
%
% h5Path can also be a local workspace variable.
% Variable input arguments:
% options.timeChunk=false;
% options.saveData=true;
% options.verbose=1;
% options.dataset='mov';
% options.windowSize=5000;
%

%% OPTIONS
options.timeChunk=false;
options.saveData=true;
options.verbose=1;
options.dataset='mov';
options.windowSize=5000;

%% UPDATE OPTIONS
if nargin>1
    options=getOptions(options,varargin);
end

%% CORE OF THE FUNCTION
disps('Starting Edge detection & Trimming')

% identify path versus memory
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
    
    if ~contains(h5Path,'TEMP.h5')
    options.trimMoviePath=strrep(h5Path,'.h5','_trim.h5');
    else
        %if used inside moco function, temp file is identified at
        %_mocoTEMP.h5
    options.trimMoviePath=strrep(h5Path,'TEMP.h5','.h5');
    end
    
    if exist(options.trimMoviePath,'file')==2
        delete(options.trimMoviePath)
    end
      
else
    disps('Using movie from workspace')
    [movie_trim, ~] = postCropping(h5Path);
end

% load and trim
fprintf('Loading and processing %5g frames in chunks.\n', numFrame)
k=0;
p=1;
allCorners=[];
while k<numFrame
    tic;
    
    currentFrame = min(options.windowSize, numFrame-k);
    fprintf('Loading frames %3.0f to %3.0f out of %3.0f. \n ', k, currentFrame+k, numFrame)
    
    disp('finding shift on the bandpassed movie')
    temp=h5read(h5Path,dataset,[1 1 k+1],[mx my currentFrame]);
    
    %save the corner for final cropping
    [~, corner] = postCropping(temp);
    allCorners(:,:,p)=corner;
    
    k=k+currentFrame;
    p=p+1;
    toc;
end

disps('Finding optimal trimming region');
bestCorner(1,1)=max(allCorners(1,1,:));
bestCorner(1,2)=max(allCorners(1,2,:));
bestCorner(2,1)=min(allCorners(2,1,:));
bestCorner(2,2)=max(allCorners(2,2,:));
bestCorner(3,1)=min(allCorners(3,1,:));
bestCorner(3,2)=min(allCorners(3,2,:));
bestCorner(4,1)=max(allCorners(4,1,:));
bestCorner(4,2)=min(allCorners(4,2,:));

k=0;
while k<numFrame
    tic;
    fprintf('Loading and trimming frames %3.0f to %3.0f out of %3.0f. \n ', k, currentFrame+k, numFrame)
    currentFrame = min(options.windowSize, numFrame-k); 
    
    temp=h5read(h5Path,dataset,[1 1 k+1],[mx my currentFrame]);
  
    [tempCorr, ~] = postCropping(temp,bestCorner);
    
    h5append(options.trimMoviePath, tempCorr,options.dataset);
    
    k=k+currentFrame;
    p=p+1;
    toc;
end
    

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s trimMovieEdges: %s\n', datetime('now'),string);
        end
    end

end
