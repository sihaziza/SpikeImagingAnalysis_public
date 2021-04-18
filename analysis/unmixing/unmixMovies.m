function [unmixedMovie, summary] = unmixMovies(SCE, REF, Fs, varargin)
%% UNMIXMOVIES: unmixing the voltage movie from the source (mixed) movie
%
% [unmixedMovies,unmixMap, summary] = unmixMovies(SCE, REF, Fs)
% [unmixedMovies,unmixMap, summary] = unmixMovies(SCE, REF, Fs,Parameter,Value,...)
%
% INPUT:
%       SCE     - The source video / trace to be unmixed, can be variable loaded in
%                   memory or a pointer to a h5 file
%       REF     - The reference video / trace, or the h5 filename
%       Fs      - The acquisition sampling rate
%
% OUTPUT:
%       unmixedMovie    - The unmixed movie, variable or output filename
%       unmixMap        - The unmixing coefficient map
%       summary         - Extra outputs, validation and diagnostic
%
% OPTIONS SYNTAX
% unmixMovies(SCE, REF, Fs, 'options',options);
% unmixMovies(SCE, REF, Fs, 'EHB', false,'options',options);
% unmixMovies(SCE, REF, Fs, 'Method', 'RLR');
%   Unmixing methods:
%       - RLR: robust linear regression
%       - RLRg: compute the trace first then do robust linear regression
%       - EHB: For trace only, minimization of the energy within this heart beat band for signal unmixing
%
% AUTHOR: Simon Haziza
%
% HISTORY
% Created: 14 June, 2020, reorganized by Jizhou Li based on Simon's functions
% 
% TODO
%   - Other unmixing methods
%
%% OPTIONS specified below:

options.DataConditioning=true; % perform data conditioning (filtering and normalize)
options.CondRange=[0.01,5]; % The cutoff frequency for the butterworth filter used for conditioning
options.Normalize=true; % or called standardizing

options.computedframes = 'all'; % by default, use all frames to compute the unmixing coefficients
options.ChunkSize = 2000; % Chunking size for batching processing h5 files

% display control
options.plot=true;
options.saving = true;
options.verbose=1; % 0 - supress displaying state of execution

% voltage channel
options.voltagechannel = 1; % Green channel

% unmixing methods
options.Method = 'RLR'; 

%% VARIABLE CHECK
if nargin>=3
    options=getOptions(options,varargin);
end

%% SUMMARY PREPARATION
summary.funcname = 'unmix';
summary.input_options=options;
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;

%% CORE

if isa(SCE,'char')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% to do
%     [~,~,ext] = fileparts(SCE);
%     ext = ext(2:end);
%     if strcmpi(ext,'hdf5') || strcmpi(ext,'h5');
%         filetype = 'hdf5';
%         fileinfo_fixed = hdf5info(fixed, '/movie');
%         dims_fixed = fileinfo_fixed.Dataspace.size;
%         num_frame_fixed = dims_fixed(end);
%         
%         fileinfo_moving = hdf5info(fixed, '/movie');
%         dims_moving = fileinfo_moving.Dataspace.size;
%         num_frame_moving = dims_moving(end);
%         
%         if num_frame_fixed~=num_frame_moving
%             error('Number of frames are not equal');
%         end
%         
%         options.TemplateFrame=num_frame_fixed; % which frame to take as a template ? on default the last one.
%         fixed_frame =  h5read(fixed,'/movie',[1,1,options.TemplateFrame],[dims_fixed(1:end-1),1]);
%         moving_frame =  fliplr(h5read(moving,'/movie',[1,1,options.TemplateFrame],[dims_moving(1:end-1),1]));
%         
%         % output file names
%         [pathstr,fname,ext] = fileparts(fixed);
%         fixedV = fullfile(pathstr,[fname,'_',summary.funcname,ext]);
%         
%         [pathstr,fname,ext] = fileparts(moving);
%         registeredV = fullfile(pathstr,[fname,'_',summary.funcname,ext]);
%     end
else % array loaded in memory
    options.TrunkSize = [];
    
    filetype = 'mat';
    dims_SCE = size(SCE);
    dims_REF = size(REF);
    
