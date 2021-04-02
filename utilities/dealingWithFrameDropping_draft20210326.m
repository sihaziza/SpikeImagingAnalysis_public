
path='F:\GEVI_Wave\Preprocessed\Visual\m14\20210322\meas00\mat';

temp=dir(fullfile(path,'*.mat'));
load(fullfile(temp(1).folder,temp(1).name));
summaryG=summary;
load(fullfile(temp(1).folder,temp(2).name));
summaryR=summary;

frameG=summaryG.framesDroppedVec;
frameR=summaryR.framesDroppedVec;
timeG=summaryG.intervalDeviations;
timeR=summaryR.intervalDeviations;

figure()
subplot(121)
time=getTime(frame,294);
plot(time,[frameG frameR],'linewidth',2)
xlim([0 time(end)])
xlabel('Time (s)')
ylabel('Frame')
subplot(122)
time=getTime(timeG,294);
plot(time,[timeG timeR],'linewidth',2)
% xlim([0 time(end)])
axis square
xlabel('Time (s)')
ylabel('Frame')

% find which channel has the most dropped frame > the longest absolute recording duration.
% e.g. if 294 frame dropped with FPS=394, then camera recorded 1sec longer. 
% reassign timestamps 

if summaryG.nDroppedFrames>=summaryR.nDroppedFrames
disp('green channel dropped more frames')
else
disp('red channel dropped more frames')
end

temp=frameG-frameR;
greenFrame2Remove=find(temp<0);
greenFrame2RemoveTimestamps=abs(temp(temp<0));
redFrame2Remove=find(temp>0);
redFrame2RemoveTimestamps=temp(temp>0);
%%
% [r,lag]=xcorr(diff(summaryG.timestamps),diff(summaryR.timestamps)) ;
% plot(lag,r)
figure(1)
subplot(211)
plot(time,[diff(summaryG.timestamps) diff(summaryR.timestamps)],'linewidth',2)
xlim([time(1) time(end)])
subplot(223)
temp=diff(summaryG.timestamps);
    h=histogram(diff(temp),10000,'FaceColor','#0072BD','EdgeColor','#0072BD','linewidth',2);
    ylim([0 10])
    xlim([-0.05 0.05])
    subplot(224)
    temp=diff(summaryR.timestamps);
    histogram(diff(temp),10000,'FaceColor','#D95319','EdgeColor','#D95319','linewidth',2);
    ylim([0 10])
    xlim([-0.05 0.05])
    %%
% generate the new frame list
% redAdj=1:
