
clear; clc;
addpath(genpath('utilities'));
path = '/scratch/groups/mschnitz/STM_53Z/';
denoisedpath = '/scratch/groups/mschnitz/STM_53Z_denoised/';
filename = '53Z_day56_Z2';

hinfo=h5info([path filename '.h5']);
totalnum = hinfo.Datasets.Dataspace.Size(3);
nx = hinfo.Datasets.Dataspace.Size(1);
ny = hinfo.Datasets.Dataspace.Size(2);
numFrame = 2000;

outputfilename = [filename '_denoised'];

if isfile([denoisedpath outputfilename '.h5'])
    delete([denoisedpath outputfilename '.h5']);
end

h5create([denoisedpath outputfilename '.h5'],'/images',[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,numFrame]);

for i=1:numFrame:totalnum
    
    data = h5read([path filename '.h5'],'/images',[1,1,i],[nx,ny,numFrame]);
    
    %% stage 1: denoising first, then estimate the motion
    [nx,ny,nz] = size(data);
    timeA = tic;
    [movie_out,E_out, Info] = denoisingLOSS(data,'windowsize', numFrame,'useGPU',0,'ranks',20,'tau',0.02,'lambda',0.5);
    toc(timeA)
    normcorre_options = NoRMCorreSetParms('d1',nx,'d2',ny,...
        'max_shift',15,'us_fac',30,'correct_bidir',false,'upd_template',false);
    disp(['=== Motion correction before denoising...']);
    [~,shifts,~,~] = normcorre_batch(movie_out,normcorre_options);
    %% stage 2: apply the motion and denoising again
    data = apply_shifts(data,shifts,normcorre_options);
    [movie_out,E_out, Info] = denoisingLOSS(data,'windowsize', numFrame,'useGPU',0,'ranks',20,'tau',0.02,'lambda',0.5);
    
    h5write([denoisedpath outputfilename '.h5'],'/images',single(movie_out),[1,1,i],[nx,ny,numFrame]);
    
end

