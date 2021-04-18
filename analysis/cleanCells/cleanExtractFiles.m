function cleanExtractFiles(path)

options.skipCleanFile=true;

filelist = dir(fullfile(path, '**\DemixingEXTRACT'));
if isempty(filelist)
    error('no extract output file detected in any subfolder')
else
    
    k=1;
    while k<numel(filelist)+1
        if length(filelist(k).name)>2
            mFile = dir(fullfile(filelist(k).folder,filelist(k).name, '*.mat'));
            for i=1:numel(mFile)
                filePath=fullfile(mFile(i).folder,mFile(i).name);
                savePath=strrep(filePath,'.mat','_clean.mat');
                if ~contains(filePath,'_clean.mat')
                    if exist(savePath,'file')
                          
                        %                     % could display a figure before taking a decision
                        %                     figH=figure('defaultaxesfontsize',16,'color','w','Name','summary of selected cells');
                        % nUnits=min(10,numel(cellList));
                        % for i=1:nUnits
                        %     subplot(10,10,[10*(i-1)+1 10*(i-1)+2])
                        %     imagesc(spatial(:,:,cellList(i)))
                        %     axis off
                        %     ylabel(num2str(cellList(i)))
                        %     subplot(10,10,[10*(i-1)+3 10*i])
                        %     plot(time,temporal(:,cellList(i)))
                        %     axis tight
                        % end
                        
                        if options.skipCleanFile % then do not replace/delete...
                            answer=0;
                        else
                            answer=input('clean file already exist. delete/replace? [No-0/Yes-1]');
                        end
                        
                        if answer
                            disp('clean file already exist... replacing...')
                            delete(savePath)
                            load(filePath,'output')
                            [cellID,figH]=extractCheckCellManual(output,'waitForUser',true);
                            output.cellID=cellID;
                            save(savePath,'output')
                            pathParts=strsplit(mFile(i).folder,filesep);
                            pathParts=strrep(pathParts{end},'_','-');
                            title(pathParts)
                            savePDF(figH,strrep(mFile(i).name,'.mat','_summaryCellFilters'),mFile(i).folder)
                            close all
                        else
                            disp('clean file already exist... skipping...')
                        end
                    else
                        load(filePath,'output')
                        [cellID,figH]=extractCheckCellManual(output,'waitForUser',true);
                        output.cellID=cellID;
                        save(savePath,'output')
                        savePDF(figH,strrep(mFile(i).name,'.mat','_summaryCellFilters'),mFile(i).folder)
                        close all
                    end
                else
                    disp('skipping clean file');
                end
            end
        end
        k=k+1;
    end
end