function [val_norm]=getBloodVesselTimeProfile(movie)

nFrame=size(movie,3);

if nFrame>10
    f0=mean(movie(:,:,end-10:end),3);
else
    f0=movie(:,:,1);
end
    imshow(f0,[])
[cx,cy,~] =improfile;

xi=round([cx(1) cx(end)]);
yi=round([cy(1) cy(end)]);

[cx,~,~] =improfile(double(movie(:,:,1)),xi,yi,'bilinear');

c=zeros(length(cx),nFrame);
vect=round(linspace(1,nFrame,4));
tic;
for j=1:length(vect)-1
    parfor i=vect(j):vect(j+1)
        [c(:,i)] =improfile(movie(:,:,i),xi,yi,'bilinear');
    end
    toc;
end
toc;

[val,~]=min(c,[],1);
val_norm=(val./mean(val)-1);
end