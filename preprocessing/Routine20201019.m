
tic;
%% Routine 20200715 >  Test with all defaults
k=1;
for iMeas=10:14
    try
        meas=strcat('meas',num2str(iMeas));
        h5Path=fullfile('F:\GEVI_Spike\Raw\Visual8Angles\m78\20201012',meas);
        fileName=dir(fullfile(h5Path, '*.dcimg')); % G always comes before R
        
        [fileNameG, fileNameR]=fileName.name; % for saving other outputs
        
        options.dcimgPathG=fullfile(h5Path,fileNameG);
        options.dcimgPathR=fullfile(h5Path,fileNameR);
        
        
        % %%
        % filenameG='spike-ace-varnam-trigstart-fov2-1000Hz--BL100-fps401-cG.dcimg';
        % % dcimgPath='P:\GEVI_Spike\Raw\Visual8Angles\m78\20201012\meas01';
        % % filenameG='m78_d201012_s01_--fps500-cG.dcimg';
        % filepathG=fullfile(dcimgPath,meas,filenameG);
        % filepathR = strrep(filepathG,'cG','cR');
        % % filepathR = strrep(filepathR,'D:\','E:\');
        frame=1;
        [movieG,~,~]=loadDCIMG(options.dcimgPathG,[frame, frame]);
        [movieR,~,~]=loadDCIMG(options.dcimgPathR,[frame, frame]);
        
        figure()
        subplot(121)
        imshow(movieG,[])
        subplot(122)
        imshow(fliplr(movieR),[])
        
        fprintf('Green max %2.0f | Red max %2.0f \n', max(movieG(:)), max(movieR(:)));
        
        %
        filepathTTL = strrep(options.dcimgPathG,'.dcimg','_framestamps 0.txt');
        [TTL]=importdata(filepathTTL);
        loco=TTL.data(:,2);
        stim=TTL.data(:,4);
        fluctuationLED=TTL.data(:,5:6);
        plot(zscore([loco stim]))
        % plot(zscore(fluctuationLED))
        
        temp=diff(stim);
        plot(temp)
        frame0=find(diff(stim)==1,1,'first');
        frameX=find(diff(stim)==-1,1,'last');
        baseline=0.5; %in sec
        fps=500; % in Hz
        
        frameRange=[frame0-baseline*fps frameX+baseline*fps-1];
        temp=stim(frameRange(1):frameRange(2));plot(temp,'o')
        
        
        % %% SET EXPORT PATH (define all necessary pointers)
        [allPaths]=setExportPath(h5Path); % create all path for canonical steps
        
        % %% GET METADATA
        [metadata]=getRawMetaData(allPaths,...
            'savePath',allPaths.pathDiagLoading,...
            'softwareBinning',1,...
            'autoCropping',false);
        
        % does not work for old recording ORCA flash
        
        % %% LOADING
        % frameRange=[frame inf];
        [summaryLoading] = loading(allPaths,...
            'frameRange',frameRange,...
            'cropROI',metadata.ROI,...
            'binning',metadata.softwareBinning);
        
        toc;
    catch
        disp('oups, this one failed...')
        fail(k)=iMeas;k=k+1;
    end
    
end

%% Batch Process Visual 81 & 82 filter movie in chunks
mainFolder='B:\GEVI_Spike\Raw\Visual8Angles';%'P:\GEVI_Spike\Raw\Visual'
mouse={'m81' 'm82'};

% date='20200416';
for iMouse=1:length(mouse)
    dcimgPath=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(dcimgPath,'2020*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(dcimgPath,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
        for iFolder=1:length(folderName)
            h5Path=fullfile(dcimgPath,date,folderName{iFolder});
            fileName=dir(fullfile(h5Path, '*.dcimg')); % G always comes before R
            
            [fileNameG, fileNameR]=fileName.name; % for saving other outputs
            
            options.dcimgPathG=fullfile(h5Path,fileNameG);
            options.dcimgPathR=fullfile(h5Path,fileNameR);
            
            % SET EXPORT PATH (define all necessary pointers)
            [allPaths]=setExportPath(h5Path); % create all path for canonical steps
            
            try
                % GET METADATA
                [metadata]=getRawMetaData(allPaths,...
                    'savePath',allPaths.pathDiagLoading,...
                    'softwareBinning',1,...
                    'autoCropping',true);
                
                
                % does not work for old recording ORCA flash
                frame=1;
                [movieG,~,~]=loadDCIMG(options.dcimgPathG,[frame, frame+100]);
                [movieR,~,~]=loadDCIMG(options.dcimgPathR,[frame, frame+100]);
                
                h=figure('defaultaxesfontsize',16,'color','w');
                subplot(211)
                imshow(bpFilter2D(mean(movieG,3),35,2),[])
                title('Green Channel - avg & 2dFilter')
                subplot(212)
                imshow(bpFilter2D(fliplr(mean(movieR,3)),35,2),[])
                title('Red Channel - avg & 2dFilter')
                export_figure(h,'Average-2D Filter Movie - 100 frames',allPaths.pathDiagLoading);%close;
                
                fprintf('Green max %2.0f | Red max %2.0f \n', max(movieG(:)), max(movieR(:)));
                metrics.maxPixelG=max(movieG(:));
                metrics.maxPixelR=max(movieR(:));
                
                save(fullfile(allPaths.pathDiagLoading,'metrics.mat'),'metrics');                      
                
                % %% LOADING
                % frameRange=[frame inf];
%                 [summaryLoading] = loading(allPaths,...
%                     'frameRange',[100 inf],...
%                     'cropROI',metadata.ROI,...
%                     'binning',metadata.softwareBinning);
                
                toc; fail(iMouse,iFolder)=0;
            catch
                disp('oups, this one failed...')
                fail(iMouse,iFolder)=1;
            end
        end
    end
end

%%
mainFolder='F:\GEVI_Spike\Preprocessed\Visual8Angles';%'P:\GEVI_Spike\Raw\Visual'
mouse={'m81'};

% date='20200416';
for iMouse=1:length(mouse)
    h5PathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(h5PathMain,'2020*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(h5PathMain,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
%         
%         fileName=dir(fullfile(fullfile(h5PathMain,date,folderName{1}), '*_crop.h5')); % G always comes before R
%         [fileNameG]=fileName.name; % for saving other outputs,
%         
%         h5PathG=fullfile(fileName(1).folder,fileNameG);
%         
%         [high,low]=findBestFilterParameters(h5PathG);
%         bpFilter=[low high];
        
        tic;
        k=1;
        fail=[];
        for iFolder=1:length(folderName)
            try
                h5Path=fullfile(h5PathMain,date,folderName{iFolder});
%                 fileName=dir(fullfile(h5Path, '*.h5')); % G always comes before R
                
%                 [fileNameG, fileNameR]=fileName.name; % for saving other
                
%                 h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual8Angles\m78\20201012',folderName{iFolder});
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 fileName=dir(fullfile(h5Path, '*.h5')); % G always comes before R
%                 [fileNameG, fileNameR]=fileName.name; % for saving other outputs
%                 
%                 h5PathG=fullfile(h5Path,fileNameG);
%                 h5PathR=fullfile(h5Path,fileNameR);
%                 
%                 testPath.h5PathG=h5PathG;
%                 testPath.h5PathR=h5PathR;
% 
%                 [h5cropIndex,imcropRect]=h5movieCropping(testPath,'processWholeMovie',true);
%                 
%                 disp('End crop movie');toc;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                fileName=dir(fullfile(h5Path, '*_crop.h5')); % G always comes before R
                [fileNameG, fileNameR]=fileName.name; % for saving other outputs
                
                h5PathG=fullfile(h5Path,fileNameG);
                h5PathR=fullfile(h5Path,fileNameR);
                
                bandPassMovieChunk(h5PathG,bpFilter)
                bandPassMovieChunk(h5PathR,bpFilter)
                
                disp('End bandpass movie');toc;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                fileName=dir(fullfile(h5Path, '*_bp.h5')); % G always comes before R
                [fileNameG, fileNameR]=fileName.name; % for saving other outputs

                h5PathG=fullfile(h5Path,fileNameG);
                h5PathR=fullfile(h5Path,fileNameR);
                
                motionCorr1Movie(h5PathG,'templateLastFrame',false);
                motionCorr1Movie(h5PathR,'templateLastFrame',false);
                
                disp('End Moco movie');toc;
%                 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 % fileName=dir(fullfile(h5Path, '*_moco.h5')); % G always comes before R
%                 % [fileNameG, fileNameR]=fileName.name; % for saving other outputs
%                 %
%                 % h5PathG=fullfile(h5Path,fileNameG);
%                 % h5PathR=fullfile(h5Path,fileNameR);
%                 %
%                 % denoisingSpatialChunk(h5PathG);
%                 % denoisingSpatialChunk(h5PathR);
%                 
%                 disp('End Denoising movie');toc;
            catch
                disp('oups, this one failed...')
                fail(k)=iFolder;k=k+1;
            end
            
        end
    end
end
        disp('failed measurements')
        fail
        toc;
        %%
        
        %     try
        %         filepathTTL = strrep(options.dcimgPathG,'.dcimg','_framestamps 0.txt');
        %         [TTL]=importdata(filepathTTL);
        %         if isstruct(TTL)
        %            loco=TTL.data(:,2);
        %         stim=TTL.data(:,4);
        %         fluctuationLED=TTL.data(:,5:6);
        %         else
        %                        loco=TTL(:,2);
        %         stim=TTL(:,4);
        %         fluctuationLED=TTL(:,5:6);
        %         end
        %         plot(zscore([loco stim]))
        %         % plot(zscore(fluctuationLED))
        %
        %         temp=diff(stim);
        %         plot(temp)
        %         frame0=find(diff(stim)==1,1,'first');
        %         frameX=find(diff(stim)==-1,1,'last');
        %         baseline=0.5; %in sec
        %         fps=500; % in Hz
        %
        %         frameRange=[frame0-baseline*fps frameX+baseline*fps-1];
        %         temp=stim(frameRange(1):frameRange(2));plot(temp,'o')
        %
        
        
        
        
        
        
        
        
