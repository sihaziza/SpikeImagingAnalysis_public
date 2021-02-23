clear all;
close all;

directory='F:\GEVI_Spike\INTAN\m915_Spike';
ePath='INTAN Data';
oPath='TEMPO Data';
mouse='m2';
date='20200413';

eFile='rec__200413_154633.rhd';
oFile=num2str(1);

% % Load ePhys data
[eData, eDataIO, eTime, eFs]=read_IntanRDH(fullfile(directory,ePath,mouse,date),eFile);

% Load oPhys data
[oData, oDataIO, oTime, oFs]=read_TEMPO(fullfile(directory,oPath,mouse,date),num2str(oFile));

% sh_PSDplot(sh_Standardize(oData),[0.5 100],oFs,5);
% sh_PSDplot(sh_Standardize(eData),[0.5 100],eFs,5);

% Synchronize ePhys and oPhys considering the first and last trigger
% Pick a baseline of 10sec prior the first and posterio to the last stimulus
% find the time embedding on the low sampling frequency (often oPhys)
baseline=10; % in seconds; time prior

[on,~]=find(diff(oDataIO) == 1,1,'first');
[off,~]=find(diff(oDataIO) == -1,1,'last');
% off=length(oDataIO);
oRange=on-baseline*oFs:off+baseline*oFs;
idx=round(length(oRange)/oFs,0); % in sec

oTTL=oDataIO(on-baseline*oFs:(on-baseline*oFs)+idx*oFs-1,:);
oTemp=oData(on-baseline*oFs:(on-baseline*oFs)+idx*oFs-1,:);

[on,~]=find(diff(eDataIO) == 1,1,'first');
[off,~]=find(diff(eDataIO) == -1,1,'last');
% off=length(oDataIO);
eRange=on-baseline*eFs:off+baseline*eFs;
idx=round(length(eRange)/eFs,0); % in sec

eTTL=eDataIO(on-baseline*eFs:(on-baseline*eFs)+idx*eFs-1,:);
eTemp=eData(on-baseline*eFs:(on-baseline*eFs)+idx*eFs-1,:);

% Filter all traces before resampling
[oTemp]=sh_bpFilter(oTemp, [0.1 200], oFs);
[eTemp]=sh_bpFilter(eTemp, [0.1 200], eFs);

% Resamples the input sequence, x, at p/q times the original sample rate.
% Treats each column of x as an independent channel.
% Applies an antialiasing FIR lowpass filter to x
% Compensates for the delay introduced by the filter.
Fs=min(oFs,eFs)/2;
oTTL=downsample(oTTL,oFs/Fs);
eTTL=downsample(eTTL,eFs/Fs);

oTemp = sh_Standardize(downsample(oTemp,oFs/Fs));
eTemp = sh_Standardize(downsample(eTemp,eFs/Fs));

Time=0:1/Fs:(length(oTemp)-1)/Fs;

figure(2)
subplot(2,1,1)
plot(eTime,eDataIO,oTime,oDataIO)
subplot(2,1,2)
plot(Time,[eTTL oTTL])
%%

sh_PSDplot(sh_Standardize(oTemp),[0.5 100],Fs,5);
sh_PSDplot(sh_Standardize(eTemp),[0.5 100],Fs,5);
%%
rgi=1;
rge=length(oTemp)/2;
A=oTemp(rgi:rge,:);
LFP=eTemp(rgi:rge,3);

% A=reshape(A(~isnan(A)),[],4);
% LFP=reshape(LFP(~isnan(LFP)),[],3);
% eTemp=LFP;

Sex=A(:,2);
Sin=A(:,4);
reference=A(:,3);

[UMXinG]=sh_RobustLR(Sin, reference, [9 14], Fs);
% [UMXrefG]=sh_RobustLR(reference, UMXinG, [1 50], Fs);
[UMXexG]=sh_RobustLR(Sex, reference, [1 30], Fs);

% sh_PSDplot([UMXexG UMXrefG UMXinG],[1 100],Fs,5);

%%
% g=[0.4660 0.6740 0.1880];
% r=[200 10 10]./255;
%
% T=Time(rgi:rge);
% % figure('defaultaxesfontsize',16)
% plot(T,LFP+7,'k','linewidth',1.5)
% hold on
% plot(T,sh_bpFilter(UMXex,[0.1 80],Fs),'Color',g,'linewidth',1.5)
% hold on
% plot(T,sh_bpFilter(UMXin,[0.1 80],Fs)-7,'Color',r,'linewidth',1.5)
% hold off
% xlim([55 59])
% ylim([-11 11])
% legend('LFP','Excitatory','Inhibitory')

