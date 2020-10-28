function drawTrace(Ftrace,traceX, traceY,current)

plot(Ftrace,[traceX' traceY']);
hold on;
Ftrace.NextPlot = 'add';
maxL = max([traceX(:); traceY(:)]);
minL = min([traceX(:); traceY(:)]);
plot(Ftrace,[current current],[minL maxL],'g');

xlabel('Frame #');
title('Traces (z-scored)');
% difference
% plot(Ftrace,traceX-traceY);
Ftrace.NextPlot = 'add';

legend(Ftrace,'Before','After','Current Frame');
set(gcf,'color','w');
hold off;
Ftrace.NextPlot = 'replace';
end