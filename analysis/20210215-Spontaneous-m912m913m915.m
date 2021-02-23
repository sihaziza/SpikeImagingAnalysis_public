
filePath='F:\GEVI_Spike\Preprocessed\Spontaneous\m913\20210215\meas01';
fileName='m913_d210215_s01laser100pct--fps701-cR_moco';
data=load(fullfile(filePath,'DemixingPCAICA',fileName,strcat(fileName,'_unitsPCAICAtemp.mat')));
shape=squeeze(data.ica_filters(end,:,:));

shape=squeeze(mean(data.ica_filters,1));
imshow(shape)

thres=max(shape(:))/5;
test=shape.*(shape>thres);
imshow(test)
%%

% A=sparse(double(test));
h5Path=fullfile(filePath,strcat(fileName,'.h5'));
meta=h5info(h5Path);
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

[mask, boundbox] = autoCropImage(test, 'plot',true);
mask=imbinarize(mask);
% imshow(mask)

units=h5read(h5Path,dataset,[boundbox(2) boundbox(1) 2*Fs],[boundbox(4)+1 boundbox(3)+1  numFrame-2*Fs+1]);
units=units.*mask;
trace=getPointProjection(units);
tracec=mean(units,[1 2]);
time=getTime(trace,Fs);

figure(10)
plot(time,trace)
%% offset value does not make sense > try on raw data
fileNameRaw='m913_d210215_s01laser100pct--fps701-cG';
h5Path=fullfile(filePath,strcat(fileName,'.h5'));
meta=h5info(h5Path);
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

movie_in=h5read(h5Path,dataset,[1 1 2*Fs],[mx my 2000]);
trace=getPointProjection(movie_in);
time=getTime(trace,Fs);
figure(10)
plot(time,trace)

trend=sh_bpFilter(trace,[inf 5],Fs);
plot(time,(trace-trend)./trend)

movie_in_detrend=runPhotoBleachingRemoval(movie_in,'samplingRate',701);

implay(mat2gray(movie_in_detrend))
traceDetrend=getPointProjection(movie_in_detrend);
time=getTime(traceDetrend,Fs);
figure(10)
plot(time,traceDetrend,'linewidth',2)

traceDetrendDenoised=getPointProjection(movie_out);
time=getTime(traceDetrendDenoised,Fs);

% input=[squeeze(movie_in_detrend(70,250,:)) squeeze(movie_out(70,250,:))];
input=[traceDetrend traceDetrendDenoised];
figure(10)
plot(time,input-mean(input),'linewidth',1)% plot(time,[trace trend traceDetrend],'linewidth',2)
legend('withDNS','withoutDNS')
implay(mat2gray([movie_in_detrend-mean(movie_in_detrend,'all');movie_out-mean(movie_out,'all')]))
% xlabel('Time (s)')
% legend('raw','trend','detrended')
%%
[movie_out200,E_out200, Info200] = denoisingLOSS(movie_in_detrend,'windowsize', 200);
[movie_out500,E_out500, Info500] = denoisingLOSS(movie_in_detrend,'windowsize', 500);
[movie_out1000,E_out500, Info1000] = denoisingLOSS(movie_in_detrend,'windowsize', 1000);

%%

ranks = 100; % the only critical parameter, smaller means keeping small set of eigen images -> smoother
[movie_out100newRk100,~, ~] = denoisingLOSS_new(movie_in_detrend,'windowsize', 500, 'ranks', ranks);
[movie_out1000newRk100,~, ~] = denoisingLOSS_new(movie_in_detrend,'windowsize', 1000, 'ranks', ranks);

implay(mat2gray([movie_in_detrend-mean(movie_in_detrend,'all');...
    movie_out100newRk100-mean(movie_out100newRk100,'all');...
    movie_out1000newRk100-mean(movie_out1000newRk100,'all')]))

%% Larger window size (~1s of recording) improve the noise reduction at a single pixel level, by ~20dB

% Compute time trace of the full movies
t200=getPointProjection(movie_out200);
t500=getPointProjection(movie_out500);
t1000=getPointProjection(movie_out1000);
M=[traceDetrend t200 t500 t1000];

