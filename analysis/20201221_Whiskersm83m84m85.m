%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% DUPLEX Paper - Spike Imaging Analysis Pipeline %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script runs a demo raw file (.dcimg; proprietary format) and proeed
% with the following steps:
%   > gather metadata and create all diagnostic paths. (see metadata
%   > loading .dcimg file based off the metadata file and save as .h5
%   > motion correction (based off NoRMcorr - github package)
%   > demixing (based off PCA/ICA - Mukamel, Neuron 2009)
% At the end, a .mat file is saved with the spatiotemporal filters for each
% detected neurons.

% Follow the workspace prompt as user input will be required... ;-)

% %% INPUT PATH TO .dcimg FILE
%
% mainFolder='B:\GEVI_Spike\Raw\Whiskers';
% mouse={'m83' 'm84' 'm85'};
%
% % date='20200416';

%% LOAD AND CONVERT .dcimg RAW MOVIE

mainFolder='F:\GEVI_Spike\Preprocessed\Whiskers';
mouse={'m85'};
% fail=[];
% date='20200416';
for iMouse=1%:length(mouse)
    metaPathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(metaPathMain,'2020*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(metaPathMain,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
        for iFolder=10;%:length(folderName)
            try
                metaPath=fullfile(metaPathMain,date,folderName{iFolder});
                dcimgpath=fullfile('X:\GEVI_Spike\Raw\Whiskers',mouse{iMouse},date,folderName{iFolder});
                temp=load(fullfile(metaPath,'metadata.mat'));
                metadata=temp.metadata; clear temp;
%                 Nametemp=dir(fullfile(metadata.allPaths.dcimgPath,'*_framestamps 0.txt'));
                Nametemp=dir(fullfile(dcimgpath,'*_framestamps 0.txt'));
                [fifo]=importdata(fullfile(Nametemp.folder,Nametemp.name));
                ttl=fifo.data(metadata.frameRange(1):metadata.frameRange(2),4);
                loco=fifo.data(metadata.frameRange(1):metadata.frameRange(2),2);
                time=fifo.data(metadata.frameRange(1):metadata.frameRange(2),1);
                fps=metadata.fps;
                % 12 cm diameter wheel, 600 rot. encod.
                disp=(pi*12/600).*loco;
                %                 plot(time/1000, disp,time/1000,ttl)
                dt=(time(2)-time(1))/1000;
                v=movavg(diff(disp)./dt,'linear',round(fps/2));
                
                %                 figure('defaultaxesfontsize',12,'color','w')
                %                 subplot(411)
                %                 plot(time(1:end-1)/1000,ttl(1:end-1),'k','linewidth',2)
                %                 xlim([time(1)/1000 time(end-1)/1000])
                %                 axis off
                %                 title(strcat('Behavior Summary-',mouse{iMouse},folderName{iFolder}))
                %                 subplot(4,1,[2 4])
                %                 yyaxis left
                %                 plot(time(1:end-1)/1000, disp(1:end-1),'linewidth',2)
                %                 ylabel('Displacement (cm)')
                %                 yyaxis right
                %                 plot(time(1:end-1)/1000, v,'linewidth',2)
                %                 ylabel('Speed (cm/s)')
                %                 xlim([time(1)/1000 time(end-1)/1000])
                %
                %
                demixPath=fullfile(metadata.allPaths.exportFolder,'DemixingPCAICA');
                temp=dir(demixPath);
                for i=1:length(temp)
                    if strfind(temp(i).name,'G_moco')>0
                        try
                            
                            fileNameDemixG=fullfile(demixPath,temp(i).name);
                            
                            units=load(fullfile(fileNameDemixG, strcat(temp(i).name,'_unitsPCAICAtemp.mat')));
                            
                            filterS=units.ica_filters;
                            traceT=units.ica_sig';
                            [b,a]=butter(8,50/(fps/2),'high');
                            
                            cond=@(x) (x-mean(x))./std(filtfilt(b,a,double(x)));
                            
                            traceT_G=cond(traceT)-linspace(1,20*size(traceT,2),size(traceT,2));
                        end
                    elseif strfind(temp(i).name,'R_moco')>0
                        try
                            fileNameDemixR=fullfile(demixPath,temp(i).name);
                            
                            units=load(fullfile(fileNameDemixR, strcat(temp(i).name,'_unitsPCAICAtemp.mat')));
                            
                            filterS=units.ica_filters;
                            traceT=units.ica_sig';
                            [b,a]=butter(8,50/(fps/2),'high');
                            
                            cond=@(x) (x-mean(x))./std(filtfilt(b,a,double(x)));
                            
                            traceT_R=cond(traceT)-linspace(1,20*size(traceT,2),size(traceT,2));
                        end
                    end
                    
                end
                
                warning('off','all');
                
                figure('defaultaxesfontsize',12,'color','w')
                subplot(15,1,1)
                plot(time(1:end-1)/1000,ttl(1:end-1),'k','linewidth',2)
                xlim([time(1)/1000 time(end-1)/1000])
                axis off
                title(fileNameDemixG)
                
                subplot(15,1,[2 3])
                plot(time(1:end-1)/1000, v,'k','linewidth',2)
                ylabel('Speed (cm/s)')
                xlim([time(1)/1000 time(end-1)/1000])
                set(gca,'xtick',[])
                
                subplot(15,1,[4 15])
                plot(time/1000,traceT_G)
                %                 xlabel('Time (s)')
                xlim([time(1)/1000 time(end-1)/1000])
                xlabel('Time (s)')
                
                figure('defaultaxesfontsize',12,'color','w')
                subplot(15,1,1)
                plot(time(1:end-1)/1000,ttl(1:end-1),'k','linewidth',2)
                xlim([time(1)/1000 time(end-1)/1000])
                axis off
                title(fileNameDemixR)
                
                subplot(15,1,[2 3])
                plot(time(1:end-1)/1000, v,'k','linewidth',2)
                ylabel('Speed (cm/s)')
                xlim([time(1)/1000 time(end-1)/1000])
                set(gca,'xtick',[])
                
                subplot(15,1,[4 15])
                plot(time/1000,traceT_R)
                %                 xlabel('Time (s)')
                xlim([time(1)/1000 time(end-1)/1000])
                xlabel('Time (s)')
            catch ME
                ME;
            end
        end
    end
end
%%
pAce=traceT_G(:,[1 2 3 4 5]);
pAceR=traceT_R(:,[2 3 7]);
spikes=zscore([pAce pAceR]);
steps=linspace(1,5*size(spikes,2),size(spikes,2));
figure(1)
plot(time,spikes(:,1:5)-steps(:,1:5),'g','linewidth',1.5)
hold on
plot(time,spikes(:,6:8)-steps(:,6:8),'m','linewidth',1.5)
hold off
xlim([-1  5])
ylim([-50 10])
legend({'NDNF-Ace2.0' 'VIP-Vnm2.0'})
%%
% ttl, v
Fs=600;
% figure()
% plot(time/600, pAceR)
BW=[0.5 4;4 7;10 15;15 25;25 50;60 120];
for iBW=1:6
spikesFilt(:,:,iBW)=sh_bpFilter(double(spikes),BW(iBW,:),Fs);
end

figure(1)
for iNeuron=1:size(spikes,2)
    subplot(1,size(spikes,2),iNeuron)
    plot(spikes(:,iNeuron)+5,'k')
    hold on
    plot(ttl+5*2,'k')
    plot(zscore(v)+5*3,'k')
    for iBW=1:size(BW,1)
        plot(squeeze(spikesFilt(:,iNeuron,:))-linspace(1,2*size(BW,1),size(BW,1)))
    end
    hold off
end
%%
[array,StimBand]=sh_StimEpoch(spikes,ttl,0.5,Fs);

n=size(spikes,2);
m=size(array,2);
figure(2)
for i=1:n
subplot(1,n,i)
    sh_singleERPcolor(array(:,:,i),StimBand,[-5 5],Fs)
    xlim([-0.5 1])
end

T=StimBand(1):1/Fs:StimBand(2)-1/Fs;

figure(3)
for i=1:n
subplot(1,n,i)
    for j=1:m
    plot(T,array(:,j,i)+3*(j-1))
    hold on
    end
hold off 
xlim([-0.5 1])
end
%%
[spikeRaster]=plotSpikeRaster(spikes,Fs,6);
plotXCorrelogram(spikeRaster,Fs)
%%
type = 'linear';
windowSize = Fs;
FR=zscore(movavg(spikeRaster,type,windowSize));
figure(1)
for iNeuron=1:size(spikes,2)
    subplot(1,size(spikes,2),iNeuron)
    plot(FR(:,iNeuron)+5,'k')
    hold on
    plot(ttl+5*2,'k')
    plot(zscore(v)+5*3,'k')
    for iBW=1:size(BW,1)
        plot(squeeze(spikesFilt(:,iNeuron,:))-linspace(1,2*size(BW,1),size(BW,1)))
    end
    hold off
end

%% plot various metrics to measure Spiking Variability:
% - Spike rate 
% - Fano factor
% - Inter Spike Intervals (ISIs) distribution
% - spike PSD
% -Coefficient of Variation (Cv)
% -Local Variation (Lv)
% -Autocorrelation
% -Synchronization Index (Vector Strength)
% -Post-Stimulus Time Histograms (PSTH) 

%%
for i=1:8
Fano=std(spikeRaster(:,i)).^2/mean(spikeRaster(:,i))
end
%%
epoch=double(test);
[b,a]=butter(8,5/(fps/2),'high');

epoch=filtfilt(b,a,double(test));

figure(1)
plot(epoch)
hold on
findpeaks(filtfilt(b,a,double(epoch)).^2,'MinPeakHeight',25)
hold off

[pks,locs] =findpeaks(filtfilt(b,a,double(epoch)).^2,'MinPeakHeight',25);
array=[];

for iPeak=1:length(pks)-1
    array(:,iPeak)= epoch(max(locs(iPeak)-10,1):min(locs(iPeak)+10,length(epoch)),1);
end

figure()
plot(mean(array,2))
hold on
plot(array)
hold off
template=normalize(mean(array,2),'range');
template=template-max(template);

[c,lags] = xcorr(epoch,template);
plot(lags,c)
hold on
plot(10*epoch)
hold off

C = conv(template,epoch);
plot(C)
L=length(template);
for i=1:length(epoch)-L
    corr(i)=max((epoch(i:i+L-1).*template).^2);
end
plot(corr)
hold on
plot(epoch)
plot(10*template)
hold off

%% Process with ML spikes

fps=601;
pACEr=zscore(traceT_R(1:end,15));

[b,a]=butter(3,50/(0.5*fps),'high');

temp=filtfilt(b,a,double(pACEr));
sig=std(temp);

pACEr=pACEr/sig;
pACEr=double(pACEr-median(pACEr)+2);
median(pACEr)

figure()
plot(pACEr)

%%
figure(1)
plot(5*tr)
hold on
[peak, locs]=findpeaks(tr.^2,'MinPeakHeight',19)
hold off
locs=locs'./fps
%% Better to do it by chunk then all together... bleaching, motion... distrub the convergence

plotPSD(spikes,'FrameRate',fps,'FreqBand',[-1 2],'Window',1,'scaleAxis','log','plotAverage',true);


%% 
path='F:\GEVI_Spike\Preprocessed\Whiskers\m85\20201124\meas09';
name='m83_d201124_s00dualColorSlidePulsingLEDs-fps601-cG_moco.h5';
data=h5read(fullfile(path,name),'/mov');
%%
sigma=std(data,[],3);
imshow(sigma,[]);
%%
datbin=imresize(data,[2 4],'box');
imshow(datbin(:,:,1),[])
%%

% [dataCorr]=runPhotoBleachingRemoval(datbin);
pix=[2 3];
temp=squeeze(datbin(pix(1),pix(2),:));
% tempCorr=squeeze(dataCorr(pix(1),pix(2),:));

temp=reshape(double(datbin),size(datbin,1)*size(datbin,2),size(datbin,3))';
plotPSD(temp,'FrameRate',fps,'FreqBand',[0.5 100],'Window',2,...
    'scaleAxis','linear','plotAverage',true);
%%
% figure()
% plot([temp tempCorr])
% plot(sh_bpFilter(double([temp tempCorr]),[25 50],Fs));

time=linspace(0,((length(ttl)-1)/Fs),length(ttl));

figure('defaultaxesfontsize',16,'color','w');
spectrogram(tempCorr,1*Fs,0.9*Fs,10*Fs,Fs,'yaxis')
ylim([1 120])
caxis([0 25])
hold on
plot(time,5*ttl,'k','linewidth',2)
plot(time(1:end-1),abs(v),'k','linewidth',1)
hold off
% set(gca, 'YScale', 'log')










