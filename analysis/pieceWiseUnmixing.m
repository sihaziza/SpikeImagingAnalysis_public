function [output]=pieceWiseUnmixing(signal, reference, Fs, varargin)

% for now, only work with vectors for both inputs
% first scale is always correspond to 4 slices.
% alternatively, use 1sec window with overlap (from 0% to 90% ovlp)
% Output strucutre:
%   output.residual
%   output.coefficient

options.umxMethod='pca';
options.method='sliding';   % 'sliding' or 'pyramid'
options.window=0.5;           % 1 second
options.overlap=0.5;        % 50%

%% GET OPTIONS

options=getOptions(options,varargin);

%% CORE

n=length(signal);
[NEW_WINDOW]=getBestWindow(n, options.window, Fs);

[Q,~] = getQuoRem(n,NEW_WINDOW*Fs);

truncSig=signal(1:(Q-1)*NEW_WINDOW*Fs);
sigPrep=reshape(truncSig,Q-1,NEW_WINDOW*Fs);% treat the last section separatly

truncRef=reference(1:(Q-1)*NEW_WINDOW*Fs);
refPrep=reshape(truncRef,Q-1,NEW_WINDOW*Fs);% treat the last section separatly

%%
alpha=zeros(Q-1,1);

switch options.umxMethod
    case 'pca'
        
        for iTrunc=1:Q-1
            %             [coeff,~,~,~,~,~] = pca([sigPrep(iTrunc,:)'; refPrep(iTrunc,:)']);
            %             alpha(iTrunc)=coeff(1);
            %
            A=[sigPrep(iTrunc,:); refPrep(iTrunc,:)];
            [U,~,~] = svd(A,'econ');
            U=U./diag(U);
            alpha(iTrunc)=abs(1/U(1,2));
        end
        alpha=alpha.*ones(size(sigPrep));
        
        alpha=reshape(alpha',[1, prod(size(alpha),'all')]);
        
        % Deal with the last trunc
        tempSig=signal((Q-1)*NEW_WINDOW*Fs+1:end);
        tempRef=reference((Q-1)*NEW_WINDOW*Fs+1:end);
        
        %         [coeff,~,~,~,~,~] = pca([tempSig'; tempRef']);
        %         alpha=[alpha coeff(1).*ones(size(tempSig))];
        A=[tempSig; tempRef];
        [U,~,~] = svd(A,'econ');
        U=U./diag(U);
        alpha=[alpha abs(1/U(1,2)).*ones(size(tempSig))];
        
        % Highest variance PC1 is hemodynamic aka reference. Source is the first
        % input. The signal can be reconstructed using the first element of the
        % diagonal/anti-diagonal ratio.
        % temp=diag(coeff,0)/diag(coeff,1);
        % umxcoeff=temp(1);
        % unmixsource=M(:,1)-umxcoeff.*M(:,2); % compute the residual
        
        output.residual=signal-alpha.*reference;
        output.coefficient=alpha;
        
        time=getTime(alpha,Fs);
        plot(time,alpha)
        alphaPCA=alpha;
    case 'rlr'
        
        for iTrunc=1:Q-1
            p=robustfit(refPrep(iTrunc,:),sigPrep(iTrunc,:));
            alpha(iTrunc)=p(2);
        end
        alpha=alpha.*ones(size(sigPrep));
        
        alpha=reshape(alpha',[1, prod(size(alpha),'all')]);
        
        % Deal with the last trunc
        tempSig=signal((Q-1)*NEW_WINDOW*Fs+1:end);
        tempRef=reference((Q-1)*NEW_WINDOW*Fs+1:end);
        
        % RLR
        p=robustfit(tempRef,tempSig);
        alpha=[alpha p(2).*ones(size(tempSig))];
        
        output.residual=signal-alpha.*reference;
        output.coefficient=alpha;
        
        time=getTime(alpha,Fs);
        plot(time,alpha)
        alphaRLR=alpha;
        
        
    case 'linear'
        
        for iTrunc=1:Q-1
            p=polyfit(refPrep(iTrunc,:),sigPrep(iTrunc,:),1);
            alpha(iTrunc)=p(1);
        end
        
        alpha=alpha.*ones(size(sigPrep));
        
        alpha=reshape(alpha',[1, prod(size(alpha),'all')]);
        
        % Deal with the last trunc
        tempSig=signal((Q-1)*NEW_WINDOW*Fs+1:end);
        tempRef=reference((Q-1)*NEW_WINDOW*Fs+1:end);
        
        p=polyfit(tempRef,tempSig,1);
        
        alpha=[alpha p(1).*ones(size(tempSig))];
        
        output.residual=signal-alpha.*reference;
        output.coefficient=alpha;
        
        time=getTime(alpha,Fs);
        plot(time,alpha)
        alphaLIN=alpha;
        
    case 'ica'
        %         [icasig, ~, W] = fastica(A,'approach','symm','g','tanh','epsilon',1e-6,'stabilization','on','displayMode','on','verbose','off');
        % W(1,:)=W(1,:)./W(1,1);
        % W(2,:)=W(2,:)./W(2,2);
        % W
        %
        % % rank ICA output based on heartbeat power ? or skewness of A?
        
end

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