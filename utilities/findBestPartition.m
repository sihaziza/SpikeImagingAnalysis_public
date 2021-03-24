function [optiVect]=findBestPartition(FULL_DIM,DESIRED_CHUNK_SIZE)
% [optiVect]=findBestPartition(FULL_DIM,DESIRED_PART)
% Find the best, harmonious chunking (spatial or temporal).
% FULL_DIM: movie length, or 1 frame dimension
% DESIRED_CHUNK_SIZE: size of the chunk (obviously, should be less than FULL_DIM)
% options.verbose=true;

if FULL_DIM<=DESIRED_CHUNK_SIZE
    error('DESIRED_CHUNK_SIZE can NOT be larger than FULL_DIM.\n')
end

[NEW_WINDOW]=getBestWindow(FULL_DIM, DESIRED_CHUNK_SIZE, 1);

[Q,~] = getQuoRem(FULL_DIM,NEW_WINDOW);

if Q<2
    cprintf('yellow','The desired chunk size does not provide balanced chunking.\n')
    cprintf('yellow','Re-allocation chunk size to get at least 2 chunks.\n')
    Q=2; % to avoid inf value. if user wants chunking than
end

optiVect=round(linspace(1,FULL_DIM,Q+1));

CHUNK_SIZE=mean(diff(optiVect));

% fprintf('average chunk size is %3.3f \n',CHUNK_SIZE);
end