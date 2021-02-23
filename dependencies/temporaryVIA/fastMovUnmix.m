function [umxMovie,coeffMap,hemoPeak,summary]=fastMovUnmix(sourceMovie,refMovie,fps,varargin)
% HELP FASTMOVUNMIX.M
% Fast unmixing based on pixel-wise robust linear regression and a global, one-time hemodynamics detection and FiltFiltM filtering. 
% SYNTAX
%[umxMoviecoeffMap,summary]= fastMovUnmix(sourceMovie) - use 2, etc.
%[umxMoviecoeffMap,summary]= fastMovUnmix(sourceMovie,refMovie) - use 3, etc.
%[umxMoviecoeffMap,summary]= fastMovUnmix(sourceMovie,refMovie,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[umxMoviecoeffMap,summary]= fastMovUnmix(sourceMovie,refMovie,'options',options) - passing options as a structure.
%
% INPUTS:
% - sourceMovie - ...
% - refMovie - ...
%
% OUTPUTS:
% - umxMovie - ...
% - coeffMap - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 17-Nov-2020 14:05:44 - created by Radek Chrapkiewicz
% (radekch@stanford.edu) as a modification of Simon's functions. 

%% OPTIONS (type 'help getOptions' for details)
options=struct; % add your options below 
options.hemoPeak=[]; % if provided, no hemodynamics detection will occure;
options.preBandpassed=false; % just to avoid additional bandpassing step;
options.heartbeatRange=[5,12]; % for finding the heart beat at the beginning only
options.hemoBand=3; % band widht around hemodynamics peak in Hz +/-options.hemoBand=/2
options.conditioning=true;
options.highpassCutoff=0.1;
% options.method='rlr';
% options.type='local';

% Control display
options.verbose=true;
options.plot=true;



%% VARIABLE CHECK 
if nargin>=4
    options=getOptions(options,varargin); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
summary=initSummary(options);

%% CORE

%% 1. Finding hemodynamics if not provided 
if isempty(options.hemoPeak)    
    refGlobTrace=pointProjection(refMovie);
    refGlobTraceFilt=bandpass(refGlobTrace,options.heartbeatRange,fps);
    [Fhemo,optsFindHB]=FindHBpeak(refGlobTraceFilt,'FrameRate',fps);
    summary.Fhemo=Fhemo;
    summary.optionsHemo=optsFindHB;
    summary.refGlobTrace=refGlobTrace;   
    hemoPeak=Fhemo.Location;
    disps(sprintf('Found hear beat peak at %.2f Hz',hemoPeak));
else
    hemoPeak=options.hemoPeak;
end

%% 2. Conditioning movie
if options.conditioning
    refMovie=highpassMovie(refMovie,options.highpassCutoff,fps);
    sourceMovie=highpassMovie(sourceMovie,options.highpassCutoff,fps);
    refMovie=zscoreMovie(refMovie);
    sourceMovie=zscoreMovie(sourceMovie); 
end


%% 3. Bandpassing movie 
if ~options.preBandpassed
    hemoBands=hemoPeak+options.hemoBand*[-0.5,0.5];
    summary.hemoBands=hemoBands;
    sourceMovieBp=bandpassMovie(sourceMovie,hemoBands,fps);
    refMovieBp=bandpassMovie(refMovie,hemoBands,fps);
else
    sourceMovieBp=sourceMovie;
    refMovieBp=refMovie;
end

%% 4. Main loop

coeffMap=zeros(size(sourceMovie,1),size(sourceMovie,2));

disps('Entering the actual unmixing loop:');
fprintf('Progress: ');
for iRow=1:size(sourceMovie,1)
    progress(iRow,size(sourceMovie,1))
    parfor iCol=1:size(refMovieBp,2)
        Iv=squeeze(sourceMovieBp(iRow,iCol,:));
        Ir=squeeze(refMovieBp(iRow,iCol,:));
        if (sum(Iv)==0) || (sum(Ir)==0)
            coeffMap(iRow,iCol)=0;
        else
            p=robustfit(Ir,Iv);
            coeffMap(iRow,iCol)=p(2);
        end
    end
end
fprintf('\n');

%% Checking some example pixels unmixing 
iRow=randi(size(sourceMovie,1))
iCol=randi(size(refMovieBp,2))
Iv=squeeze(sourceMovieBp(iRow,iCol,:));
Ir=squeeze(refMovieBp(iRow,iCol,:));
IvRaw=squeeze(sourceMovie(iRow,iCol,:));
IrRaw=squeeze(refMovie(iRow,iCol,:));
figure
subplot(3,2,1)
plot(Iv);
hold on
plot(Ir);
hold off
xlim([500,600])
subplot(3,2,2)
plot(Ir,Iv,'.')
title(corr(Ir,Iv))

subplot(3,2,3)
plot(IvRaw);
hold on
plot(IrRaw);
Iumx=IvRaw-coeffMap(iRow,iCol)*IrRaw;
plot(Iumx,'k')
hold off


xlim([500,3000])
subplot(3,2,4)
plot(IrRaw,IvRaw,'.')
title(corr(Ir,Iv))

subplot(3,2,5)
plotPSD(IvRaw,fps);
hold on
plotPSD(IrRaw,fps);
plotPSD(Iumx,fps);
hold off
legend('Before unmixing','reference','after unmixng')

subplot(3,2,6)
plot(IrRaw,Iumx,'.')
title(corr(IrRaw,Iumx))

%%
figure
imshow(coeffMap,[])
colorbar



%% 5. Calculating the unmixed movie

disps('Calculating the unmixed movie')
umxMovie=sourceMovie-coeffMap.*refMovie;

%%

figure
subplot(2,1,1)

plotPSD(sourceMovie,fps);
hold on
plotPSD(refMovie,fps);

plotPSD(umxMovie,fps);
hold off
legend('Green','Reference','Voltage')




%% CLOSING
summary=closeSummary(summary);
disps(sprintf('Unmixing finished in %.1f seconds',summary.executionDuration));

end  %%% END FASTMOVUNMIX

function progress(iteration,maxiteration)
    progperc=100*iteration/maxiteration;
    if rem(progperc,5)==0
        fprintf('%.0f%% ',progperc)
    end
end