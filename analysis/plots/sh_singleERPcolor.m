%
% Same as sh_layoutLayoutPowerAB but also include the non-oddball trace to 
% compare with oddball (e.g. A baseline + B oddball + B baseline)
%
% sh_singleERPcolor(array,epoch,cRange,Fs)
%
% Frg: frequency range to compute the band power
% step: time length to compute the bandpower
% 
%

% global ChLayout
% global nBL
% global nOB

function sh_singleERPcolor(array,epoch,cRange,Fs)

n=size(array,2);

time=(epoch(1):1/Fs:epoch(2)-1/Fs)';

pcolor(time,0:n,[array zeros(size(array,1),1)]')
shading 'flat'
% caxis('auto')
caxis(cRange)
c=colorbar('Location','southoutside');
colormap(jet)
xlabel('Time (s)')
xlim(epoch)
c.Label.String = 'SD norm.';
hold on
plot([0 0],[0 n],'--k','LineWidth',1)
hold off

end