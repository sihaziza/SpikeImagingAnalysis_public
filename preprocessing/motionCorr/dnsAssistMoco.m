function [output,options]=bpAssistMoco(input,varargin)
% perform motion correction in 2 steps, with a band-pass spatial filtering
% first. User can input as a variable arguemnt a computed shift

options.findBestBP=false;
options.vectorBandPassFilter=[2 20];
options.applyshit=[];
options.windowSize=1000;
options.spatialChunk=false;
options.dataset='mov';
options.ranks=100;
options.dataChunking=false;

%% GET OPTIONS
if nargin>=2
    options = getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

%% CHECK INPUT FORMAT

if ischar(input)
    [~,~,ext]=fileparts(input);
    if strcmpi(ext,'.h5')
        h5Path=input;
        meta=h5info(h5Path);
        disp('h5 file detected')
        dim=meta.Datasets.Dataspace.Size;
        mx=dim(1);my=dim(2);numFrame=dim(3);
        dataset=strcat(meta.Name,meta.Datasets.Name);

        dnsMoviePath=strrep(h5Path,'.h5','_dns.h5');

    elseif istensor(input)
        disp('working with data in workspace')
    else
        error('input data type not accepted - only h5path or workspace')
    end
end

%% CORE FUNCTION

%% with motion correction, often better, mc takes time and two denoising steps needed

outputfilenameLESS_1st = denoisingLESSh5([path h5filename], datasetname,30);
outputfilenameLESS_mc = [outputfilenameLESS_1st '_moco.h5'];
normcorre_options = NoRMCorreSetParms('d1',mx,'d2',my,...
    'max_shift',15,'us_fac',30,'correct_bidir',false,'upd_template',false,'output_type','hdf5','h5_groupname','data','h5_filename',outputfilenameLESS_mc);

disp(['=== Motion correction...']);
[~,shifts,~,~] = normcorre_batch(outputfilenameLESS_1st,normcorre_options);
outputfilename_mc = apply_shifts([path h5filename '.h5'],shifts,normcorre_options);

outputfilenameLESS_final = denoisingLESSh5(outputfilename_mc(1:end-3), datasetname);


% CORRECT THE MOVIE FROM MOTION ARTEFACTS
try
motionCorr1Movie(dnsMoviePath,'nonRigid', false);
catch
end

end