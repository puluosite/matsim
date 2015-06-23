function unknIndex = getUnknIndex(ckt, unknName)
% - loop through unknowns -
for i=1:ckt.numUnkns
    if strcmp(ckt.unknNames{i}, unknName)
        unknIndex = i;
        return
    end
end
% - no analysis with requested name -
unknIndex = 0;
return
