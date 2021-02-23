% fG='F:\GEVI_Wave\Preprocessed\Anesthesia\m200\20201116\meas04\Sample_d201116_s00-fps83-cG_reg.h5';
fG='F:\GEVI_Wave\Preprocessed\Anesthesia\m200\20201116\meas01\m200_d201116_s01-fps50-cG_reg.h5';
% fG='F:\GEVI_Wave\Preprocessed\Anesthesia\m200\20201116\meas04\Sample_d201116_s00-fps83-cG_reg.h5';
fR=findRefPath(fG);
fps=getFps(fG)/2
mG=h5load(fG);
mR=h5load(fR);

%%
mAce=mG(:,:,11:2:end);
mVarnam=mR(:,:,12:2:end);
mCyOfp=mR(:,:,11:2:end);


%%
[maskedAce,finalMask,summaryMasking]=maskMovie(mAce,mAce);
[maskedVarnam,finalMask,summaryMasking]=maskMovie(mVarnam,mAce);
[maskedCyOfp,finalMask,summaryMasking]=maskMovie(mCyOfp,mAce);

%%

hemoPeak=7.6;
hemoBand=[hemoPeak-0.5,hemoPeak+0.5];
bandsDelta=[0.5,5.5];

bpAce=zscoreMovie(bandpassMovie(maskedAce,bandsDelta,fps,'filterOrder',4));
bpVarnam=zscoreMovie(bandpassMovie(maskedVarnam,bandsDelta,fps,'filterOrder',4));
bpCyOfp=zscoreMovie(bandpassMovie(maskedCyOfp,bandsDelta,fps,'filterOrder',4));

hbAce=zscoreMovie(bandpassMovie(maskedAce,hemoBand,fps,'filterOrder',4));
hbVarnam=zscoreMovie(bandpassMovie(maskedVarnam,hemoBand,fps,'filterOrder',4));
hbCyOfp=zscoreMovie(bandpassMovie(maskedCyOfp,hemoBand,fps,'filterOrder',4));

%%
figure(11)
clf
plotPSD(zscoreMovie(maskedAce),fps)
hold on
plotPSD(zscoreMovie(maskedVarnam),fps)
plotPSD(zscoreMovie(maskedCyOfp),fps)
hold off
legend('Ace-mNeonGreen','Varnam','cyOFP')

%%
exportFig('PSD','F:\GEVI_Wave\Analysis\Anesthesia\m200\20201116\meas01')


%%

play(zscoreMovie(bpVarnam),[],'limits',[-4,4])

%%
plotPSD(bpCyOfp,fps)

%%

%%

figure(10);
clf
ha = tight_subplot(2,2,[.05 .03],[.1 .1],[.01 .01]);


%%

