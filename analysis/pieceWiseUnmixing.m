function [output]=pieceWiseUnmixing(signal, reference, Fs, varargin)

% for now, only work with vectors for both inputs
% first scale is always correspond to 4 slices.
% alternatively, use 1sec window with overlap (from 0% to 90% ovlp)
% Output strucutre:
%   output.residual
%   output.coefficient
% Variable Input Arguments:
%     options.umxMethod='pca'; %rlr,linear,ica
%     options.method='sliding';   % 'sliding' or 'pyramid'
%     options.window=0.5;           % 1 second
%     options.overlap=0.5;        % 50%

options.umxMethod='pca'; %rlr,linear,ica
options.method='sliding';   % 'sliding' or 'pyramid'
options.window=[];           % 1 second
options.overlap=0.5;        % 50%
options.verbose=1;
%% GET OPTIONS

options=getOptions(options,varargin);

%% CHECK INPUT

d=size(signal);
if d(1)<d(2) % only work with column vectors - time in rows
    signal=signal';
    reference=reference';
end
    
%% CORE
n=length(signal);

if isempty(options.window)
    options.window=n;
    vectT=[0 n];
else
vectT=findBestPartition(n,options.window*Fs);
vectT(1)=0; % for the subsequent loop
end


signal_temp=sh_bpFilter(signal,[5 30],Fs)+1;
reference_temp=sh_bpFilter(reference,[5 30],Fs)+1;

% signal_temp=signal;
% reference_temp=reference;

%%

alpha=zeros(d);

switch options.umxMethod
    case 'pca'
        
        for i=1:length(vectT)-1
            %             A=[sigPrep(iTrunc,:); refPrep(iTrunc,:)];
            A=[reference(vectT(i)+1:vectT(i+1),1)';signal(vectT(i)+1:vectT(i+1),1)'];
            [U,~,~] = svd(A,'econ');
            U=U./diag(U);
            %             alpha(iTrunc)=abs(1/U(1,2));
            alpha(vectT(i)+1:vectT(i+1),1)=abs(1/U(1,2));
        end
        
        % Highest variance PC1 is hemodynamic aka reference. Source is the first
        % input. The signal can be reconstructed using the first element of the
        % diagonal/anti-diagonal ratio.
        % temp=diag(coeff,0)/diag(coeff,1);
        % umxcoeff=temp(1);
        % unmixsource=M(:,1)-umxcoeff.*M(:,2); % compute the residual
        
        % Smooth the coefficient output
        alpha=sh_bpFilter(alpha,[inf 0.1],Fs);
        
        output.residual=sh_bpFilter(signal-alpha.*reference,[0.1 inf],Fs);
        output.coefficient=alpha;
        output.methods='svd';
        output.window=options.window;
        
    case 'rlr'
        for j=1:d(2)
        for i=1:length(vectT)-1
            p=robustfit(reference_temp(vectT(i)+1:vectT(i+1),1),signal_temp(vectT(i)+1:vectT(i+1),1));
            alpha(vectT(i)+1:vectT(i+1),1)=p(2);
        end
        end
     % Smooth the coefficient output
        time=getTime(alpha,Fs)';
        for j=1:d(2)
        p=robustfit(time,alpha(:,j));
%         alpha(:,j)=p(2)*time+p(1)
            alpha=p(1);
        end
        output.residual=signal-alpha.*reference;
        output.coefficient=alpha;
        output.methods='rlr';
        output.window=options.window;
        
    case 'linear'
        
        for j=1:d(2)
        for  i=1:length(vectT)-1
            p=polyfit(reference_temp(vectT(i)+1:vectT(i+1),1),signal_temp(vectT(i)+1:vectT(i+1),1),1);
            alpha(vectT(i)+1:vectT(i+1),j)=p(1);
        end
        end
        % Smooth the coefficient output
        time=getTime(alpha,Fs)';
        for j=1:d(2)
        p=robustfit(time,alpha(:,j));
%         alpha(:,j)=p(2)*time+p(1)
            alpha=p(1);
        end
        output.residual=signal-alpha.*reference;
        output.coefficient=alpha;
        output.methods='linear';
        output.window=options.window;
        
    case 'ica'
        
        
%         for  i=1:length(vectT)-1
%             A=[reference(vectT(i)+1:vectT(i+1),1)';signal(vectT(i)+1:vectT(i+1),1)'];           
%             [~, ~, W] = fastica(A,'approach','symm','g','tanh','epsilon',1e-8,'stabilization','on','displayMode','on','verbose','off');
%             W(1,:)=W(1,:)./W(1,1);
%             W(2,:)=W(2,:)./W(2,2);
%             W
%             p=polyfit(reference_temp(vectT(i)+1:vectT(i+1),1),signal_temp(vectT(i)+1:vectT(i+1),1),1);
%             alpha(vectT(i)+1:vectT(i+1),1)=p(1);
%         end
        
        % Smooth the coefficient output
        %         alpha=sh_bpFilter(alpha,[inf 0.1],Fs);
        time=getTime(alpha,Fs)';
        p=robustfit(time,alpha);
        alpha=p(2)*time+p(1);
        %         plot(alpha)
        %         plot(output.residual)
        output.residual=sh_bpFilter(signal-alpha.*reference,[0.1 inf],Fs);
        output.coefficient=alpha;
        output.methods='linear';
        output.window=options.window;
        % rank ICA output based on heartbeat power ? or skewness of A?
        
end

% time=getTime(alpha,Fs);
% plot(time,alpha)
%%
%
% % don't normalize... keep the real values
% signal=zscore(signal);
% reference=zscore(reference);
%
% n=length(signal);
% alpha=zeros(n,scale);
%
% % default scale =5 from [4 8 16 32 64], number of slices
% % check that it is a multiple of the highest scale > trim is not adjusted
% r=round(n/2^(scale+1),0);
% if r<Fs % take 1sec as a reference length to unmix
%     disp('Not enough data point to compute the highest scale.')
%     disp('Decrease *Scale value')
%     return
% end
%
% for i=1:scale
%
%     step=round(n/2^(i+1),0);
%
%     for j=1:2^(i+1)
%         if j==2^(i+1)
%             range=step*(j-1)+1;
%             [temp]=RobustLR(signal(range:end), reference(range:end), FrequencyBand, Fs);
%             if temp<0
%                 alpha(range:end,i)=0;
%             else
%                 alpha(range:end,i)=temp;
%             end
%         else
%             range=step*(j-1)+1:step*j;
%             [temp]=RobustLR(signal(range), reference(range), FrequencyBand, Fs);
%             if temp<0
%                 alpha(range,i)=0;
%             else
%                 alpha(range,i)=temp;
%             end
%         end
%     end
% end
%
% a=mean(alpha,2);
% a=smoothdata(a,'sgolay',round(length(signal)/2^(scale-1),0));
%
% UMX=zscore(signal-a.*reference);

% disp('Done unmixing piece-wise')
end

function [alpha]=RobustLR(signal, reference, FrequencyBand, Fs)
% number of signal to unmix
n=size(signal,2);

% Data conditioning
M=[signal reference];

% no standardization here to not bias the output (?)

% filter on a narrower band to help find the best coeff
Mfilt=sh_bpFilter(M, FrequencyBand, Fs);

alpha=zeros(1,n);
for i=1:n
    p=robustfit(Mfilt(:,end),Mfilt(:,i));
    alpha(1,i)=p(2);
end

end