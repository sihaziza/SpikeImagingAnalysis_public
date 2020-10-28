
root='F:\TEMPO2D_raw\Spikes';
mouse=[78 81 82];
date=[20200130 20200131];

for m=2%1:3
    for d=2%1:2
   path=fullfile(root,strcat('m',num2str(mouse(m))),num2str(date(d)));
   cd(path)
    end
end
        %%
clear; clc;

path = 'F:\TEMPO2D_raw\Spikes\m81\20200131\meas03\converted\spike-ace-varnam-laser561nm-fov1-1khz--BL35-fps401-cG-000.h5';

obj = Recording(path);

%%
obj.load

% motion correction
obj.moco

%% denoising
% to be integrated into the MicroscopeRecording package
addpath(genpath('./'));
options.windowsize = 5000;
obj.movie = denoising(obj.movie, options);

%% once again motion correction
obj.moco

%% save files

obj.folderpath = fullfile(obj.folderpath,'denoised');
if ~isfolder(obj.folderpath)
    mkdir(obj.folderpath);
end
obj.convert;


%% trace analysis
thre=550; %background threshold
P=30;% Minimun area of cells to extract
[L,X,Y,N]=analysis_trace(obj.movie,thre,P);





