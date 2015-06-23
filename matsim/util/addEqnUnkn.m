function [ckt, eqnIndex, unknIndex] = addEqnUnkn(ckt, eqnName, eqnUnit, unknName, unknUnit)
% - introduce one equation and one unknown to the circuit -
ckt.numEqns = ckt.numEqns+1;
ckt.numUnkns = ckt.numUnkns+1;
ckt.eqnNames{ckt.numEqns} = eqnName;
ckt.eqnUnits{ckt.numEqns} = eqnUnit;
ckt.unknNames{ckt.numUnkns} = unknName;
ckt.unknUnits{ckt.numUnkns} = unknUnit;
eqnIndex = ckt.numEqns;
unknIndex = ckt.numUnkns;
return
