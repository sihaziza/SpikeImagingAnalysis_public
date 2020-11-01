% put file detection to avoid overwrite
% put varargin for various option

function makeMovie(movie,Name,FPS,varargin)
% tic;
frc=0.75;
DIM=size(movie);
mm=min(min(min(movie,[],1),[],2));
MM=max(max(max(movie,[],1),[],2));
% switch
%     case 'InvFilp'
%         if varin{3}==YES
% At this stage, movie is flip in y-axis to get AP=top-down and z-axis is
% flipped to represent +dF/F (SNR)
MxVid=255*mat2gray(movie,double([-frc*MM -frc*mm]));

myVideo = VideoWriter(Name,'Indexed AVI');
myVideo.FrameRate =FPS;
myVideo.Colormap=jet(256);
open(myVideo);
figure(1)
set(gca,'nextplot','replacechildren');
for k = 1:DIM(3)
   fig=imshow(MxVid(:,:,k));
   writeVideo(myVideo,uint8(fig.CData));
end
close(myVideo);
% toc;
end