% simutaneouly display two sliceviewer, to compare before and after

function compare(before, after)

% before = zscore(before);
% after = zscore(after);

[nx,ny,nz] = size(before);
% show sliceviewer
gca_before=figure('Name','Before');

% sbefore = sliceViewer(before,'Colormap',jet);
% colorbar;
sbefore = sliceViewer(before);
hz1 = zoom;
hz2 = pan;


gca_after=figure('Name','After');
safter = sliceViewer(after);
% colorbar;
hz3 = zoom;
hz4 = pan;

hz1.ActionPostCallback = @(src,evt)zoomTheOther(src,evt,gca_after);
% hz1.Enable = 'on';
hz2.ActionPostCallback = @(src,evt)panTheOther(src,evt,gca_after);
% hz2.Enable = 'on';
hz3.ActionPostCallback = @(src,evt)zoomTheOther(src,evt,gca_before);
% hz3.Enable = 'on';
hz4.ActionPostCallback = @(src,evt)panTheOther(src,evt,gca_before);
% hz4.Enable = 'on';

%% traces
figure('Name','Traces (z-scored)');
Ftrace = gca;

current = round(nz/2);

% positioning the figures
movegui(gca_before,'southeast')
movegui(gca_after,'northeast')
movegui(Ftrace,'center')
%% events

app=Controller(sbefore,safter,Ftrace,before,after);

drawTrace(Ftrace,app.traceX, app.traceY,current);

end



function zoomTheOther(src,evt,safter)


L = get(gca,{'xlim','ylim'});  % Get axes limits.

set(safter.CurrentAxes,{'xlim','ylim'},L);
end

function panTheOther(src,evt,safter)


L = get(gca,{'xlim','ylim'});  % Get axes limits.

set(safter.CurrentAxes,{'xlim','ylim'},L);
end


