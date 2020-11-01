
function savePDF(figureHandle,name,directory)

if isempty(directory)
    error('Sorry.. dont know where to save it...');
else
    fullname=fullfile(directory,name);
    
    if isfile(fullname)
        % File exists.
        delete(fullname);
    else
        % File does not exist.
        orient(figureHandle,'landscape');
        print(figureHandle,fullname,'-dpdf','-fillpage');
%         close(figureHandle);
    end
end
end
