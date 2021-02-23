function [output]=runEXTRACT(h5Path,varargin)


%% OPTIONS

% options.windowsize=2000;
% options.dataset='mov';
options.diary=true;
options.plotFigure=true;
options.diary_name='diary';
options.verbose=true;
options.frameRange=[];

%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE


%% LOAD RAW DCMIG DATA
disps('Starting Neuron Demixing (EXTRACT)')

if ischar(h5Path)
    
[folderPath,fname,ext]=fileparts(h5Path);
if strcmpi(ext,'.h5')
    disps('h5 file detected')
else
    error('not a h5 or Tiff file')
end

meta=h5info(h5Path);
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);
else
    M=h5Path;
    options.polarityGEVI='-';
end

% outputdir=fullfile(folderPath,'DemixingPCAICA',fname);
% if ~exist(outputdir,'dir')
%     mkdir(outputdir)
% end
% 
% if options.diary
%     diary(fullfile(outputdir,options.diary_name));
% end

%Initialize config
config=[];
config = get_defaults(config);

%Set some important settings
config.use_gpu=1;
config.avg_cell_radius=5;
% config.num_partitions_x=1;
% config.num_partitions_y=1;
config.cellfind_min_snr=0.1; % 5 is the default SNR
config.verbose = 2;
config.spatial_highpass_cutoff = 5;
config.spatial_lowpass_cutoff = 2;

%Perform the extraction
switch options.polarityGEVI
    case '+'
         case '-'
            M=-M+2*mean(M,3);

end

output=extractor(M,config); 


% if options.plotFigure
%     savePDF(h,'Cellsort Plot PC spectrum',outputdir);%close;
% end
%%

% % Step 3b: CellsortICAplot
% % load first 100 frames to compute average frame
% movie=h5read(h5Path,dataset,[1 1 1],[mx my 1000]);
% MEAN_PROJECTION=mean(movie,3)';
% f0=bpFilter2D(MEAN_PROJECTION,25,1,'parallel',false);
% f0=f0';
% 
% if options.plotFigure
%     h=figure('defaultaxesfontsize',16,'color','w');
%     imshow(f0,[])
%     title('Average Intensity - bandpassed')
%     savePDF(h,'Average Intensity - bandpassed',outputdir);%close;
% end
% 
% if options.plotFigure
%     savePDF(h,'ICAplot Template',outputdir);%close;
% end

%%
% 
% smwidth=1;
% thresh=1;
% arealims=[50 500];
% plotting=1;

% [ica_segments, segmentlabel, segcentroid] = CellsortSegmentation(ica_filters,1,1,[250 500],1);%, smwidth, thresh, arealims, plotting);
%%
% 
% savePath=fullfile(outputdir,strcat(fname,'_unitsPCAICA.mat'));
% % Save the output data
% if isempty(savePath)
%     save(savePath,'ica_filters', 'ica_sig')
% else
%     savePath=strrep(savePath,'.mat','temp.mat');
%     save(savePath,'ica_filters', 'ica_sig')
% end
% 
% disps('PCAICA-based Demixing output succesfully saved')
% 
% % %%
% nSpikingCells=2;
% % IDs=[end-nSpikingCells+1:end];
% IDs=[9 10];
% spikes=zscore(ica_sig(IDs,:)');
% figure()
% plot(spikes)
%
% % for thres=6:0.5:8
% [spikeRaster]=plotSpikeRaster(cell_sig(end-9:end,:)',Fs,6);
% % end
% plotXCorrelogram(spikeRaster,Fs);
% % plotAutoCorrelogram(spikeRaster,Fs);
% 
% if options.diary
%     diary off
% end

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s Demixing PCAICA: %s\n', datetime('now'),string);
        end
    end

end