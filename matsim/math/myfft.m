function X = myfft(x)
N = size(x,1);
fftx = fft(x);
X = zeros(size(x));
X(1,:) = fftx(1,:)/N;
X(2:2:N,:) = -imag(fftx(2:(N+1)/2,:))*(2/N);
X(3:2:N,:) =  real(fftx(2:(N+1)/2,:))*(2/N);
return
