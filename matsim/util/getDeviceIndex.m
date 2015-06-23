function deviceIndex = getDeviceIndex(ckt, deviceName)
% - loop through devices -
for i=1:ckt.numDevices
    if strcmp(ckt.devices{i}.name, deviceName)
        deviceIndex = i;
        return
    end
end
% - no device with requested name -
deviceIndex = 0;
return
