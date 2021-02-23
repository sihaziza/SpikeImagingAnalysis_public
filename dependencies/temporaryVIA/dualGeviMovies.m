function [voltG,voltR,reference,summary]=dualGeviMovies(movieGreen,movieRed,varargin)
% HELP DUALGEVIMOVIES.M
% Decomposing two interleaved movies acquired with pulsing blue/red LEDs into three channels: 'voltG','voltR','reference'.
% SYNTAX
%[voltGvoltRreference,summary]= dualGeviMovies(movieGreen) - use 2, etc.
%[voltGvoltRreference,summary]= dualGeviMovies(movieGreen,movieRed) - use 3, etc.
%[voltGvoltRreference,summary]= dualGeviMovies(movieGreen,movieRed,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[voltGvoltRreference,summary]= dualGeviMovies(movieGreen,movieRed,'options',options) - passing options as a structure.
%
% INPUTS:
% - movieGreen - raw movie acquired from the green channel camera
% - movieRed - raw movie acquired from the red channel camera
%
% OUTPUTS:
% - voltG - ...
% - voltR - ...
% - reference - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 17-Nov-2020 11:58:14 - created by Radek Chrapkiewicz (radekch@stanford.edu)

%% OPTIONS (type 'help getOptions' for details)
options=struct; % add your options below 
options.startingFrame=11; % cutting some first frames of the movie to avoid artifacts of turning on LEDs; assuming that is the first bright frame in green channel 
options.plot=true;
options.colorScaling=[1,1,1];

% additional tweaks
options.nframesCrosstalk=100; % number of frames taken to evalueae cross talk and frame order on the green channel.

%% VARIABLE CHECK 
if nargin>=3
    options=getOptions(options,varargin(1:end)); 
end
% summary=initSummary(options);
summary=[];

%% CORE
% recognizing which frame for the green channel is the signal and which is
% the cross talk from the red channel.
frame1=movieGreen(:,:,options.startingFrame+(0:2:options.nframesCrosstalk));
frame2=movieGreen(:,:,options.startingFrame+(1:2:options.nframesCrosstalk));
frame1=mean(frame1,3);
frame2=mean(frame2,3);

if mean(frame1(:))>mean(frame2(:))
    startingFrame=options.startingFrame;
else
    startingFrame=options.startingFrame+1;
end


%%
summary.crosstalk2voltG=mean(frame2(:))/mean(frame1(:));

%%
voltG=movieGreen(:,:,startingFrame:2:end);
voltR=movieRed(:,:,(startingFrame+1):2:end);
reference=movieRed(:,:,startingFrame:2:end);
crosstalk=movieGreen(:,:,(startingFrame+1):2:end);


movieLength=min([size(voltG,3),size(voltR,3),size(reference,3)]);
voltG=voltG(:,:,1:movieLength);
voltR=voltR(:,:,1:movieLength);
reference=reference(:,:,1:movieLength);

summary.meanCrosstalk=mean(crosstalk,3);
summary.meanVoltG=mean(voltG,3);
summary.meanVoltR=mean(voltR,3);
summary.meanReference=mean(reference,3);

summary.red2blueCrosstalk=mean(summary.meanCrosstalk(:))/mean(summary.meanVoltR(:));

% disps(sprintf('Movie channels split. Red crosstalk 2 green channel = %.4f, Red crosstalk 2 green channel = %.4f',summary.crosstalk2voltG,summary.red2blueCrosstalk));

%% plotting
if options.plot
    
    rgbImage(:,:,1)=summary.meanVoltR/max(summary.meanVoltR(:))*options.colorScaling(1);
    rgbImage(:,:,2)=summary.meanVoltG/max(summary.meanVoltG(:))*options.colorScaling(2);
    rgbImage(:,:,3)=summary.meanReference/max(summary.meanReference(:))*options.colorScaling(3);
    
    clf
    subplot(2,2,4);
    imagesc(rgbImage)
    axis equal 
    axis off
    title('Merged 3 channels')
    
    subplot(2,2,1)
    green=rgbImage;
    green(:,:,[1,3])=0;
    imagesc(green);
        axis equal 
    axis off
    title('Ace')
    
    
    subplot(2,2,2)
    red=rgbImage;
    red(:,:,[2,3])=0;
    imagesc(red);
        axis equal 
    axis off
    title('Varnam')
    
    
    subplot(2,2,3)
    blue=rgbImage;
    blue(:,:,[1,2])=0;
    imagesc(blue);
        axis equal 
    axis off
    title('cyOFP')
    
    
    summary.mergeImage=rgbImage;
    
    
end



%% CLOSING
% summary=closeSummary(summary);


end  %%% END DUALGEVIMOVIES