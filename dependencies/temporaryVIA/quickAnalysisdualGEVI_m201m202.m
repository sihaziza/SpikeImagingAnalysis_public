%%
mainFolder='F:\GEVI_Wave\Preprocessed\Spontaneous';
mouse={'m201'};

% date='20200416';
for iMouse=1:length(mouse)
    h5PathMain=fullfile(mainFolder,mouse{iMouse});
    % shoudl be F drive...  h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual\m81\20200416');
    folderDate=dir(fullfile(h5PathMain,'2021*')); % G always comes before R
    
    for iDate=1:length(folderDate)
        date=folderDate(iDate).name;
        folder=dir(fullfile(h5PathMain,date,'meas*')); % G always comes before R
        
        folderName=[];k=1;
        for iFolder=1:length(folder)
            if strlength(folder(iFolder).name)==6
                folderName{k}=folder(iFolder).name;
                k=k+1;
            end
        end
        
        for iFolder=2%:length(folderName)
            
            
            %                 h5Path=fullfile(h5PathMain,date,folderName{iFolder});
            h5Path='F:\Calibration\Preprocessed\Noise\FluoSlide\20210118\meas00';
            temp=dir(fullfile(h5Path,'*.h5'));
            filePathG=fullfile(h5Path,temp(1,1).name);
            filePathR=fullfile(h5Path,temp(2,1).name);
            meta=h5info(filePathG);
            disp('h5 file detected')
            dataset=strcat(meta.Name,meta.Datasets.Name);
            dim=meta.Datasets.Dataspace.Size;
            mx=dim(1);my=dim(2);mz=dim(3);
            
            movieGreen=h5read(filePathG,dataset,[1 1 1],[mx my mz]);
            movieRed=h5read(filePathR,dataset,[1 1 1],[mx my mz]); %[1 1 1],[mx my mz]);
            Fs=98;
            %%
            iImage=5;
            imshow([movieGreen(:,:,iImage) movieRed(:,:,iImage);...
                movieGreen(:,:,iImage+2) movieRed(:,:,iImage+2)],[])
            %%
            % if 3 colors
            [voltG,voltR,reference,~]=dualGeviMovies(movieGreen,movieRed);
            
%             if 2 color
voltG=movieGreen;
voltR=movieRed;
%% Binning
G1=voltG;
R1=voltR;
G2=imresize(G1,1/2);
R2=imresize(R1,1/2);
G4=imresize(G1,1/4);
R4=imresize(R1,1/4);
G8=imresize(G1,1/8);
R8=imresize(R1,1/8);
G16=imresize(G1,1/16);
R16=imresize(R1,1/16);
G32=imresize(G1,1/32);
R32=imresize(R1,1/32);
            %%
            tG=squeeze(mean(G16,[1 2]));
            tR=squeeze(mean(R16,[1 2]));
            tRef=squeeze(mean(reference,[1 2]));
            M=[tG tR tRef];
            plot(zscore(M))
            %%
            G=G1;
            R=R1;
            dff=@(x) (x-mean(x))./mean(x)*100;
            df=@(x) (x-mean(x));
            
            pixX=1;
            pixY=1;
            tG=squeeze(G(pixX,pixY,:));
            tR=squeeze(R(pixX,pixY,:));
%             tRef=squeeze(reference(pixX,pixY,:));
            
            M=([tG tR]);
            time=getTime(M,Fs);
            nTrace=size(M,2);
            figure(1)
            plot(time,dff(M))
            ylabel('DFF (%)')
            xlabel('Time (s)')
            legend({'Ace','Varnam'})
            title('1 pixel time trace Green and Red using 20% blue LED on orange fluo slide')
            
            % p=robustfit(M(:,3),M(:,2));
            % plot(M(:,1)-p(2)*M(:,3))
            Mz=zscore(M);
            figure(2)
            plot(Mz(:,1),Mz(:,2))
%             legend({'Ace','Varnam'})
            title('1 pixel channels cross-correlation')
            ylabel('Red Signal')
            xlabel('Green signals')
            
            % plotPSD(M,)
            %%
            trace=double(dff(M));
            BW=[0.5 Fs/2];
               plotPSD(trace/100,'FrameRate',Fs,'FreqBand',BW,'Window',2);
            title('PSD of dff')
            ylim([-90 -40])
            %%
            h=figure(1);
            subplot(1,3,1)
            plotPSD(trace/100,'FrameRate',Fs,'FreqBand',BW,'Window',2);
            title('PSD of dff')
            subplot(1,3,2)
            plotPSD(zscore(M(1:1000,:)),'FrameRate',Fs,'FreqBand',BW,'Window',1,'figureHandle',h);
            subplot(1,3,3)
            plotPSD(zscore(M(end-1000:end,:)),'FrameRate',Fs,'FreqBand',BW,'Window',1,'figureHandle',h);
            
            %%
            Mfilt=sh_bpFilter(double(M), [4 8], Fs);
            plot(zscore(Mfilt)+linspace(1,10,3))
            %
            % spectrogram(M(:,3))
            % cwt(double(M(:,3)),Fs)
            %,window,noverlap,nfft)
            
            % Load locomotion / plot
        end
    end
end
