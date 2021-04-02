


function [h5cropIndex,imcropRect,figHandle]=manualCropping(allPaths,varargin)

% if 2 channels are detected, the image on which to crop will overlay both
% channels

options.BandPx=[2 25];
options.verbose=true;
options.autoCropping=false;
options.windowsize=1000;
options.firstFrame=1;
options.dataset='mov';
options.diary=true;
options.diary_name='diary_crop';
options.processWholeMovie=true;

disps('Starting movie cropping')

% use DCIMG or H5 - starting from frist requesting channel - assume the
% allPaths structure as input

dcimgPathG=allPaths.dcimgPathG;
dcimgPathR=allPaths.dcimgPathR;

if ~isempty(dcimgPathG) && ~isempty(dcimgPathR)
    disps('2 dcimg file detected')
elseif isempty(dcimgPathG) && isempty(dcimgPathR)
    error('no dcimg file detected')
else
    disps('1 file detected only')
end

% meta=h5info(allPaths);
% dim=meta.Datasets.Dataspace.Size;
% numFrame=dim(3);
%
% options.h5Start=[1 1 1];
% options.h5Count=[dim(1) dim(2) 100]; % only load 100st frames

%% UPDATE OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end

%%
m=load(allPaths.metadataPath);
metadata=m.metadata;
frameRange=metadata.frameRange;

tempG=zeros(metadata.rawDimension(2),metadata.rawDimension(1));
tempR=zeros(metadata.rawDimension(2),metadata.rawDimension(1));

disp('Please crop manually')
if ~isempty(dcimgPathG)
    [imageG,~,~]=loadDCIMG(dcimgPathG,[frameRange(1) frameRange(1)+100],'resize',true,'scale_factor',1/metadata.softwareBinning,...
        'parallel',1,'verbose',0,'imshow',0);
    
    tempG=mean(imageG,3);
    tempG=bpFilter2D(tempG,options.BandPx(2),options.BandPx(1),'parallel',false);
    tempG=tempG-min(tempG,[],'all');
end

if ~isempty(dcimgPathR)
    [imageR,~,~]=loadDCIMG(dcimgPathR,[frameRange(1) frameRange(1)+100],'resize',true,'scale_factor',1/metadata.softwareBinning,...
        'parallel',1,'verbose',0,'imshow',0);
    
    tempR=mean(imageR,3);
    tempR=bpFilter2D(tempR,options.BandPx(2),options.BandPx(1),'parallel',false);
    tempR=tempR-min(tempR,[],'all');
    tempR=fliplr(tempR); % specific to BFM microscope
end
temp=mat2gray(tempG)+mat2gray(tempR);
imshow(temp,[])
title('Please crop manually')
[~,rect] = imcrop(mat2gray(temp));
temp=imcrop(temp,rect);

figHandle=figure(1);
subplot(221)
imshow(tempG,[])
xlabel('Green Channel')
title(dcimgPathG)
subplot(222)
imshow(tempR,[])
xlabel('Red Channel')
% title(dcimgPathR)
subplot(223)
imshowpair(tempG,tempR)
title('Merged')
subplot(224)
imshow(temp,[])
title('Cropped field')

rect=round(rect);
imcropRect=rect; %[xmin ymin width height]

h5cropIndex.Start=[rect(2) rect(1)];
h5cropIndex.Count=[rect(4) rect(3)];

% 
% if options.processWholeMovie
%     savePath=strrep(allPaths,'.h5','_crop.h5');
%     
%     flims=[1 numFrame];% to update if specific frame number required
%     
%     windowsize = min(numFrame, options.windowsize);
%     
%     fprintf('First Movie - Loading and processing %5g frames in chunks.\n', numFrame)
%     k=0;
%     while k<numFrame
%         tic;
%         currentFrame = min(windowsize, numFrame-k);
%         fprintf('Loading %3.0f frames; \n', currentFrame)
%         movie=h5read(allPaths,dataset,[h5cropIndex.Start k+flims(1)],[h5cropIndex.Count currentFrame]);
%         h5append(savePath, single(movie),options.dataset);
%         % imshow(movie(:,:,200),[])
%         k=k+currentFrame;
%         toc;
%     end
%     if ~isempty(h5PathR)
%         savePath=strrep(h5PathR,'.h5','_crop.h5');
%         
%         fprintf('Second Movie - Loading and processing %5g frames in chunks.\n', numFrame)
%         k=0;
%         while k<numFrame
%             tic;
%             fprintf('Loading %3.0f frames; \n', k)
%             currentFrame = min(windowsize, numFrame-k);
%             movie=h5read(h5PathR,dataset,[h5cropIndex.Start k+flims(1)],[h5cropIndex.Count currentFrame]);
%             h5append(savePath, single(movie),options.dataset);
%             % imshow(movie(:,:,200),[])
%             k=k+currentFrame;
%             toc;
%         end
%         
%     end
%     
% end
    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s h5movieCrop: %s\n', datetime('now'),string);
        end
    end

end

