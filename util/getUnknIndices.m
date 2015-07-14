function indices = getUnknIndices(ckt,unkns)
    indices = [];
    for k=1:1:length(unkns)
        indices = [indices,strmatch(unkns(k),ckt.unknNames,'exact')];
    end
return
