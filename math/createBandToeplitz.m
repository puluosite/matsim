function [Ta] = createBandToeplitz(a)

% --- band ---
N  = length(a);
Nf = (N-1)/2;
A  = fft(a(:))/N;
Ta = toeplitz([A(Nf+2:N);A(1:Nf+1);zeros(2*Nf,1)], [A(Nf+2),zeros(1,2*Nf)]);
Ta = Ta(Nf+1:Nf+N,:);

% --- full ---
% I  = eye(length(a));
% A  = diag(a);
% Ta = fft(A*ifft(I));

return
