
path = '/media/lijz/Data/Voltage-Simon/Voltage/Visual_m699_20191202_meas03/ProcessedData.h5';

V3d = h5read(path, '/VLT');

num = 30;
[spatial, temporal] = DecompNMF_ALS(V3d, num);
figure; imshow(spatial(:,:,1),[]); title('PC-1 - spatial');
figure; plot(temporal(:,1)); title('PC-1 - temporal');

%%
figure
ha = tight_subplot(6,5,[.01 .01],[.01 .01],[.01 .01])
for i=1:30
   temp = spatial(:,:,i); 
  axes(ha(i));
   imshow(temp,[]);
%    title([num2str(i)]);
   colormap('jet')
end

saveas(gcf,'spatial.png')
%%
% temporal components
T1 = S1*V1';
ha = tight_subplot(5,1,[.01 .01],[.01 .01],[.01 .01])
for i=1:5
  axes(ha(i));
  plot(T1(i,:));
end

%% Align with the brain map
imgpath = '/media/lijz/Data/Voltage-Simon/Voltage/Visual_m699_20191202_meas03/cG.h5';
dataG = h5read(imgpath, '/1', [1 1 1], [2048 2048 1]);
[dataG, boundbox] = sh_autoCropImage(dataG, []);
dataG = fliplr(imrotate(dataG, -90));
figure; imshow(dataG,[])
%%
