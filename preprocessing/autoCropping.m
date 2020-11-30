


function [h5cropIndex,imcropRect]=autoCropping(h5Path,varargin)

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
    
    disp('Cropping automatically')
    metadata.autoCropping=options.autoCropping;
    % Auto-crop green and red channel independently prior to registration
    fileName=fullfile(metadata.dataPath,green);
    [imGreen,~]= dcimgmatlab(metadata.totalFrames-1, fileName); %dcimg counts from 0
    % always transpose to make it consistent with ORCA
    % always single to reach better resolution
    imGreen=single(imGreen');
    imGreen=imresize(imGreen,1/metadata.softwareBinning,'Method','box','Antialiasing',true);
    [imGreenCrop, metadata.ROI.greenChannel] = autoCropImage(imGreen);
    
    fileName=fullfile(metadata.dataPath,red);
    [imRed,~]= dcimgmatlab(metadata.totalFrames-1, fileName); %dcimg counts from 0
    imRed=single(imRed');
    imRed=imresize(imRed,1/metadata.softwareBinning,'Method','box','Antialiasing',true);
    [imRedCrop,metadata.ROI.redChannel] = autoCropImage(imRed);
    
    % Diagnostic Output
    if options.plot
        h=figure;
        subplot(2,2,1)
        imshow(imGreen,[])
        title('Green Raw')
        subplot(2,2,2)
        imshow(imRed,[])
        title('Red Raw')
        
        subplot(2,2,3)
        imshow(imGreenCrop,[])
        title('Green Cropped')
        subplot(2,2,4)
        imshow(imRedCrop,[])
        title('Red Cropped')
        
        suptitle('Auto-Cropping quality on the last requested frame')
        if options.savePath
            export_figure(h,'autoCrop',options.savePath);close;
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

