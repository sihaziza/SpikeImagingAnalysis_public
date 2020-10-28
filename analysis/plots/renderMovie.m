% put file detection to avoid overwrite
% put varargin for various option

function renderMovie(movie,Name,FPS,varargin)
% tic;
% frc=0.75;
mov=normalize(double(movie),3,'range',[0 1]);
DIM=size(movie);
% mm=min(min(min(movie,[],1),[],2));
% MM=max(max(max(movie,[],1),[],2));
% switch
%     case 'InvFilp'
%         if varin{3}==YES
% At this stage, movie is flip in y-axis to get AP=top-down and z-axis is
% flipped to represent +dF/F (SNR)
% MxVid=no(movie,double([-frc*MM -frc*mm]));
% imshow(MxVid(:,:,1),[])
myVideo = VideoWriter(Name,'MPEG-4');
myVideo.FrameRate =FPS;
myVideo.Quality=100;
open(myVideo);
figure(1)
set(gca,'nextplot','replacechildren');
for k = 1:DIM(3) %parfor does not work here...
   fig=imshow(mov(:,:,k),[]);
   writeVideo(myVideo,fig.CData);
end
close(myVideo);
% toc;
end