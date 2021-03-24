function [T]=simulateInvivoImagingSpikeTrain(event_rate, t,Fs, refractory_period)

event_tau=2;
tauBleach=120; % in sec
time=linspace(0,t/Fs,t)';
photoBleach=0.5*(1+exp(-time./tauBleach));
spike_SNR=5;

[spikeMat] = poissonSpikeGen ( event_rate , t/Fs,refractory_period);
temp_kernel = exp(-(1:5*event_tau)/event_tau);

% Simulate hemodynamic artefacts
hemoFreq=12; % heartbeat in Hz
hemoAmp=0.2; % in percent
offset=1; % average photon count 
baseline=offset+hemoAmp.*(sin(2*pi*(time*hemoFreq))+randn(size(time)));

T=conv(spikeMat,temp_kernel,'same');
T=(baseline+spike_SNR*T).*photoBleach;    

plot(time,T)

end