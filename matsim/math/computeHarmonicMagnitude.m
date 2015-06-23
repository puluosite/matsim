function [absXharm, sinXharm, cosXharm] = computeHarmonicMagnitude(x, harm)
X = myfft(x);
N = length(harm);
sinXharm = zeros(N,1);
i = 0;
for h = harm
    i = i+1;
    if h == 0
        sinXharm(i) = 0;
    else
        sinXharm(i) = X(h*2);
    end
end
cosXharm = X(harm*2+1);
absXharm = sqrt(sinXharm.*sinXharm + cosXharm.*cosXharm);
return
