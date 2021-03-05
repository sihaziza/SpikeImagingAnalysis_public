%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% DUPLEX Paper - Spike Imaging Analysis Pipeline %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script runs a demo raw file (.dcimg; proprietary format) and proeed
% with the following steps:
%   > gather metadata and create all diagnostic paths. (see metadata
%   > loading .dcimg file based off the metadata file and save as .h5
%   > motion correction (based off NoRMcorr - github package)
%   > demixing (based off PCA/ICA - Mukamel, Neuron 2009)
% At the end, a .mat file is saved with the spatiotemporal filters for each
% detected neurons.

% Follow the workspace prompt as user input will be required... ;-)

%% INPUT PATH TO .dcimg FILE

mainFolder='B:\GEVI_Spike\Raw\Spontaneous';
mouse={'m912' 'm913' 'm915'};% 'm913' 'm915'

% date='20200416';
for iMouse=1:length(mouse)
    dcimgPathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(dcimgPathMain,'2021*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(dcimgPathMain,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
        for iFolder=1:length(folderName)
            try
                dcimgPath=fullfile(dcimgPathMain,date,folderName{iFolder});
                
                % GENERATING ALL PATH
                [allPaths]=setExportPath(dcimgPath);
                
                % GENERATING ALL METADATA
                [metadata]=getRawMetaData(allPaths,...
                    'frameRange',[1 inf],...
                    'softwareBinning',2,...
                    'findBestFilter',false,...
                    'croppingMethod','auto',...
                    'loadTTL',true);%
            end
        end
    end
end

%% LOAD AND CONVERT .dcimg RAW MOVIE

% [disp,speed]=getMouseSpeed(metadata.Locomotion,metadata.fps);
% hold on
% plot(getTime(test,Fs),zscore(sh_bpFilter(test,[6 7],601)),'k')
% plot(getTime(test,Fs),zscore(sh_bpFilter(test,[8.5 10],601)),'k')
% hold off

plotPSD(sh_bpFilter(test,[0.1 100],601),'FrameRate',601,'FreqBand',[1 100],'VerboseFigure',true,'Window',2);

mainFolder='F:\GEVI_Spike\Preprocessed\Spontaneous';
mouse={'m912'};% 'm913' 'm915'
% fail=[];
date='20210222';
for iMouse=1:length(mouse)
    metaPathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    %     folderDate=dir(fullfile(metaPathMain,'2021*')); % G always comes before R
    %
    %     for iDate=1:length(folderDate)
    %         date=folderDate(iDate).name;
    folder=dir(fullfile(metaPathMain,date,'meas*')); % G always comes before R
    
    folderName=[];k=1;
    for iFolder=1:length(folder)
        if strlength(folder(iFolder).name)==6
            folderName{k}=folder(iFolder).name;
            k=k+1;
        end
    end
    
    for iFolder=1:length(folderName)
        metaPath=fullfile(metaPathMain,date,folderName{iFolder});
        temp=load(fullfile(metaPath,'metadata.mat'));
        metadata=temp.metadata; clear temp;
        
        % LOAD and CONVERT the .dcimg data
        loading(metadata.allPaths);
        
        %             Fs=601;
        %             data=h5read(path,'/mov');
        %             dim=size(data);
        %             temp=imresize3(data,[dim(1)/3 dim(2)/3 dim(3)],'box');
        % %             [datafilt]=movieTimeFiltering(temp, [1 100],601);
        %             movie_dns = denoisingStep(single(temp), 10, 'DnCNN');
        % % temp=normalize(temp,3,'zscore','robust');
        % % dim=size(movie_dns);
        % %             movie_dns=imresize3(movie_dns,[dim(1)/4 dim(2)/4 dim(3)],'box');
        % implay(mat2gray(movie_dns))
        %
        % dim=size(movie_dns);
        % vect=reshape(movie_dns,dim(1)*dim(2),dim(3));
        %
        %             parfor i=1:dim(1)*dim(2)
        %             [frequency,pow(i,:),~]=plotPSD(sh_bpFilter(vect(i,:),[0.1 300],601),'FrameRate',601,'FreqBand',[1 100],'VerboseFigure',false,'Window',2);
        %             end
        %             powavg=mean(pow,1);
        %             plot(frequency,powavg)
        %
        %            trace=getPointProjection(movie_dns);
        %            trace=sh_bpFilter(trace,[0.5 4],601);
        %            [upper]=envelope(trace,1*Fs);
        %
        %            [disp,speed]=getMouseSpeed(metadata.Locomotion,Fs);
        %            hold on
        %            plot(getTime(trace,601),20*zscore(upper),'k')
        %            hold off
        %            plotPSD(sh_bpFilter(trace,[0.5 300],601),'FrameRate',601,'FreqBand',[1 100],'VerboseFigure',true,'Window',2);
        
        % MOCO
        try
            path=metadata.allPaths.h5PathG;
            bpAssistMoco(path);
            path=metadata.allPaths.h5PathR;
            bpAssistMoco(path);
        catch ME
            errorDiary(1,iFolder)=ME;
        end
        
        % Detrending
        try
            path=strrep(metadata.allPaths.h5PathG, '.h5','_bp_moco.h5');
            detrending(path,'samplingRate',metadata.fps,'lpCutOff',1);
            path=strrep(metadata.allPaths.h5PathR, '.h5','_bp_moco.h5');
            detrending(path,'samplingRate',metadata.fps,'lpCutOff',1);
        catch ME
            errorDiary(2,iFolder)=ME;
        end
        
        % Denoising
        try
            path=strrep(metadata.allPaths.h5PathG, '.h5','_bp_moco_dtr.h5');
            denoising1Movie(path,'ranks',10,'windowSize',5*metadata.fps);
            denoising1Movie(path,'ranks',25,'windowSize',5*metadata.fps);
            denoising1Movie(path,'ranks',100,'windowSize',5*metadata.fps);
            path=strrep(metadata.allPaths.h5PathR, '.h5','_bp_moco_dtr.h5');
            denoising1Movie(path,'ranks',10,'windowSize',5*metadata.fps);
            denoising1Movie(path,'ranks',25,'windowSize',5*metadata.fps);
            denoising1Movie(path,'ranks',100,'windowSize',5*metadata.fps);
            
        catch ME
            errorDiary(3,iFolder)=ME;
        end
        
        %             movie=h5read(pathG,'/mov',[1 1 1],[300 600 10000]);
        %
        %             movie=imresize3(movie,[300/2 600/2 10000],'box');
        %
        %             implay(mat2gray(movie))
        % DEMIX THE MOVIE TO FIND SINGLE NEURONS - same on denoised movie
        %             try
        %                 pathG=strrep(metadata.allPaths.h5PathG, '.h5','_dns.h5');
        %                 runPCAICA(pathG,metadata.fps)
        %                 runEXTRACT(pathG,'polarityGEVI','dual');
        %                 runNMF(pathG,'polarityGEVI','dual');
        %             catch ME
        %                 errorDiary(5,iFolder)=ME;
        %             end
    end
    %         errorDiary
    %     end
end

%% ANALYZE MOVIES (DEMIXING UNITS)

mainFolder='F:\GEVI_Spike\Preprocessed\Spontaneous';
mouse={'m915'};% 'm913'
% fail=[];
date='20210221';
for iMouse=1:length(mouse)
    metaPathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    %     folderDate=dir(fullfile(metaPathMain,'2021*')); % G always comes before R
    %
    %     for iDate=1:length(folderDate)
    %         date=folderDate(iDate).name;
    folder=dir(fullfile(metaPathMain,date,'meas*')); % G always comes before R
    
    folderName=[];k=1;
    for iFolder=1:length(folder)
        if strlength(folder(iFolder).name)==6
            folderName{k}=folder(iFolder).name;
            k=k+1;
        end
    end
    
    for iFolder=1:length(folderName)
        metaPath=fullfile(metaPathMain,date,folderName{iFolder});
        temp=load(fullfile(metaPath,'metadata.mat'));
        metadata=temp.metadata; clear temp;
        
               
        %             Fs=601;
        %             data=h5read(path,'/mov');
        %             dim=size(data);
        %             temp=imresize3(data,[dim(1)/3 dim(2)/3 dim(3)],'box');
        % %             [datafilt]=movieTimeFiltering(temp, [1 100],601);
        %             movie_dns = denoisingStep(single(temp), 10, 'DnCNN');
        % % temp=normalize(temp,3,'zscore','robust');
        % % dim=size(movie_dns);
        % %             movie_dns=imresize3(movie_dns,[dim(1)/4 dim(2)/4 dim(3)],'box');
        % implay(mat2gray(movie_dns))
        %
        % dim=size(movie_dns);
        % vect=reshape(movie_dns,dim(1)*dim(2),dim(3));
        %
        %             parfor i=1:dim(1)*dim(2)
        %             [frequency,pow(i,:),~]=plotPSD(sh_bpFilter(vect(i,:),[0.1 300],601),'FrameRate',601,'FreqBand',[1 100],'VerboseFigure',false,'Window',2);
        %             end
        %             powavg=mean(pow,1);
        %             plot(frequency,powavg)
        %
        %            trace=getPointProjection(movie_dns);
        %            trace=sh_bpFilter(trace,[0.5 4],601);
        %            [upper]=envelope(trace,1*Fs);
        %
        %            [disp,speed]=getMouseSpeed(metadata.Locomotion,Fs);
        %            hold on
        %            plot(getTime(trace,601),20*zscore(upper),'k')
        %            hold off
        %            plotPSD(sh_bpFilter(trace,[0.5 300],601),'FrameRate',601,'FreqBand',[1 100],'VerboseFigure',true,'Window',2);
           
        % Denoising
        try
            path=strrep(metadata.allPaths.h5PathG, '.h5','_bp_moco_dtr_dns2.h5');
            %                                runPCAICA(pathG,metadata.fps)
            [outputpos]=runEXTRACT(path,'polarityGEVI','pos','binning',1);
                        [outputneg]=runEXTRACT(path,'polarityGEVI','neg','binning',1);
            [output]=runNMF(path,'polarityGEVI','neg','frameRange',[1 10000],'binning',2);
            %                 path=strrep(metadata.allPaths.h5PathR, '.h5','_bp_moco_dtr.h5');
            %                 denoising1Movie(path,'ranks',10,'windowSize',5*metadata.fps);
        catch ME
        end
        
        
        
    end
    %         errorDiary
    %     end
end

%%

