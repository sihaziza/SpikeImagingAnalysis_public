filePath='F:\GEVI_Wave\Preprocessed\Anesthesia\m200\20201116\meas04\Sample_d201116_s00-fps83-cG_reg.h5';
filePathR=findRefPath(filePath);
[movieG,fps,stimulus,exportFolder,summary]=load4Analysis(filePath);
[movieR]=load4Analysis(filePathR);
fps=fps/2

%%
[voltG,voltR,reference,summary]=dualGeviMovies(movieG,movieR,'colorScaling',[1,1,1]);


[voltGmasked,finalMask,summaryMasking]=maskMovie(voltG,voltG);
[voltR,finalMask,summaryMasking]=maskMovie(voltR,voltG);
[reference,finalMask,summaryMasking]=maskMovie(reference,voltG);
voltG=voltGmasked;
%%

[umxMovie,coeffMap,hemoPeak,summary]=fastMovUnmix(voltG,reference,fps);

%%

imagesc(coeffMap)
colorbar

%%
clf
traceAce=pointProjection(voltG);
traceAceUmx=pointProjection(umxMovie);
plotPSD(zscore(traceAce),fps);
hold on
plotPSD(zscore(traceAceUmx),fps);
hold off
legend('Before unmixing','After unmixing')


%%
plotPSD(voltG,fps)
hold on
plotPSD(umxMovie,fps)
hold off
