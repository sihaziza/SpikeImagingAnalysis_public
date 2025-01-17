function [M]=runCheckCell(h5Path,varargin)


%% OPTIONS

options.diary=true;
options.plotFigure=true;
options.diary_name='diary';
options.verbose=true;
options.frameRange=[];
options.polarityGEVI='neg'; % 'pos' 'dual'
options.checkCell=true;
options.rank=100;
options.binning=[];
%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE


%% LOAD RAW DCMIG DATA
disps('Starting EXTRACT Cell Check - Manual Curing')

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
    if isempty(options.frameRange)
        options.frameRange=[1 numFrame];
    end
    dataset=strcat(meta.Name,meta.Datasets.Name);
    outputdir=fullfile(folderPath,'DemixingEXTRACT',fname);
    M=h5read(h5Path,dataset,[1 1 options.frameRange(1)],[mx my diff(options.frameRange)+1]);
    disp('Movie succefully loaded')
    if ~isempty(options.binning)
        M=imresize3(M,[mx/options.binning my/options.binning diff(options.frameRange)+1],'box');
    end
    if ~exist(outputdir,'dir')
        mkdir(outputdir)
    end
    
else
    M=h5Path;
end
% a='F:\GEVI_Spike\Preprocessed\Spontaneous\m915\20210221\meas05\DemixingEXTRACT\m915_d210221_s05laser100pct--fps601-cG_bp_moco_dtr';
% b=load(fullfile(a,'extractOutput_pos_20210401T130938.mat'));
% % load(outputdir
% %Perform the extraction
% switch options.polarityGEVI
%     case 'pos'
% %         output=extractor(M,config);
%         if options.checkCell
%         cell_check(output,M)
%         end
%     case 'neg'
%         M=-M+2*mean(M,3);
% %         output=extractor(M,config);
%         if options.checkCell
%         cell_check(output,M)
%         end
% %     case 'dual'
% %         Mp=M;
% %         output_pos=extractor(Mp,config);
% %         Mn=-M+2*mean(M,3);
% %         output_neg=extractor(Mn,config);
% %         output.positive=output_pos;
% %         output.negative=output_neg;
% %         if options.checkCell
% %         cell_check(output,M)
% %         end
% end
% 
% 
% if ischar(h5Path)
%     fileName=['extractOutput_' options.polarityGEVI '_' datestr(datetime('now'),'yyyymmddTHHMMSS') '.mat'];
%     savePath=fullfile(outputdir,fileName);
%     save(savePath,'output');
% end
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
            fprintf('%s Demixing EXTRACT: %s\n', datetime('now'),string);
        end
    end

end