function coeffmap=rcunmx(V,R,fps)

coeffmap=zeros(size(V,1),size(V,2));

Iv=squeeze(mean(V,[1,2]));

[Fhemo,optsHB]=unmixing.FindHBpeak(Iv,'FrameRate',fps,'VerboseMessage',false,'VerboseFigure',false)
Fhemo


Fh=Fhemo.Location;

for ii=1:size(V,1)
    
    ii/size(V,1)
    for jj=1:size(R,2)
        Iv=squeeze(V(ii,jj,:));
        Ir=squeeze(R(ii,jj,:));

        M=double([Iv Ir]);
        [b,a]=butter(3,[Fh-2 Fh+2]/(fps/2),'bandpass');
        Mfilt=filtfilt(b,a,M);
        try
        p=robustfit(Mfilt(:,2),Mfilt(:,1));
        coeffmap(ii,jj)=p(2);
        catch ME
            fprintf('%d %d failed robust reg\n',ii,jj);
        end
        
    end
end