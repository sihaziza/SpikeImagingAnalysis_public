function [mapALL]=sh_TTLPowerMap(mov,TTL,freqRange,Fs,Nttl)

mov=double(mov);
mov=sh_Standardize(mov);

% find the 0 before 0-1 transition
[idxBehP,~]=find(diff(TTL) == 1); %Baseline
[idxBehN,~]=find(diff(TTL) == -1); %Baseline

n=length(idxBehP);

onT=(idxBehN(1)-idxBehP(1)+1);
deadT=(idxBehP(2)-idxBehN(1)+1);

fprintf('%d Cues detected\n',n)
fprintf('Stimulus %d s ON / %d s OFF \n',[round(onT/Fs) round(deadT/Fs)])

% sort out each epoch for each ECoG channels
% array=zeros(epL*Fs,n,nCh); % Baseline

map_pre=zeros(size(mov,1),size(mov,2),n);
map_stim=zeros(size(mov,1),size(mov,2),n);
map_post=zeros(size(mov,1),size(mov,2),n);
for i=1:Nttl
    range_pre=(idxBehP(i)-onT:idxBehP(i)-1)';
    range_stim=(idxBehP(i):idxBehN(i)-1)';
    range_post=(idxBehN(i):idxBehN(i)+onT)';

    [map_pre(:,:,i)]=sh_PowerMap(mov(:,:,range_pre),freqRange,Fs);
    [map_stim(:,:,i)]=sh_PowerMap(mov(:,:,range_stim),freqRange,Fs);
    [map_post(:,:,i)]=sh_PowerMap(mov(:,:,range_post),freqRange,Fs);
end

if size(mov,1)> size(mov,2)
    mapALL=[mean(map_pre,3) mean(map_stim,3) mean(map_post,3)]';
else
    mapALL=[mean(map_pre,3) mean(map_stim,3) mean(map_post,3)];
end
end