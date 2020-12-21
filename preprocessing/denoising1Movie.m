function [movie_dns]=denoising1Movie(h5Path,varargin)

options.windowSize=1000;
options.spatialChunk=false;
options.dataset='mov';

if nargin>=3
    options = getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

meta=h5info(h5Path);
disp('h5 file detected')
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);
h5Path_original=strrep(h5Path,'_dtr.h5','.h5');
options.denoisedMoviePath=strrep(h5Path_original,'.h5','_dns2.h5');

if options.spatialChunk
options.gridSize=max(round(min(mx,my)/10),20);% a minimum of 20x20 pixel
% quid overlap?
options.windowSize=min(numFrame,options.windowSize*10);
end

if exist(options.denoisedMoviePath,'file')==2
    delete(options.denoisedMoviePath)
end

% numFrame=1000;
flims=[1 numFrame];% to update if specific frame number required

% load 10sec of movie assuming windowSize=1s=FPS. Help not saturating the
% memory
windowsize = min(numFrame, 10*options.windowSize); 
disp('Start Denoising Function')

fprintf('Loading and processing %5g frames in chunks.\n', windowsize)

%  data=h5read(h5Path,dataset);
%           
%     [movie_dns,~, ~] = denoisingLOSS(data,'windowsize', options.windowSize);
% 
%     h5append(options.denoisedMoviePath, single(movie_dns),options.dataset);
%     
%     disp('deleting output to save memory')
%     clear movie_dns

k=0;
p=1;
while k<numFrame
    tic;
    
    currentFrame = min(windowsize, numFrame-k);
    fprintf('Loading %3.0f frames; ', currentFrame+k)
    data=h5read(h5Path,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
          
    [movie_dns,~, ~] = denoisingLOSS(data,'windowsize', options.windowSize);

    h5append(options.denoisedMoviePath, single(movie_dns),options.dataset);
    
    disp('deleting output to save memory')
    clear movie_dns data
    % imshow(movie(:,:,200),[])
    k=k+currentFrame;
    p=p+1;
    toc;
end
end


