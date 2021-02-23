clear all
% load dprimeData.mat
rootfolder = 'C:\Users\FlyMind\Desktop\Temp\';
% rootfolder = 'C:\Users\FlyMind\Desktop\old Ace\3.5SD\';

% rootfolder = 'H:\Data for fly choronic imaging paper\Chronic voltage imaging\20160926 304B SD-3\data\';

% rootfolder = 'C:\Users\FlyMind\Documents\MATLAB\';
% tifFiles = dir([rootfolder,'*d50_cleared.tif.mat']);
tifFiles = dir([rootfolder,'*_cleared.tif.mat']);
% tifFiles = dir([rootfolder,'*.mat']);

dpV = zeros(length(tifFiles),1);
spV = zeros(length(tifFiles),1);
dpVmean = 0;
spVmean = 0;

for ii = 1:length(tifFiles)
    filename = tifFiles(ii).name;
    load([rootfolder filename]);
% figure
highpassdata = highpassdata';
t= 0.001:0.001:length(highpassdata)/1000;
plot(t,highpassdata)
n = length(t);
hold on
plot(t(spikeind),zeros(length(spikeind),1),'o')
hold off
dFspikes = [];
a = 30;
b = 60;
dt = t(2)-t(1);
t_s = (1:b+a+1)*dt;
for i = 1:length(spikeind)
	if spikeind(i)-a >= 1 && spikeind(i)+b <= n
	mm = mean(highpassdata(spikeind(i)-a:spikeind(i)-a+10));
	dFspikes = [dFspikes; highpassdata(spikeind(i)-a:spikeind(i)+b)-mm];
	end
end

mean_dF = mean(dFspikes);
mean_dF = mean_dF+1-mean(mean_dF(end-5:end));
std_dF = std(dFspikes,[],1);
figure
plot(t_s,mean_dF)
ex_std = mean(std_dF(end-5:end));
V1 = 1/ex_std^2;

B = 1;
Lmax = sum(mean_dF.*log(mean_dF./B)-(mean_dF-B))*V1;
Lmin = sum(log(mean_dF./B) - (mean_dF-B))*V1;
Lshotsd = sqrt(V1)*sqrt(sum( (log(mean_dF)).^2  ));
dprime = (Lmax-Lmin)/Lshotsd;
dpV(ii,1) = dprime;
spV(ii,1) = length(spikeind)/(length(t)/1000);
end

% dpVmean = 7.1   
% spVmean = 6.5

dpVmean = mean(dpV)   
spVmean = mean(spV)

framerate = 1000;
threshold = linspace(0,dpVmean,1000);

false_positive = (1-erf((threshold)/sqrt(2)))*(framerate-spVmean);
false_negative = (1-erf((dpVmean-threshold)/sqrt(2)))*spVmean;

for i = 1:length(threshold)
    tempind = find(false_negative - false_positive > 0,1);
end
errorrate = false_negative(tempind)
errorrate1 = (1-erf(dpVmean/2/sqrt(2)))*framerate