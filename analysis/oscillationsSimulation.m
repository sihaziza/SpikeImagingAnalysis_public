fs=1000;





%% Convolution with exp decay

traceUP = 1-a1.*exp(-(0:fs)./tau1)-(1-a1).*exp(-(0:fs)./tau2);
traceDOWN=a2*exp(-(0:fs)./tau3)+(1-a2)*exp(-(0:fs)./tau4);
ton=-0.1:1/fs:0.5;
toff=ton-0.005;
u = heaviside(t)+abs(heaviside(toff)-1);
plot(ton,u)
ucv = conv(u,traceUP);%+conv(abs(heaviside(toff)-1),traceDOWN,'same');
plot(ton,ucv)

spikeON=zeros(size(t));
spikeOFF=zeros(size(t));
ST=[501 601];
spikeON(ST)=1;
spikeOFF(ST+5)=1;


%     temp_kernel = temp_kernel/max(temp_kernel);
convTraceUP=conv(spikeON,traceUP);
plot(getTime(convTraceUP,1000),convTraceUP)

convTraceDOWN=conv(spikeOFF,traceDOWN).*convTraceUP(ST+5);
plot(getTime(convTraceDOWN,1000),convTraceDOWN)

convTraceDOWN=conv(spikeOFF,traceDOWN).*convTraceUP(ST+5);
gevi=[convTraceUP(1:ST+5+1) convTraceDOWN(ST+5:end)];
plot(getTime(gevi,1000),gevi)
xlim([0.48 0.8])
%%




fs=2000;
duration=0.5; % in sec
t=-0.5:1/fs:duration;
% Create GEVI kernel
traceUP = 1-(a1.*exp(-(0:100)./tau1)+(1-a1).*exp(-(0:100)./tau2));
traceDOWN=a2*exp(-(0:100)./tau3)+(1-a2)*exp(-(0:100)./tau4);

spikeON=zeros(size(t));
% spikeOFF=zeros(size(t));
ST=find(t>0,1);
spikeON(ST)=1;
% spikeOFF(ST+1)=1;


%     temp_kernel = temp_kernel/max(temp_kernel);
convTraceUP=conv(spikeON,traceUP);
% plot(getTime(convTraceUP,1000),convTraceUP)

convTraceDOWN=conv(spikeON,traceDOWN).*convTraceUP(ST+1);
% plot(getTime(convTraceDOWN,1000),convTraceDOWN)

% convTraceDOWN=conv(spikeOFF,traceDOWN).*convTraceUP(ST+5);
gevi=[convTraceUP(1:ST) convTraceDOWN(ST+1:end)];
gevi=gevi(800:1500);
figure(1)
% subplot(151)
plot(getTime(gevi,fs),gevi)
hold on
% xlim([0.49 0.54])
title('kernel')
%%
freq=10:20:110;
baseline=10;
numOsc=10;
subplot(1,5,[2 5])
for i=1:numel(freq)
    ST=baseline:round(fs/freq(i)):numOsc*round(fs/freq(i))+baseline;
    spike=zeros(size(t));
    spike(ST)=1;
    
    TF=conv(spike,gevi);
    plot(getTime(TF,1000),[deconv(gevi,TF)])
    hold on
end
hold off
% xlim([0.48 1])
title('ASAP4.4')
%%
%interpolate every mV
Vm=-150:50;
dff=interp1(VmRaw,dff_asap44,Vm);
plot(Vm,dff,'o',VmRaw,dff_asap3,'o');
%%

% GEVI feature at 32-35°
% ASAP2s
a1=67;
a2=76;
tau1=1.5;
tau2=7.8;
tau3=3.4;
tau4=13.1;

% ASAP3
a1=72;
a2=76;
tau1=0.94;
tau2=7.24;
tau3=3.79;
tau4=16;

% ASAP4
a1=19;
a2=9;
tau1=2.62/4;
tau2=21.2/4;
tau3=5.69/4;
tau4=24.5/4;

