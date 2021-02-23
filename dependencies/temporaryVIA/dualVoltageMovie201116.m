fpathG='D:\GEVI_Wave\Raw\Anesthesia\m200\20201116\meas00\m200_d201116_s00-fps83-cG.dcimg';
fpathR='E:\GEVI_Wave\Raw\Anesthesia\m200\20201116\meas00\m200_d201116_s00-fps83-cR.dcimg';

%%

[h5files,summary]=loading(fpathG);

%%

movGh5=h5load(h5files{1});
movRh5=h5load(h5files{2});

%%

subplot(2,2,1)
imshow(movGh5.mov(:,:,1),[])
colorbar
subplot(2,2,2)
imshow(movGh5.mov(:,:,2),[])
colorbar


subplot(2,2,3)
imshow(movRh5.mov(:,:,1),[])
colorbar
subplot(2,2,4)
imshow(movRh5.mov(:,:,2),[])
colorbar

%%
movAce=movGh5.mov(:,:,1:2:end);
movVarnam=movRh5.mov(:,:,2:2:end);
movRef=movRh5.mov(:,:,1:2:end);

%%
play(movAce)

%%
fps=movGh5.fps/2;

%%

plotMovie(movRef,fps)

%%

zAce=zscoreMovie(movAce);
zVarnam=zscoreMovie(movVarnam);
zReference=zscoreMovie(movRef);
%%
play(zAce)
%%
play(zVarnam)

%%
play(zReference)

%%
% fG='F:\GEVI_Wave\Preprocessed\Anesthesia\m200\20201116\meas04\Sample_d201116_s00-fps83-cG_reg.h5';
% fG='F:\GEVI_Wave\Preprocessed\Anesthesia\m200\20201116\meas01\m200_d201116_s01-fps50-cG_reg.h5';
fG='F:\GEVI_Wave\Preprocessed\Anesthesia\m200\20201116\meas04\Sample_d201116_s00-fps83-cG_reg.h5';
fR=findRefPath(fG);
fps=getFps(fG)/2
mG=h5load(fG);
mR=h5load(fR);

%%
mAce=mG(:,:,11:2:end);
mVarnam=mR(:,:,12:2:end);
mCyOfp=mR(:,:,11:2:end);

%%
clf
plot(pointProjection(mG))

hold on
plot(pointProjection(mR))
xlim([0,50])
hold off

%%
play(mAce)

%%


%%
[mAceCropped,mCyOfpCropped]=cropMoviesUI(mAce,mCyOfp);
% [mAceCropped,mVarnamCropped]=cropMoviesUI(mAce,mVarnam);




%%
clf
traceAce=squeeze(mean(mAceCropped,[1,2]));
% plot(dff(traceVar))
traceRef=squeeze(mean(mCyOfpCropped,[1,2]));
traceVar=squeeze(mean(mVarnamCropped,[1,2]));
hold on
plot(dff(traceAce))
plot(dff(traceRef))
hold off
legend('Ace','Reference')
%%
myfft(traceVar(1:end),fps)

%%

clf
plot(traceRef,traceAce,'.')



%%
% plotPSD(traceRef,fps)
plotPSD(traceRef,fps)

%%
myfft(traceRef,fps)


%%
waveletTimeFreq(traceAce,fps);

%%
[maskedAce,finalMask,summaryMasking]=maskMovie(mAce,mAce);
[maskedVarnam,finalMask,summaryMasking]=maskMovie(mVarnam,mAce);
[maskedCyOfp,finalMask,summaryMasking]=maskMovie(mCyOfp,mAce);

%%
play(maskedAce)

%%
traceAce=squeeze(mean(maskedAce,[1,2]));
plot(dff(traceAce))
traceRef=squeeze(mean(maskedCyOfp,[1,2]));
traceVarnam=squeeze(mean(maskedVarnam,[1,2]));

%%
plotPSD(zscore([traceAce,traceVarnam,traceRef]),fps)

%%
clf
subplot(2,1,1)
pr=@(x) (bandpass((x),[1.5,2.5],fps));
plot(pr(traceRef),pr(traceAce),'.')
p=robustfit(pr(traceRef),pr(traceAce));
title(corr(pr(traceRef),pr(traceAce)))
xlabel('cyOfp')
ylabel('Ace (\sigma)')
subplot(2,1,2)
plot(pr(traceRef),'-')
hold on
plot(pr(traceAce),'-')
hold off
legend('cyOfp','Ace')

%%
clf

plot(pr(traceAce)-pr(traceRef)*p(2))
hold on
plot(pr(traceAce))
hold off


%%
clf
subplot(2,1,1)
pr=@(x) zscore(bandpass(x,[1.8,2.2],fps));
plot(pr(traceRef),pr(traceVarnam),'.')
title(corr(pr(traceRef),pr(traceVarnam)))
xlabel('cyOfp')
ylabel('traceVarnam (\sigma)')
subplot(2,1,2)
plot(pr(traceRef),'-')
hold on
plot(pr(traceVarnam),'-')
hold off
legend('cyOfp','traceVarnam')

% plotPSD(pr(traceAce),fps)


%%
% mAce=mG(:,:,11:2:end);
% mVarnam=mR(:,:,12:2:end);
% mCyOfp


%%

bpAce=bandpassMovie(maskedAce,[0.01,20],fps);
bpVarnam=bandpassMovie(maskedVarnam,[0.01,20],fps);
bpCyOfp=bandpassMovie(maskedCyOfp,[0.01,20],fps);
%%
plotMovie(bpAce,fps)

%%

play(bpVarnam)

%%
plotPSD(bpVarnam,fps);

%%
[unmixSource,unmixCoeff,options]=unmixing(bpAce,bpCyOfp,'fps',fps,'mouseState','anesthesia');

%%

