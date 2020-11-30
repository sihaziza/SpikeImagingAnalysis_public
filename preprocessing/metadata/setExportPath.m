function [options]=setExportPath(dcimgPath)
% add up description


%% All Options
options.dcimgPath=dcimgPath;
options.dcimgPathG=[];
options.dcimgPathR=[];
options.h5PathG=[];
options.h5PathR=[];
options.exportFolder=[];
options.metadataPath=[];
options.loading=true;
options.registration=false;
options.motionCorr=true;
options.denoising=false;
options.demixing=true;
options.unmixing=false;
options.behavior=false;
options.diagnosticFolder=[];
options.pathDiagLoading=[];
options.pathDiagRegistration=[];
options.pathDiagMotionCorr=[];
options.pathDiagDenoising=[];
options.pathDiagUnmixing=[];
options.pathDiagDemixing=[];
options.pathDiagBehavior=[];
options.verbose=true;

%% Find dcimg files and check for export path

disp('Creating paths')
% Find Green & Red DCIMG files
fileName=dir(fullfile(dcimgPath, '*.dcimg')); % G always comes before R

if size(fileName,1)==2
    [fileNameG, fileNameR]=fileName.name; % for saving other outputs
    options.dcimgPathG=fullfile(dcimgPath,fileNameG);
    options.dcimgPathR=fullfile(dcimgPath,fileNameR);
elseif size(fileName,1)==1
    if ~isempty(strfind(allPaths.dcimgPathG,'cG.dcimg'))
        [fileNameG]=fileName.name;
        options.dcimgPathG=fullfile(dcimgPath,fileNameG);
        options.dcimgPathR=[];
    else
        [fileNameR]=fileName.name;
        options.dcimgPathG=[];
        options.dcimgPathR=fullfile(dcimgPath,fileNameR);
    end
else
    error('Oups... no dcimg file detected');
end

% Checking if we are on the right path and determining the output path
pathStructure=[];
try
    pathStructure=voltPaths(fileparts(options.dcimgPathG));
catch
    disp('Not the correct path - OK, saving along with the raw file')
end

if ~isempty(options.exportFolder)
    folderExport=options.exportFolder;
elseif pathStructure.valid_structure
    folderExport=pathStructure.PreprocessingTemporary;
else
    folderExport=fullfile(fileName(1).folder,'results');
end

if ~isfolder(folderExport)
    mkdir(folderExport)
end

options.exportFolder=folderExport;
options.metadataPath=fullfile(folderExport,'metadata.mat');

%% Create all diagnostic folders
options.diagnosticFolder=fullfile(folderExport,'diagnostic');
if ~isfolder(options.diagnosticFolder)
    mkdir(options.diagnosticFolder)
end

options.pathDiagLoading=fullfile(options.diagnosticFolder,'loading');
if options.loading && ~isfolder(options.pathDiagLoading)
    mkdir(options.pathDiagLoading)
end

options.pathDiagRegistration=fullfile(options.diagnosticFolder,'registration');
if options.registration && ~isfolder(options.pathDiagRegistration)
    mkdir(options.pathDiagRegistration)
end

options.pathDiagMotionCorr=fullfile(options.diagnosticFolder,'motionCorr');
if options.motionCorr && ~isfolder(options.pathDiagMotionCorr)
    mkdir(options.pathDiagMotionCorr)
end

options.pathDiagDenoising=fullfile(options.diagnosticFolder,'denoising');
if options.denoising && ~isfolder(options.pathDiagDenoising)
    mkdir(options.pathDiagDenoising)
end

options.pathDiagUnmixing=fullfile(options.diagnosticFolder,'Unmixing');
if options.unmixing && ~isfolder(options.pathDiagUnmixing)
    mkdir(options.pathDiagUnmixing)
end

options.pathDiagDemixing=fullfile(options.diagnosticFolder,'demixing');
if options.demixing && ~isfolder(options.pathDiagDemixing)
    mkdir(options.pathDiagDemixing)
end

options.pathDiagBehavior=fullfile(options.diagnosticFolder,'behavior');
if options.behavior && ~isfolder(options.pathDiagBehavior)
    mkdir(options.pathDiagBehavior)
end

%% Set and Check for h5 file
if size(fileName,1)==2
    options.h5PathG=fullfile(folderExport,strrep(fileNameG,'.dcimg','.h5'));
    options.h5PathR=fullfile(folderExport,strrep(fileNameR,'.dcimg','.h5'));
    if isfile(options.h5PathG)
        disp('Found green channel h5 file, you mind want to delete first as h5save will crash...')
        answer=input('Want to overwrite this file [0-no / 1-yes]?');
        if answer; delete(options.h5PathG);end
    end
    
    if isfile(options.h5PathR)
        disp('Found red channel h5 file, you mind want to delete first as h5save will crash...')
        answer=input('Want to overwrite this file [0-no / 1-yes]?');
        if answer; delete(options.h5PathG);end
    end
else
    options.h5PathG=fullfile(folderExport,strrep(fileNameG,'.dcimg','.h5'));
    if isfile(options.h5PathG)
        disp('Found green channel h5 file, you mind want to delete first as h5save will crash...')
        answer=input('Want to overwrite this file [0-no / 1-yes]?');
        if answer; delete(options.h5PathG);end
    end
end

disps('all export paths succesfully created')

    function disps(string) %overloading disp for this function - this function should be nested
        FUNCTION_NAME='setExportPath';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end

end