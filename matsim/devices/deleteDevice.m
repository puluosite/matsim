function ckt = deleteDevice(ckt, deviceIndex)
switch ckt.devices{deviceIndex}.type 
    case {'R', 'C', 'I', 'M', 'G', 'P'}
    case 'V'
        ckt = deleteEqnUnkn(ckt, ckt.devices{deviceIndex}.eqn, ckt.devices{deviceIndex}.unkn);
    case 'L'
        ckt = deleteEqnUnkn(ckt, ckt.devices{deviceIndex}.eqn, ckt.devices{deviceIndex}.unkn);
    otherwise
        error(['Unknown type of device ''',ckt.devices{deviceIndex}.name,'''']);
        return
end
ckt.devices(deviceIndex) = [];
ckt.devNames(deviceIndex) = [];
ckt.numDevices = ckt.numDevices - 1;
return
