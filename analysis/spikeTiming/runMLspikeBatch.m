function runMLspikeBatch(path)

options.skipCleanFile=true;

filelist = dir(fullfile(path, '**\*_clean.mat'));
if isempty(filelist)
    error('no extract output file detected in any subfolder')
end

for i=1:numel(filelist)
    filePath=fullfile(filelist(i).folder,filelist(i).name);
    savePath=strrep(filePath,'.mat','_spikes.mat');
    if exist(savePath,'file')
        if options.skipCleanFile % then do not replace/delete...
            answer=0;
        else
            answer=input('clean file already exist. delete/replace? [No-0/Yes-1]');
        end
        
        if answer
            disp('clean file already exist... replacing...')
            delete(savePath)
            getSpikesAllNeurons(filePath);
            %                     save(savePath,'output')
        else
            disp('clean file already exist... skipping...')
        end
    else
        getSpikesAllNeurons(filePath);
    end
end
end