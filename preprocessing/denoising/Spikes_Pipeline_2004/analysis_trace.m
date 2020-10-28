function [X,Y,Trace,fig]=analysis_trace(Mr,thre,P)
% file='Test 1/image17.tif';
% thre=150;
% P=30;% Minimun area of cells to extract

% cell segmentation
%1. take the mean value to find the mask
Mean = mean(Mr,3);
% figure(11);
% imshow(Mean,[]);
X=[];
Y=[];
%% 2. thresholding
% thre = 50;
BW = imbinarize(Mean,thre);
%preview
% figure(12);
% imshowpair(Mean,BW);

%%
se = strel('disk',5);
BWopen = imopen(BW,se);
% figure(13);imshowpair(Mean,BWopen);

%% tell how many cells 
CC = bwconncomp(BW);
S = regionprops(CC, 'Area');
L = labelmatrix(CC);
%P = 300; % minimum area
BW2 = ismember(L, find([S.Area] >= P));
CC = bwconncomp(BW2);
Sfiltered_Centroid = regionprops(CC, 'Centroid');

N=num2str(CC.NumObjects);
disp('Creation of binary image...');

NumCell = numel(Sfiltered_Centroid);

for i=1:numel(Sfiltered_Centroid)
    X(i) = Sfiltered_Centroid(i).Centroid(1);
    Y(i) = Sfiltered_Centroid(i).Centroid(2);
end
% 
fig=figure;
clf
% subplot(3,1,1);
cmap = hsv(NumCell); 
imshow(Mean,[]); hold on; 

for i = 1:NumCell
  plot(X(i),Y(i),'.','MarkerSize',20,'Color',cmap(i,:)); hold on;
  visboundaries(BW2,'LineWidth',0.5,'Color',cmap(i,:));
end
% subplot(3,1,2);
L = bwlabel(BW2);
% imshow(L,[]);
hold off;

%%

%trace visualization
U = unique(L);
for i=2:numel(U)
    Index{i-1} = find(L==U(i));
end

%
for j=1:size(Mr,3)
    frame = Mr(:,:,j);
for i=1:NumCell
    Trace(i,j) = mean(frame(Index{i}));
end
end

% figure()
% for i=1:NumCell
%     plot(sh_Standardize(Trace(i,:))+5*i,'Color',cmap(i,:));
%     hold on;
% end
disp('The End')
end
    
