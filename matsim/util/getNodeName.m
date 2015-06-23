function nodeName = getNodeName(ckt, nodeKCLeqnIndex)
% - check for ground node -
if nodeKCLeqnIndex == 0
    nodeName = '0';
    return
end
nodeIndex = find(ckt.nodeKCLeqnIndices==nodeKCLeqnIndex);
nodeName = ckt.nodeNames{nodeIndex};
return
