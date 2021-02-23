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
mouse={'m912' 'm913' 'm915'};

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
    'softwareBinning',1,...
    'findBestFilter',false,...
    'croppingMethod','manual',... 
    'loadTTL',false);%     
            end
        end
    end
end

%% LOAD AND CONVERT .dcimg RAW MOVIE

mainFolder='F:\GEVI_Spike\Preprocessed\Spontaneous';
mouse={'m912' 'm913' 'm915'};
% fail=[];
% date='20200416';
for iMouse=1:length(mouse)
    metaPathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(metaPathMain,'2021*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(metaPathMain,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
        for iFolder=1:length(folderName)
            try
metaPath=fullfile(metaPathMain,date,folderName{iFolder});
temp=load(fullfile(metaPath,'metadata.mat'));
metadata=temp.metadata; clear temp;

% loading(metadata.allPaths);

% % % GENERATE THE BANDPASS MOVIE FOR MOTION CORRECTION
% % Find the best filter frequency bands - [2 20] is good
% % [bpFilter]=findBestFilterParameters(allPaths.h5PathG);
% metadata.vectorBandPassFilter=[1 30];
% bandPassMovieChunk(metadata.allPaths.h5PathG,metadata.vectorBandPassFilter);
% bandPassMovieChunk(metadata.allPaths.h5PathR,metadata.vectorBandPassFilter);
% 
% % % CORRECT THE MOVIE FROM MOTION ARTEFACTS
% pathG=strrep(metadata.allPaths.h5PathG,'.h5', '_bp.h5');
% pathR=strrep(metadata.allPaths.h5PathR,'.h5', '_bp.h5');
% try
% motionCorr1Movie(pathG,'nonRigid', false);
% catch
% end
% try
% motionCorr1Movie(pathR,'nonRigid', false);
% catch
% end

% % CORRECT for photobleaching
% pathG=strrep(metadata.allPaths.h5PathG, '.h5','_moco2.h5');
% pathR=strrep(metadata.allPaths.h5PathR, '.h5','_moco2.h5');
% try
% detrending(pathG)
% catch
% end
% try
% detrending(pathR)
% catch 
% end

% DENOISING the Movie
% try
% pathG=strrep(metadata.allPaths.h5PathG,'.h5', '_moco2_dtr2.h5');
% denoising1Movie(pathG,'windowSize',metadata.fps);
% catch
% end
% 
% try
% pathR=strrep(metadata.allPaths.h5PathR,'.h5', '_moco2_dtr2.h5');
% denoising1Movie(pathR,'windowSize',metadata.fps);
% catch
% end

% % DENOISING the Movie
% pathG=strrep(metadata.allPaths.h5PathG,'.h5', '_dtr.h5');
% pathR=strrep(metadata.allPaths.h5PathR,'.h5', '_dtr.h5');
% denoising1Movie(pathG,'windowSize',metadata.fps);
% denoising1Movie(pathR,'windowSize',metadata.fps);
% 
% DEMIX THE MOVIE TO FIND SINGLE NEURONS - same on denoised movie
pathG=strrep(metadata.allPaths.h5PathG, '.h5','_moco.h5');
pathR=strrep(metadata.allPaths.h5PathR, '.h5','_moco.h5');
try
runPCAICA(pathR,metadata.fps)
catch ME1
    ME1;
end
try
runPCAICA(pathG,metadata.fps)
catch ME2
    ME2;
end

% % DEMIX THE MOVIE TO FIND SINGLE NEURONS 
% pathG=strrep(metadata.allPaths.h5PathG, '.h5','_dtr.h5');
% pathR=strrep(metadata.allPaths.h5PathR, '.h5','_dtr.h5');
% try
% runPCAICA(pathG,metadata.fps)
% catch ME1
%     ME1;
% end
% try
% runPCAICA(pathR,metadata.fps)
% catch ME2
%     ME2;
% end
%             catch ME
                ME;
            end
        end
    end
end

%% Denoising
% % 
% mainFolder='F:\GEVI_Spike\Preprocessed\Whiskers';
% mouse={'m83' 'm84' 'm85'};
% % fail=[];
% % date='20200416';
% for iMouse=1%:length(mouse)
%     metaPathMain=fullfile(mainFolder,mouse{iMouse});
%     % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
%     folderDate=dir(fullfile(metaPathMain,'2020*')); % G always comes before R
%     
%     for iDate=1:length(folderDate)
%         date=folderDate(iDate).name;
%         folder=dir(fullfile(metaPathMain,date,'meas*')); % G always comes before R
%         
%         folderName=[];k=1;
%         for iFolder=1:length(folder)
%             if strlength(folder(iFolder).name)==6
%                 folderName{k}=folder(iFolder).name;
%                 k=k+1;
%             end
%         end
%         
%         for iFolder=1:length(folderName)
% 
% metaPath=fullfile(metaPathMain,date,folderName{iFolder});
% temp=load(fullfile(metaPath,'metadata.mat'));
% metadata=temp.metadata; clear temp;
% 
% % DENOISING the Movie
% try
% pathG=strrep(metadata.allPaths.h5PathG,'.h5', '_dtr2.h5');
% denoising1Movie(pathG,'windowSize',metadata.fps);
% catch
% end
% 
% try
% pathR=strrep(metadata.allPaths.h5PathR,'.h5', '_dtr2.h5');
% denoising1Movie(pathR,'windowSize',metadata.fps);
% catch
% end
% % % DEMIX THE MOVIE TO FIND SINGLE NEURONS - same on denoised movie
% % try
% % pathG=strrep(metadata.allPaths.h5PathG, '.h5','_dns.h5');
% % runPCAICA(pathG,metadata.fps)
% % catch ME1
% %     ME1;
% % end
% % trypathR=strrep(metadata.allPaths.h5PathR, '.h5','_dns.h5');
% % runPCAICA(pathR,metadata.fps)
% % catch ME2
% %     ME2;
% % end
% 
%         end
%     end
% end
