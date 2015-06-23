% -------------------------------------------------------------------------
% -                                                                       -
% -     Backward Differentiation Formula coefficients alpha and beta      -                                                                       -
% -                                                                       -
% -------------------------------------------------------------------------

function [alpha, beta] = bdf(diffFormula)

switch diffFormula
    case 'be'
        beta = 1;
        alpha = -[1 -1];
    case 'bdf2'
        beta = 2;
        alpha = -[3 -4 1];
    otherwise
        error(['Unsupported backward differentiation formula: ''',diffFormula,''''])
end

return