set(gcf,'color','white')
iFrame=100;
% subplot(2,2,1)
axes(ha(1));
imshow(bpFilter2D(flipud(bpAce(:,:,iFrame)'),2,Inf),[-2,2])
colormap(redblue(500))
title('AcemNeonGreen, delta 0.5-4 Hz')

% subplot(2,2,2)
axes(ha(2));
imshow(bpFilter2D(flipud(bpVarnam(:,:,iFrame)'),2,Inf),[-2,2])
colormap(redblue(500))
title('Varnam delta, 0.5-4 Hz')

% subplot(2,2,3)
axes(ha(3));
imshow(bpFilter2D(flipud(hbAce(:,:,iFrame)'),1,Inf),[-2,2])
colormap(redblue(500))
title('Green channel, Heart beat')

% subplot(2,2,4)
axes(ha(4));
imshow(bpFilter2D(flipud(hbVarnam(:,:,iFrame)'),2,Inf),[-2,2])
colormap(redblue(500))
title('Red channel, Heart beat')

% suptitle(sprintf('t=%.3f s',iframe/fps))



%%


%%
outputPath=fileparts(fG);
outputPath=strrep(outputPath,'Preprocessed','Analysis');
mkdirs(outputPath);

outputPath=fullfile(outputPath,'AceVarnam.mp4')


%%


framerate=25;
format='mp4';

 disps('Exporting MP4 movie')
        file_idx=1;
        while isfile([outputPath,sprintf('-%i',file_idx),'.mp4'])
            file_idx=file_idx+1;
        end        
        finalVideoPath=[outputPath,sprintf('-%i',file_idx),'.mp4'];
        videoobj=VideoWriter(finalVideoPath,'MPEG-4');  
% videoobj=VideoWriter(finalVideoPath,'Motio JPEG AVI');  
%         Motion JPEG AVI
       
        videoobj.Quality=100;
videoobj.FrameRate=framerate;


open(videoobj);

fig = figure('units','pixels','position',[200 200 800 800]);
ax=gca;
ax.Position;
ax.Position=[0 0 1 1];
ha = tight_subplot(2,2,[.05 .03],[.1 .1],[.01 .01]);
set(gcf,'color','white')

idx=0;



    
for iFrame=1:1000 %size(bpAce,3)     
    

% subplot(2,2,1)
axes(ha(1));
imshow(bpFilter2D(flipud(bpAce(:,:,iFrame)'),2,Inf),[-2,2])
colormap(redblue(500))
title('AcemNeonGreen, delta 0.5-5.5 Hz')

% subplot(2,2,2)
axes(ha(2));
imshow(bpFilter2D(flipud(bpVarnam(:,:,iFrame)'),2,Inf),[-2,2])
colormap(redblue(500))
title('Varnam delta, 0.5-5.5 Hz')

% subplot(2,2,3)
axes(ha(3));
imshow(bpFilter2D(flipud(hbAce(:,:,iFrame)'),1,Inf),[-2,2])
colormap(redblue(500))
title('Green channel, Heart beat')

% subplot(2,2,4)
axes(ha(4));
imshow(bpFilter2D(flipud(hbVarnam(:,:,iFrame)'),2,Inf),[-2,2])
colormap(redblue(500))
title('Red channel, Heart beat')
    
    imframe=getframe(gcf);
    writeVideo(videoobj,imframe)

    
end

close(videoobj);

%
winopen(fileparts(outputPath))

%%
options=struct; % add your options below 
options.hemoPeak=[0]; % if provided, no hemodynamics detection will occure;
options.preBandpassed=true; % just to avoid additional bandpassing step;
options.heartbeatRange=[]; % for finding the heart beat at the beginning only
options.hemoBand=[]; % band widht around hemodynamics peak in Hz +/-options.hemoBand=/2
options.conditioning=false;
options.highpassCutoff=0.1;

[umxMovieVarnam,coeffMap,hemoPeak,summary]=fastMovUnmix(bpVarnam,bpAce,fps,'options',options);

%%

play(umxMovieVarnam,[],'limits',[-1,1])

%%
trA=pointProjection(bpAce);
trV=pointProjection(bpVarnam);
trVumx=pointProjection(umxMovieVarnam);
clf
plot(trA,trVumx,'.')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %% unmixed varnam

outputPath=fileparts(fG);
outputPath=strrep(outputPath,'Preprocessed','Analysis');
mkdirs(outputPath);

outputPath=fullfile(outputPath,'Ace-VarnamUnmixed')


%%


framerate=25;
format='mp4';

 disps('Exporting MP4 movie')
        file_idx=1;
        while isfile([outputPath,sprintf('-%i',file_idx),'.mp4'])
            file_idx=file_idx+1;
        end        
        finalVideoPath=[outputPath,sprintf('-%i',file_idx),'.mp4'];
        videoobj=VideoWriter(finalVideoPath,'MPEG-4');  
% videoobj=VideoWriter(finalVideoPath,'Motio JPEG AVI');  
%         Motion JPEG AVI
       
        videoobj.Quality=100;
videoobj.FrameRate=framerate;


open(videoobj);

fig = figure('units','pixels','position',[200 200 800 800]);
ax=gca;
ax.Position;
ax.Position=[0 0 1 1];
ha = tight_subplot(1,2,[.05 .03],[.1 .1],[.01 .01]);
set(gcf,'color','white')

idx=0;



    
for iFrame=1:size(bpAce,3)     
    

% subplot(2,2,1)
axes(ha(1));
imshow(bpFilter2D(flipud(bpAce(:,:,iFrame)'),2,Inf),[-2,2])
colormap(redblue(500))
title('AcemNeonGreen, delta 0.5-5.5 Hz')

% subplot(2,2,2)
axes(ha(2));
imshow(bpFilter2D(flipud(umxMovieVarnam(:,:,iFrame)'),2,Inf),[-2,2])
colormap(redblue(500))
title('Varnam delta, 0.5-5.5 Hz')

    
    imframe=getframe(gcf);
    writeVideo(videoobj,imframe)

    
end

close(videoobj);

%
winopen(fileparts(outputPath))
