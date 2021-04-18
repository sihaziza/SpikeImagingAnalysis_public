function [S,T,map,binaryMap]=getCellSTfilters(output)
% output the spatial and temporal filters of cleaned-up extract output

temp=full(output.spatial_weights);
temp=temp(:,:,output.cellID);
S=temp;
T=double(output.temporal_weights(:,output.cellID));

nUnits=min(size(T));

for i=1:nUnits
tempS(:,:,i)=rescale(S(:,:,i),0,255);
% tempS=tempS(:);
tempS(tempS<150)=0;
% temp
end

map=mean(tempS,3);
% 
figure(1);%figure('defaultaxesfontsize',12,'color','w');
imshow(map,[])
% % imagesc(map)
% % axis tight
plot_cells_overlay(tempS,[],3,0.75)
% % axis off

binaryMap=imbinarize(map,5*256/10);
end