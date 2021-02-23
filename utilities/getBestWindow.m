function [NEW_WINDOW]=getBestWindow(SIGNAL_LENGTH, TIME_WINDOW, SAMPLING_RATE)
% get the best window in sec for a given signal length to trunc it in
% approaximatly equal length (exept the last section for which the
% remainder will be add up)
% All input-output are scalars
% [NEW_WINDOW]=getBestWindow(SIGNAL_LENGTH, TIME_WINDOW, SAMPLING_RATE)

[Q,R]=getQuoRem(SIGNAL_LENGTH,TIME_WINDOW*SAMPLING_RATE);

rest=R/(TIME_WINDOW*SAMPLING_RATE);
if rest>=0.5
    NEW_WINDOW=TIME_WINDOW-rest/(Q-1);
else
    NEW_WINDOW=TIME_WINDOW+rest/(Q);
end

NEW_WINDOW=floor(NEW_WINDOW*SAMPLING_RATE)/SAMPLING_RATE;

fprintf('estimated best time window is %2.3f \n',NEW_WINDOW);

end