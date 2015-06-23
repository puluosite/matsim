function [f x] = convolveSpectra(f1, x1, f2, x2, xmin)

f = [];
x = [];

for i1 = 1:length(f1)
    [f, x] = addSpectra(f, x, f1(i1)+f2, x1(i1)*x2);
end

[f, x] = compactSpectrum(f, x);

ismall = find(abs(x) < xmin);
f(ismall) = [];
x(ismall) = [];

return