% figure()
% Fband=[2 20];
% [c,lag]=xcorr(sh_bpFilter(Sin(1:end-9), Fband, Fs), sh_bpFilter(reference(10:end), Fband, Fs),Fs,'coeff');
% plot(lag,c)

% try by tracking the phase shift of Hemodynamics
%%
[UMXin, alphain]=sh_PieceWiseUMX(Sin, reference, 5, [9 14], Fs);
[UMXref, alpharef]=sh_PieceWiseUMX(reference, UMXin, 5, [1 50], Fs);
[UMXex, alphaex]=sh_PieceWiseUMX(Sex, reference, 5, [9 14], Fs);

figure('defaultaxesfontsize',16)
plot(Time(1:length(Sex)),[alpharef alphaex alphain],'linewidth',2)
legend('Reference','Excitatory','Inhibitory')

sh_PSDplot([UMXex UMXref UMXin],[1 100],Fs,3);

%%

M=sh_Standardize([reference Sex]);

[coeff,score,latent,tsquared,explained,mu] = pca(M);

score=sh_Standardize(score);

figure(1)
plot(M(1:1000:end,1),M(1:1000:end,2),'*',...
    score(1:1000:end,1),score(1:1000:end,2),'*',...
    UMXrefG(1:1000:end,1),UMXexG(1:1000:end,1),'*')
axis square
legend('Raw','RLR','PCA')

T=Time(rgi:rge);

figure(1);
subplot(311)
plot(T,[tsquared sh_Standardize(M)])
xlim([360 380])
title('Raw, RLR and PCA comparison')
subplot(312)
plot(T,[tsquared sh_Standardize([UMXrefG UMXexG])])
xlim([360 380])
subplot(313)
plot(T,[tsquared sh_Standardize(score)])
xlim([360 380])
legend('tSquared','Ref','Volt')

figure(2)
biplot( coeff,'scores',score(1:500:end,:),'varlabels',{'Volt','Ref'});

%%
LFP=sh_Standardize(sh_bpFilter(eTemp(rgi:rge,3),[0.1 200],Fs));
pyram=sh_Standardize(sh_bpFilter(UMXex,[0.1 200],Fs));
inter=sh_Standardize(sh_bpFilter(UMXin,[0.1 200],Fs));
reference=sh_Standardize(sh_bpFilter(reference,[0.1 200],Fs));

%%
minFreq = 1;
maxFreq1 = 200;
maxFreq2 = 150;

% cqt(LFP,'SamplingFrequency',Fs,'BinsPerOctave',96,...
%'FrequencyLimits',[minFreq maxFreq])'blackmanharris' | 'itersine' | 'bartlett'

cax=[-40 -15];
% cax='auto';
Bin=48;

figure('defaultaxesfontsize',16,'color','w')

subplot(411)
cqt(LFP,'SamplingFrequency',Fs,'BinsPerOctave',Bin,...
    'FrequencyLimits',[minFreq maxFreq1],'window','bartlett');
title('LFP')
caxis([-40 -15])
ylim([1 20])
xlabel('')
% colormap(jet)
% set(gca, 'YScale', 'log')
% xlim([2 20])

subplot(412)
cqt(pyram,'SamplingFrequency',Fs,'BinsPerOctave',Bin,...
    'FrequencyLimits',[minFreq maxFreq1],'window','bartlett');
title('TEMPO - Pyramidal')
caxis(cax)
ylim([1 20])
xlabel('')
% colormap(jet)
% set(gca, 'YScale', 'log')
% xlim([2 20])

subplot(413)
cqt(LFP,'SamplingFrequency',Fs,'BinsPerOctave',Bin,...
    'FrequencyLimits',[minFreq maxFreq1],'window','bartlett');
title('LFP')
caxis(cax)
ylim([1 150])
xlabel('')
% colormap(jet)
% set(gca, 'YScale', 'log')
% xlim([2 20])

subplot(414)
cqt(inter,'SamplingFrequency',Fs,'BinsPerOctave',Bin,...
    'FrequencyLimits',[minFreq maxFreq1],'window','bartlett');
title('TEMPO - Interneurons')
caxis(cax)
ylim([1 150])
% xlabel('T')
colormap(parula)
% set(gca, 'YScale', 'log')
% xlim([2 20])

% subplot(515)
% cqt(reference,'SamplingFrequency',Fs,'BinsPerOctave',Bin,...
%     'FrequencyLimits',[minFreq maxFreq1],'window','hamming');
% title('Optical Reference')
% caxis(cax)
% % ylim([1 20])
% colormap(jet)
% % set(gca, 'YScale', 'log')
% % xlim([2 20])

