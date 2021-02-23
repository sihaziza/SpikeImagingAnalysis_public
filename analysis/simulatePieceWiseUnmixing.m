
% Simulate
t=0:1/Fs:23389/Fs;
signal=sin(2*pi*t*10)+1*randn(1,length(t));
reference=2*sin(2*pi*t*10)+0.1*randn(1,length(t));
% plot(signal, reference)

win=[0.5 1 2];
for iWin=1:length(win)
[output]=pieceWiseUnmixing( reference,signal, Fs, 'umxMethod','pca','window',win(iWin));
a_pca(iWin,:)=output.coefficient;

[output]=pieceWiseUnmixing(reference,signal,  Fs, 'umxMethod','rlr','window',win(iWin));
a_rlr(iWin,:)=output.coefficient;

[output]=pieceWiseUnmixing(reference,signal,  Fs, 'umxMethod','linear','window',win(iWin));
a_lin(iWin,:)=output.coefficient;

end
%%
Apca=mean(a_pca,1);
Arlr=mean(a_rlr,1);
Alin=mean(a_lin,1);
mean([Alin; Arlr; Apca]')
% for now, only work with vectors for both inputs
% first scale is always correspond to 4 slices.
% alternatively, use 1sec window with overlap (from 0% to 90% ovlp)
% Output strucutre:
%   output.residual
%   output.coefficient


figure('defaultaxesfontsize',16,'color','w') 
subplot(2,1,1)
plot(time,[signal' reference']+[1 -1])
legend('signal','reference')
subplot(2,1,2)
plot(time,[Alin; Arlr; Apca]','linewidth',2)
legend('Linear','robustLR','PCA')
% xlim([])
xlabel(['Time (s)'])