function [A] = createCoeffs(a)

% --- band ---
N  = length(a);
Nf = (N-1)/2;
A  = fft(a(:))/N;
A  = [A(Nf+2:N);A(1:Nf+1)];

return
