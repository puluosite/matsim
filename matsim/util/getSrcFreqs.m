function [srcFreqs, fund] = getSrcFreqs(ckt)

% - find the list of unique source frequencies -
srcFreqs = [];
fund = 0;
numPeriodicSources = 0;
for dev = 1:ckt.numDevices
    type = ckt.devices{dev}.type;
    if (type == 'V' | type == 'I') & isfield(ckt.devices{dev}, 'freq') & ckt.devices{dev}.freq ~= 0
        if isempty(find(srcFreqs==ckt.devices{dev}.freq))            
            numPeriodicSources = numPeriodicSources + 1;
            srcFreqs(numPeriodicSources) = ckt.devices{dev}.freq;
        end
    end
end

% - find the fundamental frequency (if there is one) -
for i = 1:length(srcFreqs)
    if i == 1
        fund = srcFreqs(1);
    else
        if ~mod(fund/srcFreqs(i),1)
            fund = srcFreqs(i);
        elseif mod(srcFreqs(i)/fund,1)
            fund = 0;
            return
        end
    end
end

return
