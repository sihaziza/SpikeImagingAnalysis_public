[output]=simulateVoltage;
trace=getPointProjection(output.movie);
t=getTime(trace,1000);

implay(output.movie)
plot(t,trace)
imshow(reshape(output.spatialFilters(:,1),200,200),[])
plot(output.tempFilters')

t=poissrnd(2,1,1000);
plot(t)
%% generate poisson spike train
firingRate=1;
duration=60;
refracT=5; %in ms
event_tau=2; %ms
event_SNR=1;
noise_std=1;2
 temp_kernel = exp(-(1:5*event_tau)/event_tau);
    temp_kernel = event_SNR*noise_std*temp_kernel/max(temp_kernel); 
    
for iUnit=1:5
[ spikeMat] = poissonSpikeGen ( firingRate , duration ,refracT);

    convTrace=conv(spikeMat,temp_kernel,'same');
    
%     plot(getTime(spikeMat,1000),convTrace)
    
 neuron(:,iUnit)=convTrace;
   
end

plot(getTime(neuron,1000),neuron)
[spikeRaster]=plotSpikeRaster(neuron,1000,3);

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

