function [ckt, eqnIndex] = addNode(ckt, nodeName)
global VOLTAGE_UNIT
global CURRENT_UNIT
% - check for ground node -
if strcmp(nodeName,'0')
   ckt.groundNodeIntroduced = 1;
   eqnIndex = 0;
   return
end
% - check if the node is already in the circuit -
nodeIndex = strmatch(nodeName, ckt.nodeNames, 'exact');
if length(nodeIndex)
    % - do not add - the node is already in the ciruit -
    eqnIndex = ckt.nodeKCLeqnIndices(nodeIndex);
    return
else
    % - add the node to the circuit -
    ckt.numNodes = ckt.numNodes+1;
    ckt.nodeNames{ckt.numNodes} = nodeName;
    % - add the equation name and variable name -
    eqnName = ['KCL at ', ckt.nodeNames{ckt.numNodes}];
    eqnUnit = CURRENT_UNIT;
    unknName = ['v(', ckt.nodeNames{ckt.numNodes}, ')'];
    unknUnit = VOLTAGE_UNIT;
    [ckt, eqnIndex, unknIndex] = addEqnUnkn(ckt, eqnName, eqnUnit, unknName, unknUnit);
    ckt.nodeKCLeqnIndices(ckt.numNodes) = eqnIndex;
end
return
