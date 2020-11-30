function [movie_dns]=denoising1Movie(h5Path,varargin)

options.windowsize=1000;
options.dataset='mov';

meta=h5info(h5Path);
disp('h5 file detected')
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);
h5Path_original=strrep(h5Path,'_moco.h5','.h5');
options.denoisedMoviePath=strrep(h5Path_original,'.h5','_dns.h5');

if exist(options.denoisedMoviePath,'file')==2
    delete(options.denoisedMoviePath)
end
% numFrame=1000;
flims=[1 numFrame];% to update if specific frame number required

windowsize = min(numFrame, options.windowsize);

disp('Start Denoising Function')

fprintf('Loading and processing %5g frames in chunks.\n', numFrame)
k=0;
p=1;
while k<numFrame
    tic;
    
    currentFrame = min(windowsize, numFrame-k);
    fprintf('Loading %3.0f frames; ', currentFrame+k)
    data=h5read(h5Path,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
          
    [movie_dns,~, ~] = denoisingLOSS(data,'windowsize', currentFrame);

    h5append(options.denoisedMoviePath, single(movie_dns),options.dataset);
    
    % imshow(movie(:,:,200),[])
    k=k+currentFrame;
    p=p+1;
    toc;
end



