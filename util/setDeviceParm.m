function ckt = setDeviceParm(ckt, deviceIndex, deviceParm, value)
dev = ckt.devices{deviceIndex};
% - get device parameter -
switch dev.type
    case 'R'
        if strcmp(deviceParm, 'res')
            dev.resistance = value;
        elseif strcmp(deviceParm, 'cond')
            dev.resistance = 1/value;
        end
    case 'L'
        if strcmp(deviceParm, 'ind')
            dev.inductance = value;
        end
    case 'C'
        if strcmp(deviceParm, 'cap')
            dev.capacitance = value;
        end
    case 'X'
        if strcmp(deviceParm, 'cap')
            dev.capacitance = value;
        end
    case 'I'
        if strcmp(deviceParm, 'cur')
            dev.current = value;
        end
    case 'V'
        if strcmp(deviceParm, 'vol')
            if ~isfield(dev, 'pwl')
                dev.voltage = value;
            else
                dev.pwl.value(3) = value;
                dev.pwl.value(4) = value; 
            end
            
        elseif strcmp(deviceParm, 'amplitude')
            dev.amplitude = value;
        elseif strcmp(deviceParm, 'freq')
            dev.freq = value;
        elseif strcmp(deviceParm, 'period')
            dev.freq = 1/value;
        elseif strcmp(deviceParm, 'piece2Location')
            piece = 2;
            t1 = dev.pwl.time(piece);
            t2 = dev.pwl.time(piece+1);
            d = (t2-t1)/2;
            dev.pwl.time(piece)   = value - d;
            dev.pwl.time(piece+1) = value + d;
        end
    case 'M'
        if strcmp(deviceParm, 'W')
            dev.W = value;
        elseif strcmp(deviceParm, 'L')
            dev.L = value;
        end
    case 'N'
        if strcmp(deviceParm, 'W')
            dev.W = value;
        elseif strcmp(deviceParm, 'L')
            dev.L = value;
        end
    case 'Z'
        switch ckt.models{dev.model}.model
            case 'Van der Pol oscillator'
                if strcmp(deviceParm, 'm')
                    dev.m = value;
                end
        end
    otherwise
        ckt = reportError(ckt, ['Unknown type of device ''',dev.name,'''']);
        return
end
ckt.devices{deviceIndex} = dev;
return