% Compare with 1 pixel value
x=70;
y=275;
Mpix=squeeze([movie_in_detrend(x,y,:) movie_out200(x,y,:) movie_out500(x,y,:) movie_out1000(x,y,:)])';

time=getTime(t200,Fs);

h=figure('defaultaxesfontsize',16,'color','w')
subplot(2,5,[1 4])
plot(time,(M-mean(M)),'linewidth',1)
xlabel('Time (s)')
subplot(2,5,5)
plotPSD((M-mean(M))./mean(M),'FrameRate',Fs,'FreqBand',[0.5 200],'Window',1,'scaleAxis','linear','figureHandle',h);

subplot(2,5,[6 9])
plot(time,(Mpix-mean(Mpix)),'linewidth',1)
xlabel('Time (s)')

subplot(2,5,10)
plotPSD((Mpix-mean(Mpix))./mean(Mpix),'FrameRate',Fs,'FreqBand',[0.5 200],'Window',1,'scaleAxis','linear','figureHandle',h);
legend('raw','win200','win500','win1000')

%% Compare old and new denoising method. New one is way faster

% Compute time trace of the full movies
t500=getPointProjection(movie_out500);
t1000=getPointProjection(movie_out1000);
t100new=getPointProjection(movie_out100newRk100);
t1000new=getPointProjection(movie_out1000newRk100);
M=[traceDetrend t500 t1000 t100new t1000new];

% Compare with 1 pixel value
x=70;
y=275;
Mpix=squeeze([movie_in_detrend(x,y,:) movie_out500(x,y,:) movie_out1000(x,y,:) movie_out500new(x,y,:) movie_out1000new(x,y,:)])';

time=getTime(t200,Fs);

h=figure('defaultaxesfontsize',16,'color','w')
subplot(2,5,[1 4])
plot(time,(M-mean(M)),'linewidth',1)
subplot(2,5,5)
plotPSD((M-mean(M))./mean(M),'FrameRate',Fs,'FreqBand',[0.5 200],'Window',1,'scaleAxis','linear','figureHandle',h);

subplot(2,5,[6 9])
plot(time,(Mpix-mean(Mpix)),'linewidth',1)
xlabel('Time (s)')

subplot(2,5,10)
plotPSD((Mpix-mean(Mpix))./mean(Mpix),'FrameRate',Fs,'FreqBand',[0.5 200],'Window',1,'scaleAxis','linear','figureHandle',h);
legend('raw','win500','win1000','win100newRk100','win1000newRk100')

%%
units=h5read(h5Path,dataset,[boundbox(2) boundbox(1) 2*Fs],[boundbox(4)+1 boundbox(3)+1  numFrame-2*Fs+1]);
units(12,8,1)
units=units.*mask;
imshow(units(:,:,1),[])
implay(mat2gray(units))
rawPath='B:\GEVI_Spike\Raw\Spontaneous\m913\20210215\meas01';
dcimgPath=fullfile(rawPath,strcat(fileNameRaw,'.dcimg'));

[framedata,~]=  dcimgmatlab(0, dcimgPath);
imshow(framedata,[])
[S,L]=bounds(framedata,'all')

framedataResize=imresize(single(framedata),1,'box');
imshow(framedataResize,[])
[S,L]=bounds(framedataResize,'all')
%%
trace=getPointProjection(units);
time=getTime(trace,Fs);

notchF=[76.4 86.9 120 193.2 197.6];
temp=double(trace);
for iNotch=1:length(notchF)
[temp]=sh_NotchFilter(temp,Fs,notchF(iNotch));
end
traceFilt=sh_bpFilter(temp, [0.1 300], Fs);

figure(10)
plot(time,zscore([trace' traceFilt']))
plotPSD([trace' traceFilt'],'FrameRate',Fs,'FreqBand',[1 200],'Window',1,'scaleAxis','linear');

%% Compute d'
offset=15000;
test=trace(:,1:Fs);
plot(getTime(test,Fs),test)


%%
[units, trace]=getUnitsROI(h5Path,Fs)


