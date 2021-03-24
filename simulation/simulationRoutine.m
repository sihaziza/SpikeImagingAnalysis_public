[output]=simulateVoltage;
trace=getPointProjection(output.movie);
t=getTime(trace,1000);

implay(output.movie)
plot(t,trace)
imshow(reshape(output.spatialFilters(:,1),200,200),[])
plot(output.tempFilters')

t=poissrnd(2,1,1000);
plot(t)


[movie_out,~, ~] = denoisingLOSS_new(output.movie,...
    'gridsize',-1,'windowsize',1000,'ranks',100);
implay([output.movie;movie_out])

M=[output.movie movie_out];
h5save('test2',single(M),'/mov')
% Generate realistic spike imaging dataset
% STEP 1: generate poisson spike train
% STEP 2: convolve with exponential decay of GEVI (tau_fast=0.7ms
% tau_slow=2ms)
% STEP 3: simulate photobleaching with exponential decay
% STEP 4: simulate neuropil
% STEP 5: simulate motion artefact


%% generate poisson spike train
Fs=1000;
firingRate=1;
duration=60;
refracT=5; %in ms
event_tau=2; %ms
event_SNR=1;
noise_std=1;
 temp_kernel = exp(-(1:5*event_tau)/event_tau);
    temp_kernel = event_SNR*noise_std*temp_kernel/max(temp_kernel); 
    
for iUnit=1
[ spikeMat] = poissonSpikeGen ( firingRate , duration ,refracT);

    convTrace=conv(spikeMat,temp_kernel,'same');
    
%     plot(getTime(spikeMat,1000),convTrace)
    
 neuron(:,iUnit)=convTrace;
   
end
%%
tauBleach=120; % in sec
t=getTime(neuron,Fs);
photoBleach=0.5*(1+exp(-t./tauBleach));
plot(t,photoBleach)
ylim([0 2])
plot(t,(baseline'.*(1+neuron).*photoBleach'))

T_filter=(baseline'.*(1+neuron).*photoBleach');

%% SIMULATE Hemodynamic Artefacts for 0D+T  recordings
Fs=1000;
Fhb=12; % heartbeat in Hz
A=10; % average photon count 
R=0.9; % correlation coeff between voltage and reference
% t=linspace(0,30,30*Fs)';%generate 30s recording

k=5;
baseline=A*(1+sin(2*pi*(t*Fhb)))+poissrnd(k*sqrt(A),size(t));

% [spikeRaster]=plotSpikeRaster(neuron,1000,3);

%% Convolution with exp decay
event_tau=2; %ms
event_SNR=1;
noise_std=1;
 temp_kernel = exp(-(1:5*event_tau)/event_tau);
    temp_kernel = event_SNR*noise_std*temp_kernel/max(temp_kernel); 
    convTrace=conv(spikeMat,temp_kernel,'same');
    plot(getTime(spikeMat,1000),convTrace)
    
% plot(tVec,spikeMat)
% plotRaster ( spikeMat , tVec*1000);

% plotAutoCorrelogram(spikeMat',1000)

%%
% This code cycles through each trial, finds all the spike times in that trial, and draws a black line for each spike. Once
% you have saved this function, use it visualize the spike matrix and label the axes. Here is the code to do so:
[spikeMat, tVec] = poissonSpikeGen(30, 1, 20);
plotRaster(spikeMat, tVec*1000);
xlabel('Time (ms)');
ylabel('Trial Number');

