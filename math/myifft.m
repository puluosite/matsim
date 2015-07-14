function x = myifft(X)
N = size(X,1);
fftx = zeros(size(X));
fftx(1,:) = X(1,:)*N;
fftx(2:(N+1)/2,:)      = (X(3:2:N,:) - j*X(2:2:N,:))*(N/2);
fftx(N:-1:(N+1)/2+1,:) = (X(3:2:N,:) + j*X(2:2:N,:))*(N/2);
x = ifft(fftx);
return
