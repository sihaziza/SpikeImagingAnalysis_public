%{
%%%%%%% INPUT %%%%%%%
This function assume 32-Channel ECoG recording along with behavioral
TTL input representing Baseline versus OddBall stimuli

Need to specify: Fs, epoch length (begin&end times) as a 2 element vector

Extract and normalize each epoch based on the 2s baseline prior to the
stimulus.

%%%%%%% OUTPUT %%%%%%%
Event-triggered epoch for baseline and oddball separatly

%%%%%%% MISC %%%%%%%
Uses sh_zscore function

%}

function [array,StimBand]=sh_StimEpoch(Data,TTL,marging,Fs)

% assume constant stimulation length
[on,~]=find(diff(TTL) == 1, 1,'first');
[off,~]=find(diff(TTL) == -1, 1,'first');

StimLength=max(round((off-on+1)/Fs,1),1);

% lgth=round((2*marging+StimLength)*Fs,0);
StimBand=[-marging marging+StimLength];
nCh=size(Data,2);

% find the 0 before 0-1 transition
[idx,~]=find(diff(TTL) == 1); 
n=length(idx);
fprintf('%d Cues detected\n',n)

% sort out each epoch for each channels
array=zeros(uint32((2*marging+StimLength)*Fs),n,nCh); 

for i=1:n
    try
    range=(idx(i)-marging*Fs:idx(i)+(StimLength+ marging)*Fs-1)';
    normRange=(1:marging*Fs)'; % normalized with 'marging'sec prior stimulus
    
    % if analogue time trace
        DataTemp=sh_zscore(Data(range,:),'range',normRange);
    % if binary data or no standardization required
%         DataTemp=Data(range,:);

%     stim(:,i)= ioData(range,1);
    array(:,i,:)=DataTemp;
    catch
        disp(strcat('fail @ index=',num2str(i)))
    end
end


end