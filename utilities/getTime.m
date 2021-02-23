function time=getTime(data,Fs)

n=max(size(data));
time=linspace(0,(n-1)/Fs,n);
end