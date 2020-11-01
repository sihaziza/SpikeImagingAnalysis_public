function [frequency,pow,options]=plotPSD(data,varargin)

% EXAMPLE: [~,options]=plotPSD(data,'FrameRate',200,'FreqBand',[0.1 100])

% DEFAULT Options
options.VerboseMessage=true;
options.VerboseFigure=true;
options.Savefig=false;
options.FrameRate=1000;
options.FreqBand=[0.1 min(options.FrameRate/2,30)];
options.Window=5;
options.figureHandle=[];
options.scaleAxis='linear';

% USER-DEFINED INPUT OPTIONS
if nargin>1
    options=getOptions(options,varargin);
end

Fs=round(options.FrameRate);
win=options.Window*Fs;
ovl=round(0.9*win);
nfft=100*Fs;

[xg,frequency] =pwelch(data-median(data),win,ovl,nfft,Fs,'onesided');
pow=10*log10(xg);

% k=find(frequency>=band(2),1,'first');
% pow=pow-min(pow(1:k,:),[],1); % to norm all to same noise floor

if options.VerboseFigure
    if isempty(options.figureHandle)
        figure('Name','Power Spectrum Density')
    else
        figure(options.figureHandle)
    end
    switch options.scaleAxis
        case 'linear'
            % plot(log10(frequency),movmin(pow,round(k)/10));
            % band=[0 2];
            % plot(log10(frequency),pow,'linewidth',2)
            trace=pow;%-movmin(pow,20*Nfft/Fs);
            plot(frequency,trace,'linewidth',1.5)
            xlim(options.FreqBand)
            ylabel('Power Spectrum Density')
            xlabel('Frequency (Hz)')
%             title('pWelch-estimated Power Spectral Density')
        case 'log'
            % band=[0 2];
            % plot(log10(frequency),pow,'linewidth',2)
%             options.FreqBand=[-2 log10(Fs/2)];
            trace=pow;%-movmin(pow,20*Nfft/Fs);
            plot(log10(frequency),trace,'linewidth',1.5)
            xlim(options.FreqBand)
            ylabel('Power Spectrum Density')
            xlabel('Frequency (Hz)')
            title('pWelch-estimated Power Spectral Density')
            
        otherwise
            warning('Scale axis not recognize. Only "linear" or "log" accepted.')
    end
end
end