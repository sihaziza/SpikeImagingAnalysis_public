function sh_TimexCorr(G_t,R_t,Fs)

step=1;
nstep=length(G_t)/(step*Fs);
for i=1:nstep
[r(:,i),lags] =xcorr(G_t(1+step*(i-1)*Fs:step*i*Fs),R_t(1+step*(i-1)*Fs:step*i*Fs),2*Fs,'coeff');
end

time=(1:nstep)';

fig=figure('defaultAxesFontSize',18);         
imagesc(time,lags/Fs,r)
ylim([-1 1])
colorbar
caxis([-1 1])
xlabel('Time (s)')
ylabel('Lag (s)')        
sh_SavePDF(fig,'Temporal xCorr');

end