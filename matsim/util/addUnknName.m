function  ckt = addUnknName(ckt, unknName);
ckt.numUnkns = ckt.numUnkns+1;
ckt.unknNames{ckt.numUnkns} = unknName;
return
