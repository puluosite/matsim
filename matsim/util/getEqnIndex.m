function eqnIndex = getEqnIndex(ckt, eqnName)
% - loop through equations -
for i=1:ckt.numEqns
    if strcmp(ckt.eqnNames{i}, eqnName)
        eqnIndex = i;
        return
    end
end
% - no equation with requested name -
eqnIndex = 0;
return
