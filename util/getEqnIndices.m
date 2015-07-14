function indices = getEqnIndices(ckt,eqns)
    indices = [];
    for k=1:1:length(eqns)
        indices = [indices,strmatch(eqns(k),ckt.eqnNames,'exact')];
    end
return
