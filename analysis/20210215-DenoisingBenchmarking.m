
%%
filePath='F:\GEVI_Spike\Preprocessed\Spontaneous\m915\20210215\meas03';
fileName='m915_d210215_s03laser100pct--fps701-cR_moco.h5';

h5Path=fullfile(filePath,fileName);
meta=h5info(h5Path);
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

fs=701;

movie=h5read(h5Path,dataset,[1 1 1],[mx my 10000]);
%% Denoising the movie

[movie_dns,~, ~] = denoisingLOSS_new(movie,'windowsize', 1000, 'ranks', 10);

binning=2;
movie_dns_bin=imresize3(movie_dns,[mx/binning my/binning size(movie_dns,3)],'box');

% [M,m] = compute_dfof(movie_dns_bin);
implay(mat2gray(movie_dns_bin))

pathDNS=strrep(h5Path,'.h5','_dns.h5');
h5save(pathDNS, single(movie_dns), '/mov');

%%

f0=mean(movie,3);
f0_dns=mean(movie_dns,3);
f0_dns_bin=mean(movie_dns_bin,3);

montage({mat2gray(f0), mat2gray(f0_dns), mat2gray(f0_dns_bin)})

%% Detrend the movie: detrend on movie average and apply

% movie_detrend=runPhotoBleachingRemoval(movie,'samplingRate',fs);

trace=getPointProjection(movie);
trace_dns=getPointProjection(movie_dns);
trace_dns_bin=getPointProjection(movie_dns_bin);
trace_dns_bin_norm=getPointProjection(movie_dns_bin_norm);

t=getTime(trace,fs);
figure()
plot(t,[trace trace_dns trace_dns_bin trace_dns_bin_norm])

dim=size(movie_dns_bin);
temp=reshape(movie_dns_bin,dim(1)*dim(2),dim(3));
movie_dns_bin_norm=ones(size(temp,1),1)*trace_dns_bin';

movie_dns_bin_norm=temp./movie_dns_bin_norm;

movie_dns_bin_norm=reshape(movie_dns_bin_norm,dim(1),dim(2),dim(3));
implay(mat2gray(movie_dns_bin_norm))

%% 

[output]=runEXTRACT(movie_dns_bin_norm);

%Perform post-processing such as cell checking and further data analysis
cell_check(output, movie_dns_bin_norm);

%% Non-rigid Moco 

filePath='F:\GEVI_Spike\DatasetAnalysisBenchmarking';
fileName='m83_d201124_s06dualColorSlidePulsingLEDs-fps781-cR_moco.h5';

h5Path=fullfile(filePath,fileName);

% vectorBandPassFilter=[1 25];
% bandPassMovieChunk(pathDNS,vectorBandPassFilter);
pathBP=strrep(h5Path,'.h5','_dns_bp.h5');
motionCorr1Movie(pathBP,'nonRigid', true);

%% Demixing using PCAICA
pathDNSMoco=strrep(h5Path,'.h5','_dns_moco.h5');
runPCAICA(h5Path,fs);
runPCAICA(pathDNS,781);
runPCAICA(pathDNSMoco,fs);

%% Demixe the movie

% PCAICA
% runPCAICA(h5Path,Fs,varargin)
% EXTRACT
% runEXTRACT()
path='F:\GEVI_Spike\Preprocessed\Whiskers\m85\20201124\meas00';
fileName='m85_d201124_s00dualColorSlidePulsingLEDs-fps601-cG_moco.h5';
h5Path=fullfile(path,fileName);

meta=h5info(h5Path);
disp('h5 file detected')
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

M=h5read(h5Path,dataset);
% M=M(:,:,1:2500);
M=-M+2*mean(M,3);
implay(mat2gray(Mtest))

Mtest=(M-mean(M,3))./mean(M,3);
% imshow([Mtest(:,:,1) bpFilter2D(Mtest(:,:,1),2,25,'parallel',false)],[])
Mtest=bpFilter2D(Mtest,2,25,'parallel',true);

pathDNS=strrep(h5Path,'.h5','_bin2_dns_dff_filt.h5');
h5save(pathDNS, single(Mtest), '/mov');
runPCAICA(pathDNS,781);

movie_in_detrend=runPhotoBleachingRemoval(movie_in,'samplingRate',701);

test=-trace;
[fitresult, gof,output] = createSplineFit(time, trace);
Fs=601;
trace=getPointProjection(M);
time=getTime(trace,Fs);

 [~, ~,outputExp] = createFitExp(-trace);
        tempExp=output.residuals;
        
trend=sh_bpFilter(trace,[inf 0.5],Fs);
temp=(trace-trend);
figure()
plot(time,[trace tempExp])
plotPSD([trace temp tempExp],'FrameRate',Fs,'FreqBand',[0.5 100],'Window',1,'scaleAxis','linear');


%% trying unmixing on EXTRACT output with movie average wavelet fitlered as a ref
% All on native, non-denoised movie.

ref=getPointProjection(movie);
ref=wdenoise(double(ref));
 [x,status] = denoisingTrace(y,0.5e-6);
plot(time,[y x sh_bpFilter(y,[inf 50],Fs) wdenoise(y)])

%%
%Initialize config
config=[];
config = get_defaults(config);

%Set some important settings
config.use_gpu=1;
config.avg_cell_radius=5;
% config.num_partitions_x=1;
% config.num_partitions_y=1;
config.cellfind_min_snr=0.1; % 5 is the default SNR
config.verbose = 2;
config.spatial_highpass_cutoff = 5;
config.spatial_lowpass_cutoff = 2;

%Perform the extraction
M=-Mbin_dns+2*mean(Mbin_dns,3);
output=extractor(M,config); 

%Perform post-processing such as cell checking and further data analysis
cell_check(output, M);

temp=full(output.spatial_weights(:,:,1));
tempUS=imresize(temp,binning,'box');
imshow(tempUS,[])
implay(mat2gray(temp))
tempUSraw=movie.*tempUS;
Fs=781;
traceRaw=getPointProjection(tempUSraw);
time=getTime(traceRaw,Fs);
plot(time,zscore(sh_bpFilter([traceRaw trace ica_sig(1,:)'],[0.5 inf],Fs))+[5 0 -5])
legend('raw','dns','ica')
sf_ica=imbinarize(permute(ica_filters,[2 3 1]), 25);
montage(sf_ica)

% crange = [min(ica_filters,[],[2 3]),max(ica_filters,[],[2 3])];
%         contourlevel = crange(2) - diff(crange,[],2)*[1,1]*0.8;
%%
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
tempExp=double(trace);
for iNotch=1:length(notchF)
[tempExp]=sh_NotchFilter(tempExp,Fs,notchF(iNotch));
end
traceFilt=sh_bpFilter(tempExp, [0.1 300], Fs);

figure(10)
plot(time,zscore([trace' traceFilt']))
plotPSD([trace' traceFilt'],'FrameRate',Fs,'FreqBand',[1 200],'Window',1,'scaleAxis','linear');

%% Compute d'
offset=15000;
test=trace(:,1:Fs);
plot(getTime(test,Fs),test)


%%
[units, trace]=getUnitsROI(h5Path,Fs)