%%


%%
figure()
spectrogram(UMXex,10*Fs,5*Fs,5*Fs,Fs,'yaxis','onesided');
ylim([1 50])
caxis([-40 -10])

figure()
spectrogram(UMXin,10*Fs,5*Fs,5*Fs,Fs,'yaxis','onesided');
ylim([1 50])
caxis([-40 -10])
%%
h=figure('defaultaxesfontsize',16);
subplot(131)
sh_PSDplot(sh_Standardize([A(:,3) UMXrefG UMXref]),[0.5 100],Fs,2,'figure',h);
title('Reference')
legend('Raw','Global','Piece-Wise')

subplot(132)
sh_PSDplot(sh_Standardize([A(:,2) UMXexG UMXex]),[0.5 100],Fs,2,'figure',h);
title('Excitatory')

subplot(133)
sh_PSDplot(sh_Standardize([A(:,4) UMXinG UMXin]),[0.5 100],Fs,2,'figure',h);
title('Inhibitory')

%% Compute the coherence and phase relationship
sh_Coherence(UMXex, UMXin,Fs,2);

sh_Coherence(LFP,[pyram inter],Fs,2);

%% Compute Time-varying Coherence and Phase
sh_XCoherencePhaseTime(LFP, UMXex, 5, Fs, 0.5)
sh_XCoherencePhaseTime(LFP, UMXin, 5, Fs, 0.5)
sh_XCoherencePhaseTime(UMXex, UMXin, 5, Fs, 0.5)
caxis([0 1])
ylim([1 50])
set(gca, 'YScale', 'linear')
xlim([0 15])

% maybe sort by theta energy and look at gamma coherence?

%% someting not right here... check the code again.

for i=1:1
    Fband=[0.5 4; 5 10; 15 50; 50 150];
    L=[1 0.5 0.5 0.2];
    step=60;
    sh_XCorrelationTime(LFP, UMXin, Fband, L, step, Fs)
end
caxis([-1 1])

