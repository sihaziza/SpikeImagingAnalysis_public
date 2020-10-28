function [lowF,highF]=findBestFilterParameters(h5Path,varargin)
disps('Start findBestFilterParameters Function')

meta=h5info(h5Path);
disp('h5 file detected')
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

disps('Uses the last frame by default')
% use frist is LED switched off at the end
temp=h5read(h5Path,dataset,[1 1 1],[mx my 1]);
lowF=10:5:30;% in pixel
highF=1:5; % in pixel
frameBP=zeros(mx,my,length(lowF)*length(highF));
for iLow=1:length(lowF)
    for iHigh=1:length(highF)
        frameBP(:,:,length(lowF)*(iLow-1)+iHigh)=bpFilter2D(temp,lowF(iLow),highF(iHigh));
        %         e(iLow,iHigh) = entropy(frameBP(:,:,length(lowF)*(iLow-1)+iHigh));
    end
end

figure('Name','Behavioral Metrics','defaultaxesfontsize',16,'color','w')
montage(frameBP,'Size', [length(lowF) length(highF)],'DisplayRange', [],'BorderSize',[2 2] );
xlabel('High-Pass from 1pix -> 5pix - step 1')
ylabel('Low-Pass from 30 pix <- 10 pix - step 5')
title('Montage of band-pass filtered images')

%    subplot(2,1,2)
% imagesc(e)
% title('Entropy of each image')
[lowF,highF]=userFeedback(temp);

disps('Success, you found the best band-pass filter parameters')

fprintf('high-low : [%2.0f %2.0f] \n',highF,lowF)
    function disps(string) %overloading disp for this function
        %         if options.verbose
        fprintf('%s findBestFilterParameters: %s\n', datetime('now'),string);
        %         end
    end
end

function [lowF,highF]=userFeedback(frame)

low=input('Which low pass (10:5:30)');
high=input('Which high pass (1:1:5)');

figure('Name','Behavioral Metrics','defaultaxesfontsize',16,'color','w')
temp=bpFilter2D(frame,low,high);
imshow(temp,[])

answer=input('Are you happy with your choice? (0-No / 1-Yes)');
if ~answer
    [lowF,highF]=userFeedback(frame);
else
    lowF=low;
    highF=high;
end
end