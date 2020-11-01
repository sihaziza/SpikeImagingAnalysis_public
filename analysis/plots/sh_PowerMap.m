function [map]=sh_PowerMap(movie, freqrange,fs)

options.plot=false; % RC

if freqrange(2)==inf
    band=[1 4;...
        5 9;...
        10 24;...
        25 50;...
        51 110;...
        120 fs/2-1];
    
    nFB=6;[i,j]=find(band>(fs/2-1));
    
    if ~isempty(i)
        jj=find(j==2,1,'first');
        nFB=i(jj);
        band(i,2)=fs/2-1;
    end
    
    for fr=1:nFB
        freqR=band(fr,:);
        dim=size(movie);
        map=zeros(dim(1),dim(2));
        
        parfor i=1:dim(1)
            temp=squeeze(movie(i,:,:));
            map(i,:) = bandpower(temp',fs,freqR);
        end
        if options.plot
        fig=figure;
        imshow(map,[])
        sh_SavePDF(fig,strcat('Fband_',num2str(freqR(1)),'Hz-',num2str(freqR(2)),'Hz'))
        end
    end
else
    dim=size(movie);
    map=zeros(dim(1),dim(2));
    
    parfor i=1:dim(1)
        temp=squeeze(movie(i,:,:));
        map(i,:) = bandpower(temp',fs,freqrange);
    end
    
    if options.plot
    fig=figure;
    imshow(map,[])
    sh_SavePDF(fig,strcat('Fband_',num2str(freqrange(1)),'Hz-',num2str(freqrange(2)),'Hz'))
    end
end


end
