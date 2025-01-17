% function [cellRadius]=estimateCellRadius(frame)
% get the optimal cell radius
folderPath='F:\GEVI_Spike\Preprocessed\Spontaneous\m915\20210221\meas01';
fname='m915_d210221_s01laser100pct--fps601-cG_bp_moco.h5';

  h5Path=fullfile(folderPath,fname);  
    meta=h5info(h5Path);
    dim=meta.Datasets.Dataspace.Size;
    mx=dim(1);my=dim(2);numFrame=dim(3);
    dataset=strcat(meta.Name,meta.Datasets.Name);
    M=h5read(h5Path,dataset,[1 1 1],[mx my 1000]);
    M=bpFilter2D(M,25,2,'parallel',false);
    
    Mavg=mean(M,3);Mavg=rescale(Mavg,0, 255);
    Mstd=std(M,[],3);Mstd=rescale(Mstd,0, 255);
    
    frame=[Mavg; Mstd];
  
imshow(frame,[])
[cx,cy,~] =improfile;

xi=round([cx(1) cx(end)]);
yi=round([cy(1) cy(end)]);

[cx] =improfile(frame,xi,yi,'bilinear');

[xData,yData,fitresult] = createGaussianFit(cx,'fittype','gauss2');
plot(fitresult,xData,yData)

data=(fitresult(xData));
% Find the half max value.
halfMax = (min(data) + max(data))*0.5;
% Find where the data first drops below half the max.
index1 = find(data >= halfMax, 1, 'first');
% Find where the data last rises above half the max.
index2 = find(data >= halfMax, 1, 'last');
fwhm = index2-index1 + 1; % FWHM in indexes.
% OR, if you have an x vector
fwhmx = xData(index2) - xData(index1);
cellRadius=2*fwhmx
% end