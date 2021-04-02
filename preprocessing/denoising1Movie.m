function [movie_dns,optiRank]=denoising1Movie(h5Path,varargin)

options.windowSize=1000;
options.spatialChunk=false;
options.dataset='mov';
options.ranks=100;

if nargin>=3
    options = getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

meta=h5info(h5Path);
disp('h5 file detected')
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);nFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);
% h5Path_original=strrep(h5Path,'_dtr.h5','.h5');

windowsize = min(nFrame, options.windowSize); 

suffix_full=strcat('_dns','W',num2str(windowsize),'R',num2str(options.ranks),'.h5');
% suffix_short=strcat('_dns.h5');
options.denoisedMoviePath=strrep(h5Path,'.h5',suffix_full);

if options.spatialChunk
options.gridSize=max(round(min(mx,my)/10),20);% a minimum of 20x20 pixel
% quid overlap?
options.windowSize=min(nFrame,options.windowSize*10);
end

if exist(options.denoisedMoviePath,'file')==2
    delete(options.denoisedMoviePath)
end

% numFrame=1000;
flims=[1 nFrame];% to update if specific frame number required

% load 10sec of movie assuming windowSize=1s=FPS. Help not saturating the
% memory
disp('Start Denoising Function')

% fprintf('Loading and processing %5g frames in full.\n', nFrame)

%  data=h5read(h5Path,dataset);
%           
%     [movie_dns,~, ~] = denoisingLOSS(data,'windowsize', options.windowSize);
% 
%     h5append(options.denoisedMoviePath, single(movie_dns),options.dataset);
%     
%     disp('deleting output to save memory')
%     clear movie_dns
% tic;
% data=h5read(h5Path,dataset,[1 1 1],[mx my nFrame]);
% movie_dns = denoisingStep(single(data), 100, 'DnCNN');
% h5create(options.denoisedMoviePath,dataset,size(movie_dns),'Datatype','single');
% h5write(options.denoisedMoviePath, dataset, single(movie_dns));
% toc;


k=0;
p=1;
while k<nFrame
    tic;
    
    currentFrame = min(windowsize, nFrame-k);
    fprintf('Loading %3.0f frames; ', currentFrame+k)
    movie_in=h5read(h5Path,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
%     movie_in=h5read(h5Path,dataset,[1 1 1],[mx my numFrame]);

%     movie_dns = denoisingLOSS_new(movie_in,'ranks',options.ranks,'windowsize', windowsize);
    movie_dns = denoisingStep(movie_in, options.ranks, 'DnCNN');

%     optiRank(p)=getRank(movie_in);
    
    h5append(options.denoisedMoviePath, single(movie_dns),options.dataset);
    
    disp('deleting output to save memory')
    clear movie_dns movie_in
    % imshow(movie(:,:,200),[])
    k=k+currentFrame;
    p=p+1;
    toc;
end

%     h5append(options.denoisedMoviePath, optiRank,'/optiRank');

end