end

if ~options.voltagechannel
    SCE0 = SCE;
    SCE = REF;
    REF = SCE0;
    clear SCE0;
end

% outputing some basic info about the processed movie
summary.filetype = filetype;
summary.computedframes=options.computedframes;
summary.dims_SCE=dims_SCE;
summary.dims_REF=dims_REF;
summary.framerate = Fs;
summary.method = options.Method;

fprintf('\n'); disp('Begin the unmixing');

%% 1. Data conditioning
[SCEnorm, REFnorm]=dataConditioning(SCE, REF, Fs);

%% 2. How many frames used for determining the unmixing coefficients
if class(options.computedframes)=='char'
        if strcmpi(options.computedframes,'all')
            options.computedframes = dims_SCE(3);
            SCE4unmix = SCEnorm; % use for unmixing
            REF4unmix = REF;
        end
    else
        if isnumeric(options.computedframes)
            SCE4unmix = SCEnorm(:,:,1:options.computedframes);
            REF4unmix = REFnorm(:,:,1:options.computedframes);
        end
end

[mx, my, mz] = size(SCE4unmix);

%% 3. Determine the heart beat frequency, in Hz
fh = findHBpeak(SCE,Fs);

%% 4. Different methods
funReshape = @(x) reshape(x,mx*my,mz,1);
funTrace = @(x) squeeze(nansum(nansum(x,1),2));
funRLR = @(x,y) robustfit(double(x),double(y));

switch options.Method
    case 'RLRg'
        SCEt = funTrace(SCE4unmix);
        REFt = funTrace(REF4unmix);
        pr=funRLR(REFt, SCEt); 
        unmixMap=pr(2); 
    case 'RLR'
        mSCE2d = funReshape(SCE4unmix);
        mREF2d = funReshape(REF4unmix);
        unmixMap=zeros(mx*my,1);
        parfor ri = 1:size(mSCE2d,1)
            TX = mREF2d(ri,:);
            TY = mSCE2d(ri,:);
            pr=funRLR(TX,TY);
            unmixMap(ri)=max(pr(2),0);
            [~, MSGID] = lastwarn();
            warning('off', MSGID);
        end
        unmixMap = reshape(unmixMap, mx, my);
    case 'EHB'
        mSCE2d = funReshape(SCE4unmix);
        mREF2d = funReshape(REF4unmix);
        unmixMap=zeros(mx*my,1);
        parfor ri = 1:size(mSCE2d,1)
            TX = mREF2d(ri,:);
            TY = mSCE2d(ri,:);
            unmixMap(ri) =EHBumx(TY, TX, Fs, fh);
            [~, MSGID] = lastwarn();
            warning('off', MSGID);
        end
        unmixMap = reshape(unmixMap, mx, my);
end

%% 5. Apply to the original movies
unmixedMovie=SCEnorm-unmixMap.*REFnorm;

summary.unmixMap = unmixMap;

if options.plot
    %% Unmixed results
    imshow(unmixedMovie(:,:,1),[]); title('Unmixed frame');
    drawnow
end

disp('Finished');

%% VALIDATION
%%
summary.execution_duration=toc(summary.execution_duration);

end

function disp(string) %overloading disp for this function
    fprintf('%s unmixing: %s\n', datetime('now'),string);
end

function [UMX] = EHBumx(SCE, REF, Fs, Fh)
% Minimization of the energy within this heart beat band for signal unmixing
%work on a time trace only
%-----------------------------------------------------------
ME=0;
%check for column vector
s=size(SCE);
if s(2)>s(1)
    SCE=SCE';
    REF=REF';
end

funNorm = @(x) (x - nanmean(x))./(nanstd(x));
SCE=funNorm(SCE);
REF=funNorm(REF);

alpha=(0:0.01:1.5)';
x=SCE*ones(size(alpha))';
y=REF*alpha';

try
    E=bandpower(x-y,Fs,[Fh-1.5 Fh+1.5]);
catch
    ME=1;
end

if ME
    UMX=nan;
