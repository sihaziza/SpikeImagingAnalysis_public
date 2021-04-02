


function [h5cropIndex,imcropRect]=h5movieCropping(h5Path,varargin)

options.BandPx=[3 25];
options.verbose=true;
options.autoCropping=false;
options.windowsize=1000;
options.dataset='mov';
options.diary=true;
options.diary_name='diary_crop';
options.processWholeMovie=true;

disps('Starting movie cropping')

if isstruct(h5Path)
    h5PathG=h5Path.h5PathG;
    h5PathR=h5Path.h5PathR;
    disps('2 channels detected')
    h5Path=h5PathG;
    % options.cropMoviePath=strrep(h5Path,'.h5','_crop.h5');
    
end

[~,~,ext]=fileparts(h5Path);
if strcmpi(ext,'.h5')
    disps('h5 file detected')
else
    error('not a h5 or Tiff file')
end

meta=h5info(h5Path);
dim=meta.Datasets.Dataspace.Size;
numFrame=dim(3);

options.h5Start=[1 1 1];
options.h5Count=[dim(1) dim(2) 100]; % only load 100st frames

%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%%
if options.autoCropping
    disp('Cropping automatically')
    
else
    disp('Please crop manually')
    if isempty(h5PathR)
        dataset=strcat(meta.Name,meta.Datasets.Name);
        image=h5read(h5Path,dataset,options.h5Start,options.h5Count);
        
        temp=mean(image,3);
        temp=bpFilter2D(temp,options.BandPx(2),options.BandPx(1),'parallel',false);
        temp=temp-min(temp,[],'all');
        imshow(temp,[])
        title('Please crop manually')
        [~,rect] = imcrop(mat2gray(temp));
        temp=imcrop(temp,rect);
        imshow(temp,[])
        rect=round(rect);
    else
        dataset=strcat(meta.Name,meta.Datasets.Name);
        imageG=h5read(h5Path,dataset,options.h5Start,options.h5Count);
        imageR=h5read(h5PathR,dataset,options.h5Start,options.h5Count);
        
        tempG=mean(imageG,3);
        tempG=bpFilter2D(tempG,options.BandPx(2),options.BandPx(1),'parallel',false);
        tempG=tempG-min(tempG,[],'all');
        
        tempR=mean(imageR,3);
        tempR=bpFilter2D(tempR,options.BandPx(2),options.BandPx(1),'parallel',false);
        tempR=tempR-min(tempR,[],'all');
        
        imshowpair(tempG,tempR)
        
        temp=mat2gray(tempG)+mat2gray(tempR);
        
        imshow(temp,[])
        title('Please crop manually')
        [~,rect] = imcrop(mat2gray(temp));
        temp=imcrop(temp,rect);
        imshow(temp,[])
        rect=round(rect);
    end
end

imcropRect=rect;

h5cropIndex.Start=[rect(2) rect(1)];
h5cropIndex.Count=[rect(4) rect(3)];


if options.processWholeMovie
    savePath=strrep(h5Path,'.h5','_crop.h5');
    
    flims=[1 numFrame];% to update if specific frame number required
    
    windowsize = min(numFrame, options.windowsize);
    
    fprintf('First Movie - Loading and processing %5g frames in chunks.\n', numFrame)
    k=0;
    while k<numFrame
        tic;
        currentFrame = min(windowsize, numFrame-k);
        fprintf('Loading %3.0f frames; \n', currentFrame)
        movie=h5read(h5Path,dataset,[h5cropIndex.Start k+flims(1)],[h5cropIndex.Count currentFrame]);
        h5append(savePath, single(movie),options.dataset);
        % imshow(movie(:,:,200),[])
        k=k+currentFrame;
        toc;
    end
    if ~isempty(h5PathR)
        savePath=strrep(h5PathR,'.h5','_crop.h5');
        
        fprintf('Second Movie - Loading and processing %5g frames in chunks.\n', numFrame)
        k=0;
        while k<numFrame
            tic;
            fprintf('Loading %3.0f frames; \n', k)
            currentFrame = min(windowsize, numFrame-k);
            movie=h5read(h5PathR,dataset,[h5cropIndex.Start k+flims(1)],[h5cropIndex.Count currentFrame]);
            h5append(savePath, single(movie),options.dataset);
            % imshow(movie(:,:,200),[])
            k=k+currentFrame;
            toc;
        end
        
    end
    
end
    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s h5movieCrop: %s\n', datetime('now'),string);
        end
    end

end

