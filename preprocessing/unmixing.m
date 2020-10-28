function [unmixSource,unmixCoeff,options]=unmixing(sourceMovie,referenceMovie,allPaths,varargin)
% GOAL: Unmix two movies using various method.
%
% INPUT
%     - source: source trace to be unmixed from the reference trace 'ref'.
%     - reference:
%     - options (as input struct or variable arguments):
%         * FrameRate: sampling frequency of time trace. (default: 1kHz)
%         * HeartbeatRange: a 2-element-vector. (default: awake > 9-13Hz
%         * Verbose: command window output
% OUTPUT
%     - unmixsource: unmixed source signal
%     - umxcoeff: unmixing coefficient used to correct signal from reference
%     - options: all options used in the function
%
% EXAMPLE 1
%     [umx,a,options]=sh_HDMumx(V,R,[]); % uses default options
%
% EXAMPLE 2
%     options.CorrectionMethods='ratiometric';
%     [umx,a,options]=unmixing1D(V,R,options);
%
% EXAMPLE 3
%     [umx,a,options]=unmixing1D(V,R,[]); % uses default options
%
% DEPENDENCIES
% if ICA method is used > https://research.ics.aalto.fi/ica/fastica/
%
% CONTACT
% StanfordVoltageGroup@gmail.com
%
% HISTORY
% Created 2020-06-01 by Stanford Voltage Group, Schnitzer Lab

%% CHECK VARIABLES FORMATING
if nargin<2
    error('This function requires at least 2 inputs (source & reference)');
end

if ~istensor(sourceMovie)||~istensor(referenceMovie)
    error('This function requires 2 3D-matrix inputs (source & reference)');
end

if mod(nargin-3,2)
    error('Variable input arguments work as Name-Value pairs');
end

%% DEFAULT INPUT OPTIONS
[options]=defaultOptionsUnmixing;

%% UPDATE OPTIONS
if nargin>3
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
[summaryUnmixing]=outputSummaryUnmixing(options);

if options.diary
    diary(fullfile(allPaths.pathDiagUnmixing,options.diary_name));
end


%% FUNCTION CORE
disps('Running Unmixing ...');
fps=options.fps;
diagnosticFolder=allPaths.pathDiagUnmixing;
options.diagnosticFolder=diagnosticFolder;

if options.conditioning
    tic; cprintf('yellow','Performing Data Conditioning (Filtering & Scaling).\n')
    [sourceMovie,referenceMovie,optsDC]=conditioning3D(sourceMovie, referenceMovie,...
        'FrameRate',fps);toc;
    options.optionsConditioning=optsDC;
end

method=options.method;
type=options.type;
mState=options.mouseState;
cprintf('yellow','[%s] unmixing with method [%s].\n',type,method);

% Find Hemo peak
disps('finding hemodynamic peak')
temp=pointProjection(sourceMovie);
[Fhemo,optsFindHB]=FindHBpeak(temp,'FrameRate',fps);
options.FreqHemo=Fhemo.Location;
options.optionsHemo=optsFindHB;

if options.savePlot
    if isempty(diagnosticFolder)
        warning('Figure not saved. Indicate saving path.\n')
    else
        disps('saving figures')
        export_figure(optsFindHB.figureHandle,'Heart beat location',diagnosticFolder);
        close;
    end
end

if strcmpi(type,'global')
    
    tsource = pointProjection(sourceMovie);
    tref = pointProjection(referenceMovie);
    % figure(1); plot([tsource tref])
    
    % Run Unmixing
    [~,unmixCoeff,unmixOptions]=unmixing1D(tsource,tref,...
        'UnmixingMethod',method,'FrameRate',fps,'MouseState',mState,...
        'VerboseMessage',true,'VerboseFigure',false);
    % Update the output 3D-matrix
    unmixSource=sourceMovie-unmixCoeff.*referenceMovie;
    
elseif strcmpi(type,'local')
    
    [mx, my, mz] = size(sourceMovie);
    UMX=zeros(mx*my,1);
    
    source2d = reshape(sourceMovie,mx*my,mz,1);
    ref2d = reshape(referenceMovie,mx*my,mz,1);
    
    FreqHemo=options.FreqHemo;
    
    [~,~,unmixOptions]=unmixing1D(source2d(round(mx*my/2),:)',ref2d(round(mx*my/2),:)',...
        'UnmixingMethod',method,'FrameRate',fps,'freqHemo',FreqHemo,'MouseState',mState,...
        'VerboseMessage',false,'VerboseFigure',false);
    
    disps('Starting pixel-wise unmixing...')
    parfor ri = 1:size(source2d,1)
        try
            tsce = source2d(ri,:)';
            trefer = ref2d(ri,:)';
            % Run Unmixing
            [~,UMX(ri),~]=unmixing1D(tsce,trefer,...
                'UnmixingMethod',method,'FrameRate',fps,'freqHemo',FreqHemo,'MouseState',mState,...
                'VerboseMessage',false,'VerboseFigure',false);
        catch
        end
    end
    
    unmixCoeff = reshape(UMX, mx, my);
    unmixCoeff(unmixCoeff<0)=0; unmixCoeff(unmixCoeff>1)=1;
    unmixSource=sourceMovie-unmixCoeff.*referenceMovie;
    
    disps(sprintf('Average Unmixing coefficient is @ %2.3f \n',mean(unmixCoeff(:))))
    
    h=figure();
    imshow(unmixCoeff,[]);
    export_figure(h,'Unmixing Matrix',diagnosticFolder);
    close;
else
    error('Unmixing type not recognized');
end

summaryUnmixing.umxOptions=unmixOptions;
summaryUnmixing.executionDuration=toc(summaryUnmixing.executionDuration);
disps('saving summary output')
save_summary(summaryUnmixing,diagnosticFolder);

metadata.fps=50; % fps to be trasnfered properly 
disps('Generating mp4 unmixed movie')
renderMovie(unmixSource,fullfile(diagnosticFolder,'movie'),metadata.fps);
close;

disps('Saving h5 outputs')
h5PathV=strcat(erase(allPaths.h5PathG,'.h5'),[options.suffix '.h5']);
h5save(h5PathV,unmixSource,'mov');
h5PathCoeff=fullfile(diagnosticFolder,'umxCoeff.h5');
h5save(h5PathCoeff, unmixCoeff,'umx');

%% PLOT RELEVANT METRICS TO ASSESS THE QUALITY OF THE OUTPUT

if options.plot
    disps('plotting figures')
    tumx=pointProjection(unmixSource);
    tref=pointProjection(referenceMovie);
    tsource=pointProjection(sourceMovie);
    
    name=strcat(type,'_unmixing_method_',method);
    h=figure('Name',strcat('Output Summary for',name));
    subplot(221)
    plot(normalize(tref(1:10:end,end)),normalize(tsource(1:10:end,1)),'+k')
    hold on
    plot(normalize(tref(1:10:end,end)),normalize(tumx(1:10:end,1)),'+r')
    hold off
    title('Correlation plot before-after unmxing')
    xlabel('Reference')
    ylabel('Voltage')
    
    subplot(222)
    plotPSD([tref tsource tumx],'FrameRate',fps,'figureHandle',h);
    title('pWelch PSD plot')
    xlabel('Frequency (Hz)')
    b=ylabel('Power Density dB/$$\sqrt{Hz}$$');
    set(b,'Interpreter','latex')

    subplot(212)
    t=linspace(0,(length(sourceMovie)-1)/fps,length(sourceMovie))';
    plot(t,normalize(tref),t,normalize(tsource),t,normalize(tumx))
    title('Time Trace for all signals')
    xlim([t(end-5*fps) t(end)])
    xlabel('Time (s)')
    ylabel('z-score')
    
    if options.savePlot
        if isempty(diagnosticFolder)
            warning('Figure not saved. Indicate saving path.\n')
        else
            disps('saving figures')
            export_figure(h,'Unmixing Figure',diagnosticFolder);
            close;
        end
    end
    
end

if options.diary
    diary off
end
    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s unmixing: %s\n', datetime('now'),string);
        end
    end
end
