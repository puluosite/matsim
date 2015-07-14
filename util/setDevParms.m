function ckt = setDevParms(ckt, devIndices, parmName, parmValue)

if length(parmValue) == 1
    parmValue = ones(length(devIndices))*parmValue;
end

for i=1:length(parmValue)
    ckt = setDeviceParm(ckt, devIndices(i), parmName, parmValue(i));
end
