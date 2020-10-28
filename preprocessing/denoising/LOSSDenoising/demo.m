clear; clc;

addpath(genpath('utilities'));

disp(['begin reading file...']);

folder = './';
% filename = '200217-504B-20xpAceR(P40)-F02-01-10s-spon-50_pwr.tif';
% filename = '200721-433B-pAce-F01-01-1x5s-VIN.tif';
filename = '200623-085C-2pAce-F04-02-1x5s-EtA_CS+.tif';

data = aux_stackread([folder filename]);

% Denoising by LOSS (Learning rObust SubSpace)
disp(['begin denoising...']);
% movie_out = denoisingLOSS(data);
[nx,ny,nz] = size(data);

%% Option-1
[movie_out,~, Info] = denoisingLOSS(data,'windowsize', 2000,'useGPU',0,'tau',0.01,'lambda',5*1/sqrt(nx*ny));
disp(['finished']);

%% Option-2: remove spatial filtering
[movie_out,~, Info] = denoisingLOSS(data,'windowsize', 2000,'useGPU',0,'tau',0.01,'lambda',5*1/sqrt(nx*ny),'noSpatial', true);
disp(['finished']);

%% Option-3: only denoise the traces
funReshape = @(x) reshape(double(x),[],size(data,3),1);
X = funReshape(data);
traceX = zscore(mean(X));

% determine the maximum regularization parameter
[traceY,status] = denoisingTrace(traceX', 0.00000001);
figure; plot(traceX); hold on; plot(traceY);


%% ROI selection
f1=figure; imshow(data(:,:,1),[]);
set(gcf, 'Position', get(0, 'Screensize'));

hBox = imrect;
roiPosition = wait(hBox);

close(f1);

%% compute ROI traces
funReshape = @(x) reshape(double(x),[],size(data,3),1);

beforeROI = data(roiPosition(2):roiPosition(2)+roiPosition(4)-1,roiPosition(1):roiPosition(1)+roiPosition(3)-1,:);
X = funReshape(beforeROI);
traceX = zscore(mean(X));
afterROI = movie_out(roiPosition(2):roiPosition(2)+roiPosition(4)-1,roiPosition(1):roiPosition(1)+roiPosition(3)-1,:);
Y = funReshape(afterROI);
traceY = zscore(mean(Y));

% Visualization
%dispBeforeAfter(data, movie_out, roiPosition)
% dispBothApp(data,movie_out,roiPosition,traceX, traceY);
compare(data,movie_out)

figure; plot([traceX' traceY']); legend('Before','After');
drawnow;
%% Saving
aux_stackwrite(uint16(movie_out), [folder filename '_denoised.tif']);