else
    [~,idx]=min(E);
    UMX=alpha(idx);
end

end

function [mSCEnorm,mREFnorm] = dataConditioning(mSCE, mREF, Fs, Wn)
% INPUT: source trace 'sce' to be unmixed from the reference trace 'ref'.
% Fs is the acquisition sampling rate

% OUTPUT: source and reference trace filtered and normalized, unmixed trace
% and unmixing coefficient

if nargin < 4
    Wn = 0.5;
end

[mx, my, mz] = size(mSCE);

% Data conditioning: filtering & scaling
[b,a]=butter(4,Wn/(0.5*Fs),'high');

funReshape = @(x) reshape(x,mx*my,mz,1);
funNorm = @(x) (x - nanmean(x))./(nanstd(x));

mSCE2d = funReshape(mSCE);
mREF2d = funReshape(mREF);

parfor ri = 1:size(mSCE2d,1)   
    TX = double(mREF2d(ri,:));
    TY = double(mSCE2d(ri,:));
    
    TX=filtfilt(b,a,TX);
    TY=filtfilt(b,a,TY);
    
    TX=funNorm(TX);
    TY=funNorm(TY);
    
    mREF2d(ri,:)=TX;
    mSCE2d(ri,:)=TY;
end    
mSCEnorm=reshape(mSCE2d, mx, my, mz);
mREFnorm=reshape(mREF2d, mx, my, mz);

end 

function fh = findHBpeak(wave,Fs,varargin)
% FindHBpeak
% Find heart beat frequency, in Hz.
%
% SYNTAX:
% [Fhemo]=sh_FindHBpeak(wave,Fs);
% [Fhemo]=sh_FindHBpeak(wave,Fs,'FFTwin',10,'verbose',0); increase windowing to 10 sec + no display
%
% DESCRIPTION
% Automaticaly detect and quantify the mouse heart beat frequency from the power spectrum density
% Only for 1D time trace
%
% HELP
% No issue highlighted yet, so help yourself!;-)
%
% HISTORY
% - 2019-11-30 - created by Simon Haziza, Stanford
%
% ISSUES
% #1 - it's dope!
%
% TODO
% #1 - easy peasy!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the default optional parameters

% get the trace
wave=squeeze(nansum(nansum(wave,1),2));

verbose = 1; % output dialogue by default
FFTwin = 2; % 2 second windowing by default

win=FFTwin*Fs;
ovl=round(win*0.8,0);
nfft=10*Fs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check some basic requirements of the data

if nargin < 2
    error ('Input should be: a time trace + its sampling frequency Fs');
end

if length (size (wave)) > 2
    error ('This function only work with 1-D data (time trace).');
end

if any (any (isnan (wave)))
    error ('Input data contains NaN''s.');
end

if numel(wave)<win
    error('The data length is smaller than the window of 2 seconds, try to increase the frame number');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the optional parameters

if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        if ~ischar (varargin{i})
            error (['Unknown type of optional parameter name (parameter' ...
                ' names must be strings).']);
        end
        % change the value of parameter
        switch lower (varargin{i})
            case 'fftwin'
                win = lower (varargin{i+1})*Fs;
            case 'verbose'
                verb = varargin{i+1};
                if strcmpi (verb, 'off'), verbose = 0; end
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized parameter: ''' varargin{i} '''']);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OK, let's do some computation now!

[x,f]=pwelch(wave,win,ovl,nfft,Fs,'onesided');

[pks,locs,wdth,prom] =findpeaks(10*log10(x(9*nfft/Fs:13*nfft/Fs)),f(9*nfft/Fs:13*nfft/Fs),'SortStr','descend','NPeaks',1,'Annotate','extents');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nice, it's done! Let's output the data.
Fhemo.Peak=pks;
Fhemo.Location=locs;
Fhemo.Width=wdth;
Fhemo.Prominence=prom;

if (verbose==1)
    fprintf('Heart beat in Source Channel @ %2.1f Hz \n',locs)
end

fh=Fhemo.Location;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THIS IS THE END %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end


% unmixMovies.m
% Displaying unmixMovies.m.