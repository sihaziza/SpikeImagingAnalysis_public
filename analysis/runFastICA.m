function [umxSignal,umxReference]=runFastICA(source,reference)

options.savePath=[];
options.figName= '_runFastICA';
options.plotFigure=[];

% Make sure M is a row matrix
if isrow(source) && isrow(reference)
    M=double([source reference]);
else
    M=double([source' reference']);
end

% run fastICA
[icasig, ~, ~] = fastica(M','approach','symm','g','tanh','epsilon',1e-6,...
    'stabilization','on','displayMode','off','verbose','off');
icasig=icasig';

% reassign traces
X1=M;
X2=icasig;
N = size(X1,1);
X1_norm = zscore(X1,1,1)/sqrt(N);
X2_norm = zscore(X2,1,1)/sqrt(N);
C = X1_norm'*X2_norm;
C(abs(C)<0.75)=0;
C=round(C);
umx=(C*icasig')';

% rescale as original inputs
umx(:,1)=rescale(umx(:,1),min(M(:,1)),max(M(:,1)));
umx(:,2)=rescale(umx(:,2),min(M(:,2)),max(M(:,2)));

umxSignal=umx(:,1);
umxReference=umx(:,2);

if options.plotFigure
    figH=figure('Name','fastICA output','DefaultAxesFontSize',12,'color','w');
    for i=1:2
        for j=1:2
            subplot(2,2,(i-1)*2+j)
            plot(M(:,i),icasig(:,j))
            title(['input ' num2str(i) 'vs ica ' num2str(j)])
        end
    end
end

if options.savePath    
    if options.savePath
        savePDF(figH,options.figName,options.savePath)
        disp(['Figure - ' options.figName ' - successfully saved...'])
    end    
end
end