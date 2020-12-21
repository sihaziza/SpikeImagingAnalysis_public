% comparison bspike, min-median sliding window and high pass - DC removed
path='F:\GEVI_Spike\Preprocessed\Whiskers\m83\20201124\meas06';
filename='m83_d201124_s06dualColorSlidePulsingLEDs-fps781-cR_moco.h5';

meta=h5info(fullfile(path, filename));
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);mz=dim(3);
mx=50;
my=100;
nFrame=mz;
dataR=h5read(fullfile(path, filename),'/mov',[1 1 1],[50 100 nFrame]);

tProj=@(x) 1+(squeeze(mean(x,[1 2]))-mean(x(:,:,1),'all'))./mean(x(:,:,1),'all') ;
avgR=tProj(dataR);
disp('done')
%%
t=linspace(0,nFrame/781,nFrame);
plot(t,100.*[avgR1 avgR5 avgR7 avgR6 avgR])
legend('w/ 100% blue','w/ 100% blue','w/ 3% blue','wo/ blue' ,'wo/ blue')
ylim([50 100])
%%
bleachCorr=@(x) reshape(reshape(x,mx*my,nFrame)./(reshape(x(:,:,1),mx*my,1)*tProj(x)'),mx,my,nFrame);
dataRcorr=bleachCorr(dataR);
plot(zscore([avgR tProj(dataRcorr)]))

pntR=squeeze(dataR(50,100,:));
plot(pntR)
%%
temp=reshape(dataR,mx*my,nFrame);
tempCorr=zeros(size(temp));
% test=temp(iPixel,:);
tic;
parfor iPixel=1:mx*my
%     tic;
[~, ~,outputSpline] = createFitSpline(temp(iPixel,:));toc;
% [~, ~,outputExp] = createFitExp(temp(iPixel,:));
tempCorr(iPixel,:)=outputSpline.residuals;
% tempCorr(iPixel,:)=outputExp.residuals;
end
toc;

dataRcorr=reshape(tempCorr,mx,my,nFrame);
toc;


%%

[dataCorr]=runPhotoBleachingRemoval(data);

Fs=781;
[b,a]=butter(3,0.5/(Fs/2),'high');
avgR=tProj(dataR);
avgRcorr=tProj(dataRcorr);

plot(zscore(filtfilt(b,a,double([avgR avgRcorr])))+[2 -2])

implay(mat2gray([ dataR dataRcorr]),100)

saveFileName=strrep(filename,'.h5','_raw.h5');
  [info] = h5save(fullfile(path, saveFileName),dataR,'mov');

%%
temp=reshape(ones(mx*my,1)*tProj(dataR)',mx,my,nFrame);
plot(squeeze(temp(100,100,:)))

plot(zscore([avgR tProj(dataRcorr)]));
implay(mat2gray([dataR dataRcorr]),100)
imshow([dataR(:,:,1) dataRcorr(:,:,1);dataR(:,:,end) dataRcorr(:,:,end)],[])

max(dataR(:,:,1),[],'all')-min(dataR(:,:,1),[],'all')
max(dataR(:,:,end),[],'all')-min(dataR(:,:,end),[],'all')


mean(dataRcorr(:,:,1),'all')
mean(dataRcorr(:,:,1),'all')
max(dataRcorr(:,:,1),[],'all')-min(dataRcorr(:,:,1),[],'all')

max(dataRcorr(:,:,end),[],'all')-min(dataRcorr(:,:,end),[],'all')

%%
[fitresult, gof] = createFit_default(avgR);
% plot();
% plot(squeeze(mean(dataR,[1 2])));
%%
datafilt=bpFilter2D(dataR,min(size(dataR,1),size(dataR,2)),0.5,'parallel',true);
plot(zscore([tProj(datafilt) avgR ]));
max(datafilt(:,:,1),[],'all')-min(datafilt(:,:,1),[],'all')
max(datafilt(:,:,end),[],'all')-min(datafilt(:,:,end),[],'all')
mean(dataR(:,:,end),'all')
mean(datafilt(:,:,end),'all')