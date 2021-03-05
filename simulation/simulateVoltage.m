function [output]=simulateVoltage(varargin)

% basic options
options.movieSize=[200 200 10000];
options.numCells=10;
options.polarity='dual';
options.minmaxCellRadius=[10 15];
options.minCellSpacing=50;
options.eventRate=10;
options.eventTau=5;
options.eventSNR=5;
options.noiseSTD=1;

% options to make things more complicated
options.addNeuropil=[];
options.addPhotbleaching=[];
options.addMotion=[];

[M,F_mat,T_mat,event_times, cents] = simulate_data(...
    options.movieSize,...
    options.numCells,...
    options.minmaxCellRadius,...
    options.minCellSpacing,...
    options.eventRate,...
    options.eventTau,...
    options.eventSNR,...
    options.noiseSTD,...
    options.addNeuropil,...
options.polarity);

% implay(M)
output.movie=M;
output.spatialFilters=F_mat;
output.tempFilters=T_mat;
output.eventTimes=event_times;
output.cents=cents;
end