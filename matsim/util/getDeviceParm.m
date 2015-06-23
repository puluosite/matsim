function value = getDeviceParm(ckt, deviceIndex, deviceParm)
dev = ckt.devices{deviceIndex};
% - get device parameter -
switch dev.type
    case 'R'
        if strcmp(deviceParm, 'res')
            value = dev.resistance;
        elseif strcmp(deviceParm, 'cond')
            value = 1/dev.resistance;
        end
    case 'L'
        if strcmp(deviceParm, 'ind')
            value = dev.inductance;
        end
    case 'C'
        if strcmp(deviceParm, 'cap')
            value = dev.capacitance;
        end
    case 'X'
        if strcmp(deviceParm, 'cap')
            value = dev.capacitance;
        end
    case 'I'
        if strcmp(deviceParm, 'cur')
            value = dev.current;
        end
    case 'V'
        if strcmp(deviceParm, 'vol')
            if ~isfield(dev, 'pwl')
                value = dev.voltage;
            else
                value = dev.pwl.value(3);
            end
        elseif strcmp(deviceParm, 'amplitude')
            value = dev.amplitude;
        elseif strcmp(deviceParm, 'freq')
            value = dev.freq;
        elseif strcmp(deviceParm, 'period')
            value = 1/dev.freq;
        elseif strcmp(deviceParm, 'piece2Location')
            piece = 2;
            t1 = dev.pwl.time(piece);
            t2 = dev.pwl.time(piece+1);
            value = (t1+t2)/2;
        end
    case 'M'
        if strcmp(deviceParm, 'W')
            value = dev.W;
        elseif strcmp(deviceParm, 'L')
            value = dev.L;
        end
    case 'N'
        if strcmp(deviceParm, 'W')
            value = dev.W;
        elseif strcmp(deviceParm, 'L')
            value = dev.L;
        end
    case 'Z'
        switch ckt.models{dev.model}.model
            case 'Van der Pol oscillator'
                if strcmp(deviceParm, 'm')
                    value = dev.m;
                end
        end
    otherwise
        ckt = reportError(ckt, ['Unknown type of device ''',dev.name,'''']);
        return
end

return
