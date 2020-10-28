%% LOAD h5 File
Fs=400;
M=h5read('F:\U01Grant_Mark_20200418\Movie_Spike\MoCoDataCrop2Dfilt.h5', '/movie');

% crop around the 2 opposite-going neurons
ROI=double(M(74:96,181:206,:));

% each one to get the time trace
n1=ROI(13:19,8:14,:);
n2=ROI(5:12,14:19,:);
%% No Standardization
tic;
imdenW=zeros(size(M));
for i=1:size(M,3)
imdenW(:,:,i) = wdenoise2(M(:,:,i));
end
toc;
%% Comparison with wiener2, an Adaptive Filter
tic;
imden=zeros(size(M));
for i=1:size(M,3)
    imden(:,:,i)=wiener2(M(:,:,i),[3 3]);
end
toc;
%%
figure(1)
imshow([M(:,:,end) mean(M,3);...
    imden(:,:,end) mean(imden,3);...
    imdenW(:,:,end) mean(imdenW,3)],[-2500 7000])
title('Raw - Wiener2 - Wdenoise')
%% Standardize ROI first
zROI=sh_Standardize(ROI);
n1z=ROIz(13:19,8:14,:);
n2z=ROIz(5:12,14:19,:);

% Denoising in Space
tic;
imdenz=zeros(size(zROI));
for i=1:size(zROI,3)
image=zROI(:,:,i);
imdenz(:,:,i) = wdenoise2(image);
end
toc;

dim=size(ROI);
temp=reshape(ROI,dim(1)*dim(2),dim(3));
% Denoising in Time
tic;
for i=1:dim(1)*dim(2)
image=ROI(:,:,i);
temp(i,:) = wdenoise(temp(i,:));
end
imdenzT=reshape(temp,dim(1),dim(2),dim(3));
imdenzT=sh_Standardize(imdenzT);
toc;

%%
n1den=imdenz(13:19,8:14,:);
n2den=imdenz(5:12,14:19,:);

n1denT=imdenzT(13:19,8:14,:);
n2denT=imdenzT(5:12,14:19,:);

idx=880;
figure(1)
subplot(1,2,1)
imshow(imdenzT(:,:,idx),[-3 3])
title('Denoised')
subplot(1,2,2)
imshow(zROI(:,:,idx),[-3 3])
title('Noisy')
colormap gray
%%
t1=sh_Standardize(sh_PointProjection(n1));
t2=sh_Standardize(sh_PointProjection(n2));

t1den=sh_Standardize(sh_PointProjection(n1den));
t2den=sh_Standardize(sh_PointProjection(n2den));

% t1den=wdenoise(t1);
% t2den=wdenoise(t2);

% 
% [b,a]=butter(3,10/(Fs/2),'high');
% 
% t1RP=sh_Standardize(filtfilt(b,a,double(t1)));
% t2RP=sh_Standardize(filtfilt(b,a,double(t2)));
% 
% [~,l1]=findpeaks(-t1RP,Fs,'MinPeakHeight',2.5);
% [~,l2]=findpeaks(t2RP,Fs,'MinPeakHeight',2.5);

Time=0:1/Fs:(length(t1)-1)/Fs;
% figure()
% plot((t1-t1den).^2)
clf
figure('DefaultAxesfontsize',18,'Color','w')
plot(Time,t1,'b','linewidth',1)
hold on
plot(Time,t2,'r','linewidth',1)
plot(Time,t1denT,'-b','linewidth',2)
plot(Time,t2denT,'-r','linewidth',2)
% plot(Time,t1den,'-b','linewidth',2)
% plot(Time,t2den,'-r','linewidth',2)
axis off
% plot(l1,-7,'b','Marker','v','MarkerSize',5,'linewidth',2)
% plot(l2,7,'r','Marker','^','MarkerSize',5,'linewidth',2)
% plot([0 Time(end)],[-4 -4],':b','linewidth',1)
% plot([0 Time(end)],[4 4],':r','linewidth',1)
% plot([0.9 0.9],[-8 8],':k','linewidth',3)
% hold off
xlim([0 Time(end)])
ylim([-8 8])