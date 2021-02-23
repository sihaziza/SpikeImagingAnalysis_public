function [bpFilter]=findBestFilterParameters(filePath)
disps('Start findBestFilterParameters Function')
% 
% m=load(allPaths.metadataPath);
% metadata=m.metadata;

[~,~,ext]=fileparts(filePath);

if strcmpi(ext,'.h5')    
    meta=h5info(filePath);
    disp('h5 file detected')
    dim=meta.Datasets.Dataspace.Size;
    mx=dim(1);my=dim(2);numFrame=dim(3);
    dataset=strcat(meta.Name,meta.Datasets.Name);
    
    disps('Uses the last frame by default')
    % use frist is LED switched off at the end
    temp=h5read(filePath,dataset,[1 1 dim(3)-100],[mx my 100]); 
    temp=mean(temp,3);
elseif strcmpi(ext,'.dcimg')
    [temp,~,~]=loadDCIMG(filePath,[100 199],'parallel',1,'verbose',0,'imshow',0);%,...
%         'resize',false,'scale_factor',1/metadata.softwareBinning,);   
    temp=mean(temp,3);
    dim=size(temp);
    mx=dim(1);my=dim(2);

else
    error('only dcimg and h5 accepted here')
end

lowF=10:10:50;% in pixel
highF=1:2:9; % in pixel
frameBP=zeros(mx,my,length(lowF)*length(highF));
for iLow=1:length(lowF)
    for iHigh=1:length(highF)
        frameBP(:,:,length(lowF)*(iLow-1)+iHigh)=bpFilter2D(temp,lowF(iLow),highF(iHigh),'parallel',false);
        %         e(iLow,iHigh) = entropy(frameBP(:,:,length(lowF)*(iLow-1)+iHigh));
    end
end

figure('Name','Behavioral Metrics','defaultaxesfontsize',16,'color','w')
montage(frameBP,'Size', [length(lowF) length(highF)],'DisplayRange', [],'BorderSize',[2 2] );
xlabel('High-Pass from 1pix -> 9pix - step 2')
ylabel('Low-Pass from 50 pix <- 10 pix - step 10')
title('Montage of band-pass filtered images')

%    subplot(2,1,2)
% imagesc(e)
% title('Entropy of each image')
[lowF,highF]=userFeedback(temp);

bpFilter=[highF lowF];

disps('Success, you found the best band-pass filter parameters')

fprintf('high-low : [%2.0f %2.0f] \n',highF,lowF)
    function disps(string) %overloading disp for this function
        %         if options.verbose
        fprintf('%s findBestFilterParameters: %s\n', datetime('now'),string);
        %         end
    end
end

function [lowF,highF]=userFeedback(frame)

low=input('Which low pass (10:5:25)');
high=input('Which high pass (1:1:4)');

figure('Name','Behavioral Metrics','defaultaxesfontsize',16,'color','w')
temp=bpFilter2D(frame,low,high,'parallel',false);
imshow(temp,[])

answer=input('Are you happy with your choice? (0-No / 1-Yes)');
if ~answer
    [lowF,highF]=userFeedback(frame);
else
    lowF=low;
    highF=high;
end
end