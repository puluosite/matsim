function [parmValue, given] = getParmValue(parms, parmValue, parmName)
given = 0;
for i=1:2:length(parms)
    if strcmp(parms{i}, parmName)
        parmValue = parms{i+1};
        given = 1;
        return
    end
end