bands=[5,8];
V1=bandpassMovie(bpAce,bands,fps);
V2=bandpassMovie(bpVarnam,bands,fps);
R=bandpassMovie(bpCyOfp,bands,fps);

%%
play(V2,R,'limits',[-5,5])

%%
% R=bpCyOfp;
V=V2;

for ii=1:size(V,1)
    
    ii/size(V,1)
    parfor jj=1:size(R,2)
        Iv=squeeze(V(ii,jj,:));
        Ir=squeeze(R(ii,jj,:));
        if (sum(Iv)==0) || (sum(Ir)==0)
            coeffmap(ii,jj)=0;            
        else           
%             try
                p=robustfit(Ir,Iv);
                coeffmap(ii,jj)=p(2);
%             catch ME
%                 fprintf('%d %d failed robust reg\n',ii,jj);
%             end
        end        
    end
end

%%
ii=94;
jj=95;
Iv=squeeze(bpAce(ii,jj,:));
Ir=squeeze(bpCyOfp(ii,jj,:));
p=robustfit(Ir,Iv);

subplot(2,1,1)
plot(Ir,Iv,'.')
subplot(2,1,2)
plot(Ir,Iv-p(2)*Ir,'.')

%%
clf
plot(Iv)
hold on
plot

%%
% coeffmap1=coeffmap;
%%
% coeffmap2=coeffmap;
%%
imshow(coeffmap,[])

%%
play(zscoreMovie(bpVarnam),[],'limits',[-4,4])

%%
plotPSD(bpAce,fps)

%%
unmxAce=bpAce-coeffmap1.*bpCyOfp;

%%
unmxVarnam=bpVarnam-coeffmap2.*bpCyOfp;

%%
unmxHemo=bpCyOfp+coeffmap1.*bpAce;

%%
play(zscoreMovie(unmxVarnam),[],'limits',[-4,4])

%%
plotPSD(bpVarnam,fps)
hold on
plotPSD(unmxVarnam,fps)
hold off

%%
plotPSD(bpAce,fps)
hold on
plotPSD(unmxAce,fps)
hold off

%%
clf
plotMovie(bpAce,fps)
hold on
plotMovie(unmxAce,fps)
hold off


%%

AceUmxBp2=bandpassMovie(unmxAce,[0.1,4],fps);

%%

VarnamUmxBp2=bandpassMovie(unmxVarnam,[0.1,4],fps);

%%
play(zscoreMovie(AceUmxBp2),[],'limits',[-4,4])
%%
play(zscoreMovie(VarnamUmxBp2),[],'limits',[-4,4])

%%
play(flipud(zscoreMovie(permute(AceUmxBp2,[2,1,3]))),flipud(zscoreMovie(permute(VarnamUmxBp2,[2,1,3]))),'limits',[-4,4])

%%
% plot(pointProjection(bpCyOfp),pointProjection(unmxAce),'.')
% plot(pointProjection(bpCyOfp),pointProjection(bpVarnam),'.')
plot(pointProjection(bpCyOfp),pointProjection(unmxVarnam),'.')
% plot(pointProjection(bpCyOfp),pointProjection(bpAce),'.')

%%
disps('Preparing the movie')
global keyIn
keyIn = 0;
clf
set(gcf,'WindowKeyPressFcn',@KeyPressFcn);
mvproc=@(mv) zscoreMovie(bandpassMovie(mv,[0.1,7],fps));
% movie1=mvproc(bpAce);
% movie2=mvproc(bpVarnam);
% movie3=mvproc(bpCyOfp);
movie1=mvproc(unmxAce);
movie2=mvproc(unmxVarnam);
% unmxHemo
movie3=mvproc(unmxHemo);
disps('Starting the display')
for iframe=1:size(unmxAce,3)
    iframe
    imshow(horzcat(movie1(:,:,iframe),movie2(:,:,iframe),movie3(:,:,iframe)),[-4,4]);
%     imshow(horzcat(imresize(movie1(:,:,iframe),0.5),imresize(movie2(:,:,iframe),0.5)),[-4,4]);
    colorbar
    colormap(redblue(500));
    drawnow;
    if strcmpi(keyIn,'e')
        disps('Terminated display')
        break;
    end
end

%%
clf; plotPSD((fs3.LED1(2:2:end)),100); hold on; plotPSD((fs4.LED1(2:2:end)),100);

%%
clf
fsPulse=importFrameStamps('D:\Calibration\Raw\Noise\Sample\20201117\meas02\Sample_d201117_s02DualColorPulsking2msPulse-fps100-cG_framestamps 0.txt');
fsGlobalExp=importFrameStamps('D:\Calibration\Raw\Noise\Sample\20201117\meas03\Sample_d201117_s03DualColorPulskingGlobalExp-fps100-cG_framestamps 0.txt');
plot(zscore(fsPulse.LED1(12:2:2000)))
hold on
plot(zscore(fsGlobalExp.LED1(12:2:2000)))
hold off
legend('Pulse','GlobalExp')

%%
clf
fsPulse=importFrameStamps('D:\Calibration\Raw\Noise\Sample\20201117\meas02\Sample_d201117_s02DualColorPulsking2msPulse-fps100-cG_framestamps 0.txt');
fsGlobalExp=importFrameStamps('D:\Calibration\Raw\Noise\Sample\20201117\meas03\Sample_d201117_s03DualColorPulskingGlobalExp-fps100-cG_framestamps 0.txt');
plotPSD(zscore(fsPulse.LED1(12:2:2500)),100)
hold on
plotPSD(zscore(fsGlobalExp.LED1(12:2:2500)),100)
hold off
legend('Pulse','GlobalExp')

%%

function KeyPressFcn(~,event)
global keyIn
keyIn = event.Key;
% drawnow
disp(keyIn)
end


