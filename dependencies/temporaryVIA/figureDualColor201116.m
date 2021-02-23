

filepath='F:\Calibration\Preprocessed\Noise\m84\20201113\meas00\m84_d201113_s00SlideDualColor-fps100-cG.h5';
filepath2='F:\Calibration\Preprocessed\Noise\m84\20201113\meas00\m84_d201113_s00SlideDualColor-fps100-cR.h5';

mov1=h5load(filepath);
mov2=h5load(filepath2);

%% Inspecting frames 

subplot(2,2,1)
imshow(mov1.mov(:,:,1),[])


subplot(2,2,2)
imshow(mov1.mov(:,:,2),[])

subplot(2,2,3)
imshow(fliplr(mov2.mov(:,:,1)),[])


subplot(2,2,4)
imshow(fliplr(mov2.mov(:,:,2)),[])

%%

ace=mov1.mov(:,:,1:2:end);
varnam=mov2.mov(:,:,2:2:end);
coyfp=mov2.mov(:,:,1:2:end);
fps=mov1.fps;

%%

%%

aceTrace=squeeze(mean(ace,[1,2]));
varnamTrace=squeeze(mean(varnam,[1,2]));
coyfpTrace=squeeze(mean(coyfp,[1,2]));

%%

plot(dff(aceTrace(10:end)))

%%

plotPSD(aceTrace(10:end),fps)

%%

myfft(aceTrace(100:end),fps)

%%

aceMean=mean(ace,3);
varnamMean=fliplr(mean(varnam,3));
coyfpMean=fliplr(mean(coyfp,3));

imshow(varnamMean,[])

%%

C = imfuse(coyfp,varnamMean,'falsecolor','Scaling','joint','ColorChannels',[1 2 0]);
imshow(C)

%%
rgbImage=zeros(size(ace,1),size(ace,2),3);

rgbImage(:,:,1)=coyfpMean/max(coyfpMean(:));
rgbImage(:,:,2)=aceMean/max(aceMean(:))*0.5;
rgbImage(:,:,3)=varnamMean/max(varnamMean(:));

imagesc(rgbImage)

%% frame stamps
filepath='D:\Calibration\Raw\Noise\Sample\20201116\meas03\Sample_d201116_s03DualColorSlidePulsking-fps200-cG_framestamps 0.txt';
fstable=importFrameStamps(filepath);

led1=fstable.LED1(1:2:end);
led2=fstable.LED2(2:2:end);

%%
subplot(2,1,1)
plot(dff(led1(2:end)))
subplot(2,1,2)
plot(dff(led2(2:end)))

%%



