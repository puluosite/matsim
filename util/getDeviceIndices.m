function deviceIndices = getDeviceIndices(ckt, deviceNames)
deviceIndices = [];
for i=1:length(deviceNames)
    devIndex = getDeviceIndex(ckt, deviceNames{i});
    if devIndex ~= 0
        deviceIndices = [deviceIndices devIndex];
    else
        error(['Device ''',deviceNames{i},''' does not exist']);
    end
end
