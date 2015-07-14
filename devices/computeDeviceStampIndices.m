function [ckt] = computeDeviceStampIndices(ckt)

% - size of G and C matrices -
N = [ckt.numUnkns, ckt.numUnkns];

% - loop through all devices and compute stamp indices -
for i=1:ckt.numDevices
    device = ckt.devices{i};
    switch device.type 
        case 'I'
        case {'R', 'C', 'P', 'X'}
            device.senPP = 0; try device.senPP = sub2ind(N, device.nodeP, device.nodeP); catch end
            device.senPN = 0; try device.senPN = sub2ind(N, device.nodeP, device.nodeN); catch end
            device.senNP = 0; try device.senNP = sub2ind(N, device.nodeN, device.nodeP); catch end
            device.senNN = 0; try device.senNN = sub2ind(N, device.nodeN, device.nodeN); catch end
        case {'L', 'V'}
            device.senNU = 0; try device.senNU = sub2ind(N, device.nodeN, device.unkn ); catch end
            device.senPU = 0; try device.senPU = sub2ind(N, device.nodeP, device.unkn ); catch end
            device.senEN = 0; try device.senEN = sub2ind(N, device.eqn,   device.nodeN); catch end
            device.senEP = 0; try device.senEP = sub2ind(N, device.eqn,   device.nodeP); catch end
            if strcmp(device.type, 'L')
                device.senEU = sub2ind(N, device.eqn,   device.unkn) ;            
            end
        case 'G'
            device.senPP = 0; try device.senPP = sub2ind(N, device.nodeCurrentSourcP, device.nodeVoltageSensorP); catch end
            device.senPN = 0; try device.senPN = sub2ind(N, device.nodeCurrentSourcP, device.nodeVoltageSensorN); catch end
            device.senNP = 0; try device.senNP = sub2ind(N, device.nodeCurrentSourcN, device.nodeVoltageSensorP); catch end
            device.senNN = 0; try device.senNN = sub2ind(N, device.nodeCurrentSourcN, device.nodeVoltageSensorN); catch end
        case 'M'
        switch ckt.models{device.model}.model
            case 'mosRabaey'
                device.senDD = 0; try device.senDD = sub2ind(N, device.nodeD, device.nodeD); catch end
                device.senDG = 0; try device.senDG = sub2ind(N, device.nodeD, device.nodeG); catch end
                device.senDS = 0; try device.senDS = sub2ind(N, device.nodeD, device.nodeS); catch end
                device.senDB = 0; try device.senDB = sub2ind(N, device.nodeD, device.nodeB); catch end
                device.senGD = 0; try device.senGD = sub2ind(N, device.nodeG, device.nodeD); catch end
                device.senGG = 0; try device.senGG = sub2ind(N, device.nodeG, device.nodeG); catch end
                device.senGS = 0; try device.senGS = sub2ind(N, device.nodeG, device.nodeS); catch end
                device.senGB = 0; try device.senGB = sub2ind(N, device.nodeG, device.nodeB); catch end
                device.senSD = 0; try device.senSD = sub2ind(N, device.nodeS, device.nodeD); catch end
                device.senSG = 0; try device.senSG = sub2ind(N, device.nodeS, device.nodeG); catch end
                device.senSS = 0; try device.senSS = sub2ind(N, device.nodeS, device.nodeS); catch end
                device.senSB = 0; try device.senSB = sub2ind(N, device.nodeS, device.nodeB); catch end
                device.senBD = 0; try device.senBD = sub2ind(N, device.nodeB, device.nodeD); catch end
                device.senBG = 0; try device.senBG = sub2ind(N, device.nodeB, device.nodeG); catch end
                device.senBS = 0; try device.senBS = sub2ind(N, device.nodeB, device.nodeS); catch end
                device.senBB = 0; try device.senBB = sub2ind(N, device.nodeB, device.nodeB); catch end
        end
        % - add Diode -
        case 'D'
           switch ckt.models{device.model}.model
                case 'diode'
                    device.senPP = 0; try device.senPP = sub2ind(N, device.nodeP, device.nodeP); catch end
                    device.senPN = 0; try device.senPN = sub2ind(N, device.nodeP, device.nodeN); catch end
                    device.senNP = 0; try device.senNP = sub2ind(N, device.nodeN, device.nodeP); catch end
                    device.senNN = 0; try device.senNN = sub2ind(N, device.nodeN, device.nodeN); catch end
           end
    end    % - save device with computed stamp indices in the circuit -
    ckt.devices{i} = device;
end
return