% AcemNeon
a1=61;
a2=90;
tau1=2.2;
tau2=6.4;
tau3=3.8;
tau4=17.5;
%%
paramGEVI.activationFastAmp=a1;
paramGEVI.activationFastTC=tau1;
paramGEVI.activationSlowTC=tau2;

paramGEVI.deactivationFastAmp=a2;
paramGEVI.deactivationFastTC=tau3;
paramGEVI.deactivationSlowTC=tau4;


[geviKernel_ace,options]=getKernelGEFI(paramGEVI,'gateDuration',1);


%%

figure(2)
plot(getTime(geviKernel_asap4,5000)-0.2,100.*[geviKernel_asap2s' geviKernel_asap3' geviKernel_asap4' geviKernel_ace'],'linewidth',2)
title('10-ms Impulse Response of GEVI')
legend('asap2s','asap3','asap4','ace1')
xlim([-0.005 0.025])
xlabel('Time (s)')
ylabel('Effective Response (%)')

%% 
fs=5000;
spike=zeros(1*fs,1);

% how to interpolate on the full sine wave?
fs=5000;
Fosc=10;
t=0:1/fs:1;
inputVm=[zeros(1,1000) sin(2*pi*Fosc*t) zeros(1,1000)];
transFunc=conv(inputVm,geviKernel_ace./max(geviKernel_ace),'same');
plot(getTime(inputVm,fs),[inputVm' transFunc']);

inputVm=rescale(inputVm,-70,-50);
Vy=-70:1:-50;
ty=interp1(inputVm,t,Vy);

for i=1:numel(Vy)
TFdff(i)=dff(Vm==Vy(i));
end
%%
steps=-70+[-80:10:100];
Vm_steps=-70.*ones(1000,numel(steps));
dff_steps=zeros(size(Vm_steps));
dff_step_dyn=zeros(size(Vm_steps));
for i=1:numel(steps)
Vm_steps(250:750,i)=steps(i);
dff_steps(250:750,i)=dff(Vm==steps(i));
% dff_step_dyn(250:750,i)=conv(dff_steps(250:750,i),gevi,'same');
end

% how to interpolate on the full sine wave?
fs=1000;
Fosc=10;
t=-1/Fosc/4+1/fs:1/fs:1/Fosc/4-1/fs;
inputVm=sin(2*pi*Fosc*t);
inputVm=rescale(inputVm,-70,-50);
Vy=-70:1:-50;
ty=interp1(inputVm,t,Vy);

for i=1:numel(Vy)
TFdff(i)=dff(Vm==Vy(i));
end
plot(t,inputVm,'o',ty,[Vy; TFdff],'o')

plot(dff)

[GEVIconv]=convGEVIkernel(dff_steps(:,end),1000,paramGEVI);
figure()
subplot(131)
plot(Vm_steps)
subplot(132)
 plot(dff_steps)
 subplot(133)
 plot(dff_step_dyn)
%% deconvolution of time series of not easy... try MLspikes or ask omer or Fatih?

% uz1=gevi(1:2000)'+eps('single');
% uz2=TF(1000:2999)'+eps('single');
% plot([uz1 uz2])
% %  Regularization parameter, which is 10 percent of the average of the power
% % spectrum of uz2
% epsilon = 0.1; 
% L = numel(uz1);
% % Time vector
% T = [-(L/2+1):1:(L/2-2)];
% % L-point symmetric Hann window in the column vector W
% W = hann(L); 
% % Multiply input signals, uz1 and uz2, with Hann window and take FFT in
% % order to make sure that the ends of signal in frequency domain match up
% % while keeping everything reasonably smooth; this greatly diminish
% % spectral leakage
% uz1f = fft(W.*uz1,L); 
% uz2f = fft(W.*uz2,L);
% % Compute deconvolution
% Stmp = real(ifft((uz1f.*conj(uz2f))./(uz2f.*conj(uz2f)+epsilon*mean(uz2f.*conj(uz2f)))));
% S = [Stmp(L/2:L-1); Stmp(1:L/2)];
% 
% plot([S])





