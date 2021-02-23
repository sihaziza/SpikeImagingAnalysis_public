function [Q,R] = getQuoRem(a,b)
% get the quotient and remainded between 2 input
% variables.
Q=floor(max(a,b)/min(a,b));
R=mod(max(a,b),min(a,b));

end