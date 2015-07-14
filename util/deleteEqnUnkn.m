function ckt = deleteEqnUnkn(ckt, eqnIndex, unknIndex)
ckt.numEqns = ckt.numEqns-1;
ckt.numUnkns = ckt.numUnkns-1;
ckt.eqnNames(eqnIndex) = [];
ckt.eqnUnits(eqnIndex) = [];
ckt.unknNames(unknIndex) = [];
ckt.unknUnits(unknIndex) = [];
return
