clear; clc;
root='F:\GEVI_Spike\Visual';
mouse=[81 82];
date=20200416;
% \m81\20200416\meas05
for m=1%1:3
    for d=1%1:2
        for n=5%
            
%             
         
            % path = 'F:\TEMPO2D_raw\Spikes\m81\20200131\meas03\converted\spike-ace-varnam-laser561nm-fov1-1khz--BL35-fps401-cG-000.h5';
            file='DualSpike--BL10-fps502';
            path=fullfile(root,strcat('m',num2str(mouse(m))),num2str(date(d)),strcat('meas0',num2str(n)),strcat(file,'_cG.dcimg'));
%             cd(path)
               obj = Recording(path);
               V=obj.load;
               V=obj.convert;
               
%             path=fullfile(root,strcat('m',num2str(mouse(m))),num2str(date(d)),strcat('meas0',num2str(n)),strcat(file,'_cR.dcimg'));
% %             cd(path)
%                obj = Recording(path);
%                obj.load
%                obj.convert
        end
    end
end


%%

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





