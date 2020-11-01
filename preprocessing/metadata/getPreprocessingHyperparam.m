function [hyperparameters]=getPreprocessingHyperparam(metadata,varargin)

%%%%% Get all metadata %%%%%
%         Once all metadata have been gathered, batch processing can start
% Find best filter parameter of the date recording

%         fileName=dir(fullfile(fullfile(h5PathMain,date,folderName{1}), '*_crop.h5')); % G always comes before R
%         [fileNameG]=fileName.name; % for saving other outputs,
%
%         h5PathG=fullfile(fileName(1).folder,fileNameG);
%
%         [high,low]=findBestFilterParameters(h5PathG);
%         bpFilter=[low high];


% Get auto or manual cropping

% Get frame range if TTL detected

% does not work for old recording ORCA flash
frame=1;
[movieG,~,~]=loadDCIMG(options.dcimgPathG,[frame, frame+100]);
[movieR,~,~]=loadDCIMG(options.dcimgPathR,[frame, frame+100]);

h=figure('defaultaxesfontsize',16,'color','w');
subplot(211)
imshow(bpFilter2D(mean(movieG,3),35,2),[])
title('Green Channel - avg & 2dFilter')
subplot(212)
imshow(bpFilter2D(mean(movieR,3),35,2),[])
title('Red Channel - avg & 2dFilter')
export_figure(h,'Average-2D Filter Movie - 100 frames',allPaths.pathDiagLoading);%close;

fprintf('Green max %2.0f | Red max %2.0f \n', max(movieG(:)), max(movieR(:)));
metrics.maxPixelG=max(movieG(:));
metrics.maxPixelR=max(movieR(:));

save(fullfile(allPaths.pathDiagLoading,'metrics.mat'),'metrics');

% SPATIAL CROPPING - set ROI
fileName=dir(fullfile(h5Path, '*.h5')); % G always comes before R
[fileNameG, fileNameR]=fileName.name; % for saving other outputs

h5PathG=fullfile(h5Path,fileNameG);
h5PathR=fullfile(h5Path,fileNameR);

testPath.h5PathG=h5PathG;
testPath.h5PathR=h5PathR;

[h5cropIndex,imcropRect]=h5movieCropping(testPath,'processWholeMovie',true);

disp('End crop movie');toc;

% TEMPORAL CROPPING - set frame range if TTL for sensory stimulation present
filepathTTL = strrep(options.dcimgPathG,'.dcimg','_framestamps 0.txt');
[TTL]=importdata(filepathTTL);
if isstruct(TTL)
    loco=TTL.data(:,2);
    stim=TTL.data(:,4);
    fluctuationLED=TTL.data(:,5:6);
else
    loco=TTL(:,2);
    stim=TTL(:,4);
    fluctuationLED=TTL(:,5:6);
end
plot(zscore([loco stim]))
% plot(zscore(fluctuationLED))

temp=diff(stim);
plot(temp)
frame0=find(diff(stim)==1,1,'first');
frameX=find(diff(stim)==-1,1,'last');
baseline=0.5; %in sec
fps=500; % in Hz

frameRange=[frame0-baseline*fps frameX+baseline*fps-1];
temp=stim(frameRange(1):frameRange(2));plot(temp,'o')


% Load TTL file if needed
if metadata.loadTTL
    try
        Nametemp=dir('*_framestamps 0.txt');
        [TTL]=importdata(Nametemp.name);
        metadata.TTL=TTL(metadata.FramesRequested,4);
    catch
        warning('Cannot detect TTL file');
    end
end

% % Memory Settings
% [userview,~] = memory;
% metadata.MemoryAvailable=userview.MaxPossibleArrayBytes/(1024^3);
% metadata.FileSizeRaw=prod(metadata.DimensionRaw)*16/8/(1024)^3;
% metadata.FileSizeLoaded=prod(metadata.DimensionLoaded)*16/8/(1024)^3;
% 
% % Chunking option by assessing loading capability with 20% margin.
% if metadata.FileSizeLoaded>=0.8*metadata.MemoryAvailable
%     metadata.Chunking=true;
%     metadata.ChunksNumber=3*ceil((metadata.FileSizeLoaded/metadata.MemoryAvailable));
%     metadata.ChunksVector=uint32(linspace(metadata.FramesRequested(1)-1,metadata.FramesRequested(2),metadata.ChunksNumber+1));
%     metadata.LoadedFramesperChunk=metadata.ChunksVector(2)-metadata.ChunksVector(1)+1; % full or chunk window
%     metadata.DimensionLoadedperChunk=[metadata.FrameDimension metadata.LoadedFramesperChunk];
%     metadata.FileSizeLoadedperChunk=prod(metadata.DimensionLoadedperChunk)*16/8/(1024)^3;
% end

% Compute the best ROI to remove useless dark portion of the movie
if options.autoCropping
    
    metadata.autoCropping=options.autoCropping;
    
    % Auto-crop green and red channel independently prior to registration
    filename=fullfile(metadata.dataPath,green);
    [imGreen,~]= dcimgmatlab(metadata.totalFrames-1, filename); %dcimg counts from 0
    % always transpose to make it consistent with ORCA
    % always single to reach better resolution
    imGreen=single(imGreen');
    imGreen=imresize(imGreen,1/metadata.softwareBinning,'Method','box','Antialiasing',true);
    [imGreenCrop, metadata.ROI.greenChannel] = autoCropImage(imGreen);
    
    filename=fullfile(metadata.dataPath,red);
    [imRed,~]= dcimgmatlab(metadata.totalFrames-1, filename); %dcimg counts from 0
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
    
end

end