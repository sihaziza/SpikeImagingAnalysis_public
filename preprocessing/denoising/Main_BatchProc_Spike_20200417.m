
clear all

tiktak0=tic;
AnalysisDirectory='G:\Users\Simon\00_TEMPO2D_AnalysisPackage_v2';
DataDirectory='F:\GEVI_Spike';
SaveDirectory='F:\GEVI_Spike_Analysis';
Experiment='Visual';
MouseList=[81 82];
Date='20200416';

GlobalBin=2;% account for hardware + software binning
FrameWindow=[1 5000; 5001 10000;...
    10001 15000; 15001 20000; ...
    20001 25000; 25001 30000]; % put inf if you want all frames; remove the 5 first seconds
lowFPS=0; % script should have been updated to include this
% Real FPS = [49 195 360]
% Set up mice #
for m=length(MouseList)
    tiktak1=tic;
    
    rootName=fullfile(DataDirectory,...
        Experiment,...
        strcat('m',num2str(MouseList(m))),...
        Date);
    
    cd(rootName)
    
    % Look for measurements
    listing = dir('meas*');
    disp(strcat('Measurement Detected:',num2str(size(listing,1))))
    
    for i=size(listing,1)
        
        for chunk=1:6
            try
            nm=listing(i).name;
            rootNameMeas=fullfile(rootName,nm);
            cd(rootNameMeas);
            
            Fs=502;
            Bin=1;
            Lgth=2304;
            Wdth=400;
            
            % Find G&R DCIMG files
            filename=dir('*.dcimg');
            [grn, red]=filename.name;
            Green_dcimg = fullfile(rootNameMeas,grn);
            Red_dcimg = fullfile(rootNameMeas,red);
            
            % Set up where to save figures
            SaveFigDir=fullfile(SaveDirectory,...
                Experiment,...
                strcat('m',num2str(MouseList(m))),...
                Date,...
                nm,...
                strcat('chunk',num2str(chunk)));
            
            if (~exist(SaveFigDir,'dir'))
                mkdir(SaveFigDir)
            end
            
            cd(SaveFigDir); diary Diary
            
            disp(strcat('%%%%%%%%%%%% MOUSE #',num2str(MouseList(m)),' %%%%%%%%%%%%'))
            
            tic;disp('//////////... METADATA ...\\\\\\\\\\');
            
            %         metadata.VoltageChannel=ChannelGEVI(m);
            metadata.FrameRate=Fs;
            metadata.Frames=[FrameWindow(chunk,1) FrameWindow(chunk,2)]; % remove n first seconds
            [metadata]=sh_getMetaDatav2(Green_dcimg, metadata);
            metadata.Dimension=...
                [Lgth Wdth FrameWindow(chunk,2)-FrameWindow(chunk,1)+1];
            
            if Bin>1
                metadata.BinningHW=Bin;
            else
                metadata.BinningHW=Lgth/metadata.Dimension(1);
            end
            metadata.BinningSW=GlobalBin/metadata.BinningHW;
            
            %Always crop on the last frame; use green channel, almost always
            %the brightest
            [frameG,~]= dcimgmatlab(metadata.EndFrame-1, Green_dcimg); %dcimg count from 0
            frameG=imresize(frameG,1/metadata.BinningSW,'Method','box','Antialiasing',true);
            [~, metadata.ROI] = sh_autoCropImage(frameG,[]);
            metadata.FinalSizeGB=metadata.ROI(3)*metadata.ROI(4)*metadata.TotalFrame*16/8/1024^3;
            imshow(frameG,[])
            cd(SaveFigDir)
            Name=strcat(nm,'_Metadata','.mat');
            save(Name,'metadata');toc;disp(metadata);
            
            % Load & Pre-Process Green Channel
            disp('//////////... LOADING GREEN ...\\\\\\\\\\');tic;[movieG]=sh_LoadDCIMGv3(Green_dcimg,metadata);toc;
            clear mex; clear pack;
            disp('//////////... LOADING RED ...\\\\\\\\\\');tic;[movieR]=sh_LoadDCIMGv3(Red_dcimg,metadata);toc;
            clear mex; clear pack;
            
            fig=figure;
            imshow([movieG(:,:,end) flip(movieR(:,:,end))],[])
            sh_SavePDF(fig,strcat(nm,'_Raw Data Last Frame'));
            
            fig=figure;
            imshowpair(movieG(:,:,end), flip(movieR(:,:,end)))
            sh_SavePDF(fig,strcat(nm,'_Raw Data Last Frame overlay'));
            
            disp('//////////... CONVERTION ...\\\\\\\\\\'); tic; movieG=single(movieG); movieR=single(flip(movieR,1));toc;%need to flip red channel
            %Two channels registration
            %         disp('//////////... REGISTRATION ...\\\\\\\\\\'); tic;[movieG, movieR] = sh_pre_reg_video(movieG, movieR);toc;
            %         fig=figure; imshowpair(movieG(:,:,end),movieR(:,:,end)); sh_SavePDF(fig,strcat(nm,'_Reg Data Last Frame overlay'));
            
            %         d=size(temp);
            %         t1=reshape(temp,d(1)*d(2),d(3));
            %         t2=detrend(t1,2); % operate column-wise, here time
            %         tempdetrend=reshape(t2,d(1),d(2),d(3));
            %         tempdetrendfilt=filters.BandPass2D(tempdetrend,5,15);
            
            Gfilt=filters.BandPass2D(movieG,5,20);
            Rfilt=filters.BandPass2D(movieR,5,20);
            
            fig=figure;
            subplot(1,3,1)
            imshow([Gfilt(:,:,100) Gfilt(:,:,end)],[])
            
            subplot(1,3,2)
            imshow([Rfilt(:,:,100) Rfilt(:,:,end)],[])
            
            subplot(1,3,3)
            imshowpair(Gfilt(100:end-100,:,end),Rfilt(100:end-100,:,1));
            
            sh_SavePDF(fig,strcat(nm,'_Spatially Filtered Fisrt-Last-Last'));toc;
            
            disp('//////////... MOTION CORRECTION ...\\\\\\\\\\'); tic;[movieG,movieR]=Moco2Movies(movieG,movieR);
            fig=figure;imshow([mean(movieG,3) mean(movieR,3)],[]); sh_SavePDF(fig,strcat(nm,'_MoCo Mean Data Raw'));toc;
            
            disp('//////////... MOTION CORRECTION ...\\\\\\\\\\'); tic;[Gfilt,Rfilt]=Moco2Movies(Gfilt,Rfilt);
            fig=figure;imshow([mean(Gfilt,3) mean(Rfilt,3)],[]); sh_SavePDF(fig,strcat(nm,'_MoCo Mean Data Filtered'));toc;
            
            % Save all data in h5
            disp('//////////...SAVING ALL DATA HDF5...\\\\\\\\\\');tic;
            h5create('ProcessedData.h5','/GRN',size(movieG),'Datatype','single');
            h5create('ProcessedData.h5','/RED',size(movieR),'Datatype','single');
            h5create('ProcessedData.h5','/GRNfilt',size(Gfilt),'Datatype','single');
            h5create('ProcessedData.h5','/REDfilt',size(Rfilt),'Datatype','single');
            h5write('ProcessedData.h5', '/GRN', movieG);
            h5write('ProcessedData.h5', '/RED', movieR);
            h5write('ProcessedData.h5', '/GRNfilt', Gfilt); % the best method
            h5write('ProcessedData.h5', '/REDfilt', Rfilt); % in case one need to recompute Volt
            
            thre=50; %background threshold
            P=10;% Minimun area of cells to extract
            [Xg,Yg,TraceG,fig]=analysis_trace(Gfilt,thre,P);
            sh_SavePDF(fig,strcat(nm,'_Spike Trace Spatial Filter_Green'));toc;
            
            thre=50; %background threshold
            P=10;% Minimun area of cells to extract
            [Xr,Yr,TraceR,fig]=analysis_trace(Rfilt,thre,P);
            sh_SavePDF(fig,strcat(nm,'_Spike Trace Spatial Filter_Red'));toc;
            
            SpatialFilterSpikes.GreenCh.SpatialCentroid=[Xg Yg];
            SpatialFilterSpikes.GreenCh.TimeTraces=single(TraceG);
            SpatialFilterSpikes.RedCh.SpatialCentroid=[Xr Yr];
            SpatialFilterSpikes.RedCh.TimeTraces=single(TraceR);
            
            save('SpatialFilterSpikes.mat', 'SpatialFilterSpikes', '-v7.3' )
            
            catch
                disp(strcat('There was a bug here: ','m',num2str(MouseList(m))...
                    ,'_',nm,'_Chunk0',num2str(chunk)));
            end
            %   h5create('ProcessedData.h5','/SpikeTraces',size(SpatialFilterSpikes),'Datatype','single');
            %   h5write('ProcessedData.h5', '/SpikeTraces', SpatialFilterSpikes);
            %
            
            %
            % %         disp('//////////... CONDITIONING ...\\\\\\\\\\'); tic;[movieG,movieR]=sh_DataConditioning(movieG, movieR, Fs);toc;
            % %         fig=figure;imshowpair(movieG(:,:,end),movieR(:,:,end)); sh_SavePDF(fig,strcat(nm,'_Conditioned Data Last Frame overlay'));
            %
            %             SCE=movieG;
            %             REF=movieR;
            %
            %         disp('//////////...UNMIXING in RED - Methods Global RLR...\\\\\\\\\\');
            %         tic; SCEt=sh_PointProjection(SCE); REFt=sh_PointProjection(REF);
            %         pr=robustfit(double(REFt),double(SCEt)); UMX=pr(2); VOLT=SCE-UMX.*REF; toc;
            %
            %         % Save all data in h5
            %         disp('//////////...SAVING ALL DATA HDF5...\\\\\\\\\\');tic;
            %         h5create('ProcessedData.h5','/GRN',size(movieG),'Datatype','single');
            %         h5create('ProcessedData.h5','/RED',size(movieR),'Datatype','single');
            % %         h5create('ProcessedData.h5','/VLT',size(VOLT),'Datatype','single');
            % %         h5create('ProcessedData.h5','/UMX',size(UMX),'Datatype','single');
            %         h5write('ProcessedData.h5', '/GRN', movieG);
            %         h5write('ProcessedData.h5', '/RED', movieR);
            % %         h5write('ProcessedData.h5', '/VLT', VOLT); % the best method
            % %         h5write('ProcessedData.h5', '/UMX', UMX); % in case one need to recompute Volt
            %   toc;
            %
            %         fig=figure;
            %         subplot(1,2,1)
            %         imshow(UMX(:,:,1),[])
            %         title('First Frame')
            %         subplot(1,2,2)
            %         imshow(UMX(:,:,end),[])
            %         title('Last Frame')
            %         sh_SavePDF(fig,strcat(nm,'_Unmixing Matrix'));
            %
            %         Vt=sh_PointProjection(VOLT);
            %
            %         Mx=[SCEt REFt Vt];
            %
            %         Name=strcat(nm,'_TimeTraces','.mat');
            %         save(Name,'Mx')
            %
            %         % Plot power spectrum density to further compare Raw versus Unmixed
            %         win=2*Fs; ovl=1.5*Fs; nfft=10*Fs;
            %         [x,f]=pwelch(Mx,win,ovl,nfft,Fs,'onesided');
            %
            %         fig=figure('defaultAxesFontSize',18); plot(f,10*log10(x),'linewidth',2);
            %         xlim([0.5 Fs/2]);legend('Sce','Ref','RLR_px','EHB_px','RLR_gl','EHB_gl');
            %         sh_SavePDF(fig,strcat(nm,'_Power Spectrum Density'));
            %
            %         sh_TimexCorr(SCEt, REFt,Fs)
            %
            %         sh_TimeTracePlot([SCEt REFt Vt],Fs)
            %
            % %         disp('//////////... SAVE VOLT MOVIE...\\\\\\\\\\');
            % %         tic;sh_MakeMovie(VOLT3,strcat(nm,'_Retinotopy_VOLT_EHB_gl'),Fs/2);toc;
            % %         fig=figure; imshow(std(VOLT3,[],3),[]); sh_SavePDF(fig,strcat(nm,'_Stdev Projection VOLT'));
            % %
            % %         disp('//////////... POWER MAP...\\\\\\\\\\');
            % %         tic;sh_PowerMap(VOLT3,[1 inf],Fs);toc;
        end
        disp(strcat('//////////... TOTAL TIME Measurement #',num2str(nm),'...\\\\\\\\\\'));
        toc(tiktak1);
        diary off
    end
    disp(strcat('//////////... TOTAL TIME Mouse #',num2str(MouseList(m)),'...\\\\\\\\\\'));
    toc(tiktak1);
    
end
disp('//////////... TOTAL TIME ...\\\\\\\\\\');
toc(tiktak0);

%
% %% denoising
% % to be integrated into the MicroscopeRecording package
% addpath(genpath('./'));
% options.windowsize = 5000;
% obj.movie = denoising(obj.movie, options);
%
% %% once again motion correction
% obj.moco
%
% %% save files
%
% obj.folderpath = fullfile(obj.folderpath,'denoised');
% if ~isfolder(obj.folderpath)
%     mkdir(obj.folderpath);
% end
% obj.convert;
%
%
% %% trace analysis
% thre=550; %background threshold
% P=30;% Minimun area of cells to extract
% [L,X,Y,N]=analysis_trace(obj.movie,thre,P);