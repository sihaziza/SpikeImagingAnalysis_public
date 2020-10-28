function [options]=setExportPath(dcimgPath)

%% All Options
options.dcimgPath=dcimgPath;
options.dcimgPathG=[];
options.dcimgPathR=[];
options.h5PathG=[];
options.h5PathR=[];
options.metadataPath=[];
options.metadataName='metadata';
options.export_folder=[];
options.diagnostic_folder=[];
options.suffix=[];
options.pathDiagLoading=[];
options.pathDiagRegistration=[];
options.pathDiagMotionCorr=[];
options.pathDiagUnmixing=[];
options.pathDiagDenoising=[];
options.pathDiagBehavior=[];

%%
disp('Creating paths')
% Find Green & Red DCIMG files
fileName=dir(fullfile(dcimgPath, '*.dcimg')); % G always comes before R

[fileNameG, fileNameR]=fileName.name; % for saving other outputs

options.dcimgPathG=fullfile(dcimgPath,fileNameG);
options.dcimgPathR=fullfile(dcimgPath,fileNameR);

% % basic information about the file (date of creation should be passed to H5)
% finfoG=dir(dcimgPathG);
% finfoR=dir(dcimgPathR);

% Checking if we are on the right path and determining if the output path
pathStructure=voltPaths(fileparts(options.dcimgPathG));
if ~isempty(options.export_folder)
    folderExport=options.export_folder;
else
    folderExport=pathStructure.PreprocessingTemporary;
end

if ~isfolder(folderExport)
    mkdir(folderExport)
end

options.export_folder=folderExport;

options.metadataPath=folderExport;

% Diagnostic folder and sub-folder

options.diagnostic_folder=fullfile(folderExport,'Diagnostic');
if ~isfolder(options.diagnostic_folder)
    mkdir(options.diagnostic_folder)
end

options.pathDiagLoading=fullfile(options.diagnostic_folder,'loading');
if ~isfolder(options.pathDiagLoading)
    mkdir(options.pathDiagLoading)
end

options.pathDiagRegistration=fullfile(options.diagnostic_folder,'registration');
if ~isfolder(options.pathDiagRegistration)
    mkdir(options.pathDiagRegistration)
end

options.pathDiagMotionCorr=fullfile(options.diagnostic_folder,'motionCorr');
if ~isfolder(options.pathDiagMotionCorr)
    mkdir(options.pathDiagMotionCorr)
end

options.pathDiagUnmixing=fullfile(options.diagnostic_folder,'unmixing');
if ~isfolder(options.pathDiagUnmixing)
    mkdir(options.pathDiagUnmixing)
end

options.pathDiagDenoising=fullfile(options.diagnostic_folder,'denoising');
if ~isfolder(options.pathDiagDenoising)
    mkdir(options.pathDiagDenoising)
end

options.pathDiagBehavior=fullfile(options.diagnostic_folder,'behavior');
if ~isfolder(options.pathDiagBehavior)
    mkdir(options.pathDiagBehavior)
end

options.h5PathG=fullfile(folderExport,[erase(fileNameG,'.dcimg'),options.suffix, '.h5']);
options.h5PathR=fullfile(folderExport,[erase(fileNameR,'.dcimg'),options.suffix, '.h5']);

%% this look dangerous... INDEED!! SH-20201017
if isfile(options.h5PathG)
    disp('Found green channel h5 file, you mind want to delete first as h5save will crash...')
%     delete(options.h5PathG);
end

if isfile(options.h5PathR)
    disp('Found red channel h5 file, you mind want to delete first as h5save will crash...')
%     delete(options.h5PathR);
end

end