function [units, trace,boundbox]=getUnitsROI(h5Path,Fs,varargin)
% to extract time traces based on ROI without loading the full movie
% [units, trace]=getUnitsROI(h5Path,Fs)
% Step1: load 1st second and generate the average frame to crop from
% Step2: get the average pixel trace from the h5 file
% drawcircle
% imcrop

%% DEFAULT INPUT OPTIONS
options.boundbox=[];

%% USER-DEFINED INPUT OPTIONS
if nargin>2
    options=getOptions(options,varargin);
end

%% LOAD RAW DCMIG DATA
% disp('Starting Neuron Demixing (PCAICA)')

[folderPath,fname,ext]=fileparts(h5Path);
if strcmpi(ext,'.h5')
    disp('h5 file detected')
else
    error('not a h5 or Tiff file')
end

meta=h5info(h5Path);
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

movie=h5read(h5Path,dataset,[1 1 1],[mx my Fs]);
MEAN_PROJECTION=mean(movie,3);
f0=bpFilter2D(MEAN_PROJECTION,25,1,'parallel',false);

if isempty(options.boundbox)
crop = get_circular_mask(f0);

image=f0.*crop;
[~, boundbox] = autoCropImage(image, 'plot',true);
else
    boundbox=options.boundbox;
end

units=h5read(h5Path,dataset,[boundbox(2) boundbox(1) 1],[boundbox(4) boundbox(3)  numFrame]);

trace=getPointProjection(units);
time=getTime(trace,Fs);

figure(10)
plot(time,trace)


% DESCRIPTION
%
% SYNTAX
%
% EXAMPLE
%
% CONTACT: StanfordVoltageGroup@gmail.com

%% GET DEFAULT OPTIONS

% options.verbose=true;
% options.boundbox=[];
% options.threshold=0.1; % remove 10% of above background level
% outputdir=fullfile(folderPath,'DemixingPCAICA',fname);
% if ~exist(outputdir,'dir')
%     mkdir(outputdir)
% end
end