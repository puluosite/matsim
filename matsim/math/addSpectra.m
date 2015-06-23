function [f1 x1] = addSpectra(f1, x1, f2, x2)

reltol = 1e-12;
for i2 = 1:length(f2)
    i1 = find(abs(f2(i2)-f1) <= reltol*abs(f2(i2)));
    if ~isempty(i1)
        % - sum values for a common frequency -
        x1(i1) = x1(i1) + x2(i2);
    else
        % - append a new frequency and a value -
        f1(length(f1)+1) = f2(i2);
        x1(length(x1)+1) = x2(i2);
    end
end
f1 = f1(:);
x1 = x1(:);

return
