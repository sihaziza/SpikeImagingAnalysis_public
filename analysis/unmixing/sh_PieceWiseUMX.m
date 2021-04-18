function [UMX, a]=sh_PieceWiseUMX(signal, reference, scale, FrequencyBand, Fs)

% for now, only work with vectors for both inputs
% first scale is always correspond to 4 slices

signal=zscore(signal);
reference=zscore(reference);

n=length(signal);
alpha=zeros(n,scale);

% default scale =5 from [4 8 16 32 64], number of slices
% check that it is a multiple of the highest scale > trim is not adjusted
r=round(n/2^(scale+1),0);
if r<Fs % take 1sec as a reference length to unmix
    disp('Not enough data point to compute the highest scale.')
    disp('Decrease *Scale value')
    return
end

for i=1:scale
    
    step=round(n/2^(i+1),0);
    
    for j=1:2^(i+1)
        if j==2^(i+1)
            range=step*(j-1)+1;
            [temp]=RobustLR(signal(range:end), reference(range:end), FrequencyBand, Fs);
            if temp<0
                alpha(range:end,i)=0;
            else
                alpha(range:end,i)=temp;
            end
        else
            range=step*(j-1)+1:step*j;
            [temp]=RobustLR(signal(range), reference(range), FrequencyBand, Fs);
            if temp<0
                alpha(range,i)=0;
            else
                alpha(range,i)=temp;
            end
        end
    end
end

a=mean(alpha,2);
a=smoothdata(a,'sgolay',round(length(signal)/2^(scale-1),0));

UMX=zscore(signal-a.*reference);

disp('Done unmixing piece-wise')
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