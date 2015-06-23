function X = myspectrum(x)
N = size(x,1);
fftx = fft(x);
% X = zeros((N+1)/2,size(x,2));
X = zeros(ceil(N/2),size(x,2));
X(1,:) = fftx(1,:)/N;
% X(2:(N+1)/2,:) = (real(fftx(2:(N+1)/2,:)) - j*imag(fftx(2:(N+1)/2,:)))*(2/N);
% X(2:(N+1)/2,:) = conj(fftx(2:(N+1)/2,:))*(2/N);
X(2:ceil(N/2),:) = conj(fftx(2:ceil(N/2),:))*(2/N);
return
