function [nonConv, absErr, relErr] = checkConv(xold, x, dx, absTol, relTol)
% - absolute errors -
absErr = abs(dx);
% - relative errors -
xmax = max(abs(x), abs(xold));
nonZeroIndices = find(xmax~=0);
relErr = zeros(size(x));
relErr(nonZeroIndices) = absErr(nonZeroIndices)./xmax(nonZeroIndices);
% - check convergence -
absNonConv = absErr>absTol;
relNonConv = relErr>relTol;
nonConv = sum(absNonConv & relNonConv);
return