%%
marging=2;
[oArray]=sh_StimEpoch(Out1',TTL,marging,Fs);
a=1;
figure()
for idx=[1 4 3 2]
    p=1;
    bandAVG=[];
    idx
    for d=1:200
        Fband=[d d+1];
        temp=sh_bpFilter(oArray(:,:,idx), oFs, Fband);
        window = gausswin(Fs/2);
        powerArray= fastrms(temp,window,1,1);
        
        % sh_singleERPcolor(powerArray,[-2 3],cRange,Fs)
        bandAVG(:,p)=mean(powerArray,2);
        p=p+1;
    end
    
    subplot(1,4,a)
    imagesc(bandAVG(:,3:end)')
    a=a+1;
end
% figure()
% plot(sh_zscore([oTemp(:,[2 4]) eTemp(:,1)])+[-5 0 5])
%%

oRange=10*60*1000:length(Data);
Fs=1000;
tic;
% Detected pure frequency noise
[F,X]=sh_PSDplot(Data(oRange,1),[10 200],10);

% 1Hz min peak distance, 1dB peak prominance
[pks,locs,w,p] =findpeaks(X,'MaxPeakWidth',5,'MinPeakProminence',2);

plot(F,X,F(locs),pks,'*r')

Fcenter=F(locs);
[idx,~]=find(Fcenter>10);
Fcenter=Fcenter(idx);
DataTemp=Data(oRange,1:3); % all blue laser affected trace
for i=1:length(Fcenter)
    [DataTemp]=sh_NotchFilter(DataTemp,Fs,Fcenter(i));
end

[F,X]=sh_PSDplot(DataTemp,[0.5 200],2);

%%
minFreq = 1;
maxFreq = 200;
wave=[LFP UMXex LFP UMXin];
cax=[-33 -17;-35 -19;-38 -20;-38 -19];
Bin=30;
yL=[1 20;1 20;1 150;1 150];

N = size(wave,1);

figure('defaultaxesfontsize',16,'color','w')
for i=1:4
    %'hamming' | 'blackmanharris' | 'itersine' | 'bartlett'
    subplot(4,1,i)
    [cfs,f]=cqt(wave(:,i),'SamplingFrequency',Fs,'BinsPerOctave',Bin,...
        'FrequencyLimits',[minFreq maxFreq],'window','hann');
    
    plotcqt(cfs,f,Fs,N)
    
    caxis(cax(i,:))
    ylim(yL(i,:))
end

colormap(parula)
%% unmixing optimum using LFp-Source Xcorr maximiation
L=0.2;
figure('defaultaxesfontsize',20,'color','w');
for a=[0 0.8 0.81824]
    temp=sh_Standardize(Sex-a.*reference);
    [cex,lag]=xcorr(LFP,temp,L*Fs,'coeff');
    plot(lag/Fs,cex,'linewidth',2)
    hold on
end
[cex,lag]=xcorr(LFP,UMXex,L*Fs,'coeff');
plot(lag/Fs,cex,'linewidth',2)
legend('Raw','Global-XCorr','Global-RLR','Local-LRL')
hold off
%% Peak correlation lag versus frequency
BW=2; %Hz
LFP=sh_Standardize(sh_bpFilter(eTemp(rgi:rge,3),band,Fs));
pyram=sh_Standardize(sh_bpFilter(UMXex,band,Fs));
inter=sh_Standardize(sh_bpFilter(UMXin,band,Fs));
% reference=sh_Standardize(sh_bpFilter(reference,[0.1 200],Fs));
% 
% L=0.5;
% 
% for band=1:2:200
%     %     temp=
%     [cex,~]=xcorr(LFP,pyram,L*Fs,'coeff');
%     
%     []=max(abs(cex,max))
%     [cin,lag]=xcorr(LFP,inter,L*Fs,'coeff');
% end

%%
g=[120 170 50]./255;
r=[200 10 10]./255;
band=[30 120];
LFP=sh_Standardize(sh_bpFilter(eTemp(rgi:rge,3),band,Fs));
pyram=sh_Standardize(sh_bpFilter(UMXex,band,Fs));
inter=sh_Standardize(sh_bpFilter(UMXin,band,Fs));
% reference=sh_Standardize(sh_bpFilter(reference,[0.1 200],Fs));

L=0.25;
[crf,~]=xcorr(pyram,inter,L*Fs,'coeff');
[cex,~]=xcorr(LFP,pyram,L*Fs,'coeff');
[cin,lag]=xcorr(LFP,inter,L*Fs,'coeff');

fig=figure('defaultaxesfontsize',20,'color','w');
set(fig,'defaultAxesColorOrder',[g; r]);
yyaxis left
plot(lag/Fs,cex,'linewidth',3,'color',g)
%     hold on
%  plot(lag/Fs,crf,'k','linewidth',3)
%  hold off
ylim(1.1.*[-max(abs(cex)) max(abs(cex))])
ylabel('Corr. Coeff.')

yyaxis right
plot(lag/Fs,cin,'linewidth',3,'color',r)
hold on
plot([0 0],[-1 1],'--k','LineWidth',3)
hold off
ylim(1.1.*[-max(abs(cin)) max(abs(cin))])
ylabel('Corr. Coeff.')

xlim([-L L])
% legend('TEMPO – Excitatory Neurons','TEMPO – Inhibitory Neurons')
xlabel('Lagging Time (s)')
%% Plot Q-transform using custom plot function
clear cfs f

wave=LFP;
[cfs,f]=cqt(wave,'SamplingFrequency',Fs,'BinsPerOctave',48,...
    'FrequencyLimits',[0.1 200]);

N = size(wave,1);
figure()
plotcqt(cfs,f,Fs,N)
ylim([1 150])
caxis([-45 -10])

%%
f = f(1:cfs.NyquistBin);
coefs = cfs.c(1:cfs.NyquistBin,:);
P=20*log10(abs(coefs)+eps(0));

figure(12)
plot(f, smoothdata(mean(P,2),'sgolay',20))
xlim([0.5 150])
% hold on
set(gca, 'XScale', 'log')

%     Numtimepts = size(coefs,2);
% t = linspace(0,N*1/Fs,Numtimepts);
%     size(t)
%%
function plotcqt(coefs,freq,Fs,N)

freq = freq(1:coefs.NyquistBin);
coefs = coefs.c(1:coefs.NyquistBin,:);

Numtimepts = size(coefs,2);
t = linspace(0,N*1/Fs,Numtimepts);

[freq,~,uf] = engunits(freq,'unicode');
[t,~,ut] = engunits(t,'unicode','time');
freqlbl = getfreqlbl([uf 'Hz']);
xlbl = ...
    [getString(message('Wavelet:getfrequnitstrs:Time')) ' (' ut ')'];

% ax = newplot;

hndl=pcolor(t, freq, 20*log10(abs(coefs)+eps(0)));
shading 'interp'
h=colorbar;
colormap(jet)
hndl.EdgeColor = 'none';
axis xy; axis tight;
view(0,90);
% h.Label.String = getString(message('Wavelet:FunctionOutput:dB'));
% ylabel(freqlbl);
% xlabel(xlbl);
% title(getString(message('Wavelet:FunctionOutput:constantq')));
end