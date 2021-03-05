function [ spikeMat] = poissonSpikeGen ( firingRate,tSim,refractoryPeriod)
samplingRate=1000;
% firingRate=10;
% refractoryPeriod in ms
dt = 1/samplingRate; % s
nBins = floor ( tSim *samplingRate ) ;
temp=rand (1 , nBins );
% plot(temp)
spikeMat = temp<(firingRate*dt);
% plot(spikeMat)
k=find(spikeMat==1);
kidx=[(diff(k)./samplingRate)>refractoryPeriod/1000 0];
k=k(kidx>0);
spikeMat=zeros(size(spikeMat));
spikeMat(k)=1;
spikeMat=spikeMat';
% plot(spikeMat)
% plotAutoCorrelogram(spikeMat',samplingRate)
% tVec = 0: dt : tSim - dt ;
end
