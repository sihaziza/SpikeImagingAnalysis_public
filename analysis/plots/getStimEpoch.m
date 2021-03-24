function [output]=getStimEpoch(Data,TTL,Fs,varargin)
% [output]=getStimEpoch(Data,TTL,Fs,'baselinePrePost',2,'getShuffle',true)
% output arrays : time x trials x channels/pixels
%
% OPTIONS:
% options.baselinePrePost=1; % 1sec baseline
% options.getShuffle=false;
%
% OUTPUT:
% output.arrayRaw=arrayRaw;
% output.arrayShuffle=arrayShuffle;
% output.stimBand=stimBand;
% output.indexTTLraw=idx_raw;
% output.indexTTLshuffle=idx_shuffle;
% output.options=options;
%% DEFAULT OPTIONS
options.baselinePrePost=1; % 1sec baseline
options.getShuffle=false;

%% UPDATE OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end
%%
% assume constant stimulation length
[on,~]=find(diff(TTL) == 1, 1,'first');
[off,~]=find(diff(TTL) == -1, 1,'first');

% find stimulus length
marging=options.baselinePrePost;
stimLength=max(round((off-on+1)/Fs,1),1);
stimBand=[-marging marging+stimLength];

nChannel=size(Data,2);

% find the 0 before 0-1 transition
[idx_raw,~]=find(diff(TTL) == 1);
if options.getShuffle
    temp=1+2*Fs:stimLength*Fs:length(TTL)-2*Fs; %to avoid epoch assignment failure
    temp=temp(randperm(numel(temp)));
    idx_shuffle = sort(temp(1:numel(idx_raw)),'ascend')';
end
plot([idx_raw idx_shuffle],'o')
nStim=length(idx_raw);

fprintf('%d Cues detected\n',nStim)

% sort out each epoch for each channels
arrayRaw=zeros((2*marging+stimLength)*Fs,nStim,nChannel);
arrayShuffle=zeros((2*marging+stimLength)*Fs,nStim,nChannel);

disp('Assigning epoch on Raw data')
for i=1:nStim
    try
        range=(idx_raw(i)-marging*Fs:idx_raw(i)+(stimLength+ marging)*Fs-1)';
        normRange=(1:marging*Fs)'; % normalized with data prior stimulus
        DataTemp=sh_zscore(Data(range,:),'range',normRange);
        arrayRaw(:,i,:)=DataTemp;
    catch
        disp(strcat('fail @ index=',num2str(i)))
    end
end

if options.getShuffle
    disp('Assigning epoch on Shuffled data')
    for i=1:nStim
        try
            range=(idx_shuffle(i)-marging*Fs:idx_shuffle(i)+(stimLength+ marging)*Fs-1)';
            normRange=(1:marging*Fs)'; % normalized with data prior stimulus
            DataTemp=sh_zscore(Data(range,:),'range',normRange);
            arrayShuffle(:,i,:)=DataTemp;
        catch
            disp(strcat('fail @ index=',num2str(i)))
        end
    end
end

output.arrayRaw=arrayRaw;
output.arrayShuffle=arrayShuffle;
output.stimBand=stimBand;
output.indexTTLraw=idx_raw;
output.indexTTLshuffle=idx_shuffle;
output.options=options;

end