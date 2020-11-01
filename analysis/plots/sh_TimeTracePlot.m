function sh_TimeTracePlot(Mx,Fs)

Mx=sh_Standardize(Mx);
name={'Green','Red','Voltage'};

fig=figure('defaultAxesFontSize',18);
tps=0:1/Fs:(size(Mx,1)-1)/Fs;
subplot(4,1,1)
plot(tps(1:60*Fs),Mx(1:60*Fs,1:2))
legend(name(1:2))
subplot(4,1,2)
plot(tps(1:2*Fs),Mx(1:2*Fs,3),'k')
legend(name(3))

last=floor(length(tps)/Fs)*Fs;
start=last-60*Fs+1;
subplot(4,1,3)
plot(tps(start:last),Mx(start:last,1:2))
% legend(name(1:2))
xlim([start last]./Fs)
subplot(4,1,4)
plot(tps(start:last),Mx(start:last,3),'k')
% legend(name(3))
xlim([start last]./Fs)

% sh_SavePDF(fig,'Time Traces')
