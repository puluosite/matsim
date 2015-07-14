function [devIndices, srcFreqs, multirate] = getPeriodicSources(ckt)

devIndices = [];
srcFreqs   = [];
numPeriodicSources = 0;
multirate = 0;
for dev = 1:ckt.numDevices
    type = ckt.devices{dev}.type;
    if (type == 'V' | type == 'I') & isfield(ckt.devices{dev}, 'freq') & ckt.devices{dev}.freq ~= 0
        numPeriodicSources = numPeriodicSources + 1;
        devIndices(numPeriodicSources) = dev;
        srcFreqs(numPeriodicSources)   = ckt.devices{dev}.freq;
        if numPeriodicSources > 1
            if srcFreqs(numPeriodicSources) ~= srcFreqs(1);
                multirate = 1;
            end
        end
    end
end

return
