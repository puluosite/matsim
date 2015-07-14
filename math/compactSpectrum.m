function [f1 x1] = compactSpectrum(f, x)

f1 = [];
x1 = [];
for i = 1:length(f)
    [f1, x1] = addSpectra(f1, x1, f(i), x(i));
end

return
