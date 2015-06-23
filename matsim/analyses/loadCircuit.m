function [ckt, data] = loadCircuit(ckt, x, info)

global MODE_DC
global MODE_TRAN
global MODE_SEN
global MODE_SEN2

% - device models are capable of providing -
% i          q 
% G = di/dv  C = dq/dv
% di/dp      dq/dp
% dG/dp      dC/dp
% dG/dv      dC/dv

% - circuit loading options given by info.mode -
% MODE_DC   adds {i  G}
% MODE_TRAN adds {q  C}
% MODE_SEN  adds {di/dp  dq/dp} 
% MODE_SEN2 adds {dG/dp  dG/dv  dC/dp  dC/dv} 


N = ckt.numUnkns;
if info.mode >= MODE_SEN
    P = length(info.parms);
else
    P = 0;
end

% - allocate memory for vectors and matrices depending on loading mode -
data = allocateDataMemory(N, P, info.mode);
% - state variables -
data.x = x;

% - load all devices -
info.thisDeviceParmIndices = [];
if info.mode < MODE_SEN
    for deviceIndex=1:ckt.numDevices
        [ckt, data] = loadDevice(ckt, deviceIndex, data, info);
    end
else
    for deviceIndex=1:ckt.numDevices
        i = 0;
        allM1 = 1;
        info.thisDeviceParmIndices = [];
        M = [];
        for par = 1:P
            % - no device indices if the pss period is a parameter -
            if isfield(info.parms{par}, 'deviceIndices')
                thisDeviceIndexInGroup = find(info.parms{par}.deviceIndices == deviceIndex);
                if thisDeviceIndexInGroup
                    i = i+1;
                    info.thisDeviceParmIndices(i) = par;
                    M(par) = info.parms{par}.multipliers(thisDeviceIndexInGroup);
                    if M(par) ~= 1
                        allM1 = 0;
                    end
                end
            end
        end
        % - all devices of this parameter are equal -
        if allM1
            [ckt, data] = loadDevice(ckt, deviceIndex, data, info);            
        else
            dataDev = allocateDataMemory(N, P, info.mode);
            dataDev.x = x;
            [ckt, dataDev] = loadDevice(ckt, deviceIndex, dataDev, info);
            data = addMultiplied(data, dataDev, N, M, info.thisDeviceParmIndices, info.mode);
        end
    end
end
return











function [data] = allocateDataMemory(N, P, mode)
global MODE_DC
global MODE_TRAN
global MODE_SEN
global MODE_SEN2

data = [];
if mode >= MODE_DC
    data.i  =  zeros(N, 1);
%     data.G  = sparse(N, N); % - doesn't work with EKV quick-stamp mex  -
    data.G  =  zeros(N, N);
    data.Nw =  zeros(N, N);
    data.Nf =  zeros(N, N);
    if mode >= MODE_TRAN
        data.q = zeros(N, 1);
%         data.C  = sparse(N, N); % - doesn't work with EKV quick-stamp mex  -
        data.C = zeros(N, N);
        if mode >= MODE_SEN
            data.didpar  = sparse(N,P);
            data.dqdpar  = sparse(N,P);
            if mode == MODE_SEN2
                for p=1:P
                    data.dCdpar{p}   = sparse(N, N);
                    data.dGdpar{p}   = sparse(N, N);
                    data.dNw_dpar{p} = sparse(N, N);
                    data.dNf_dpar{p} = sparse(N, N);
                end
                for n=1:N
                    data.dCdv{n}   = sparse(N, N);
                    data.dGdv{n}   = sparse(N, N);
                    data.dNw_dv{n} = sparse(N, N);
                    data.dNf_dv{n} = sparse(N, N);
                end
            end
        end
    end
else
    error(['Unknown loading mode (',num2str(info.mode),')']);
end
return











function [data] = addMultiplied(data, dataDev, N, M, thisDeviceParmIndices, mode);
global MODE_DC
global MODE_TRAN
global MODE_SEN
global MODE_SEN2

data.i = data.i + dataDev.i;
data.G = data.G + dataDev.G;
data.q = data.q + dataDev.q;
data.C = data.C + dataDev.C;
data.Nw = data.Nw + dataDev.Nw;
data.Nf = data.Nf + dataDev.Nf;
for par = thisDeviceParmIndices
    data.didpar(:,par)  = data.didpar(:,par)  + M(par)*dataDev.didpar(:,par);
    data.dqdpar(:,par)  = data.dqdpar(:,par)  + M(par)*dataDev.dqdpar(:,par);
%     data.dBbdpar(:,par) = data.dBbdpar(:,par) + M(par)*dataDev.dBbdpar(:,par);
end
if mode == MODE_SEN2
    for par=thisDeviceParmIndices
        data.dCdpar{par}   = data.dCdpar{par}   + M(par)*dataDev.dCdpar{par};
        data.dGdpar{par}   = data.dGdpar{par}   + M(par)*dataDev.dGdpar{par};
        data.dNw_dpar{par} = data.dNw_dpar{par} + M(par)*dataDev.dNw_dpar{par};
        data.dNf_dpar{par} = data.dNf_dpar{par} + M(par)*dataDev.dNf_dpar{par};
    end
    for n=1:N
        data.dCdv{n}   = data.dCdv{n}   + dataDev.dCdv{n};
        data.dGdv{n}   = data.dGdv{n}   + dataDev.dGdv{n};
        data.dNw_dv{n} = data.dNw_dv{n} + dataDev.dNw_dv{n};
        data.dNf_dv{n} = data.dNf_dv{n} + dataDev.dNf_dv{n};
    end
end
return
