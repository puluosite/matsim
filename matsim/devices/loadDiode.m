function [data, dev] = loadDiode(ckt, deviceIndex, data, info, dev, thisDeviceParmIndices)

global MODE_DC
global MODE_TRAN


% - equations -
        % KCL (at nodeP)            : 0 = ...  +I ...
        % KCL (at nodeN)            : 0 = ...  -I ...
        % its Jacobian  di(v(t))/dv : G(v) = [      +G -G  ]
        %                                    [      -G +G  ]
        % dynamic variable  q(v(t)) : q(v) =  [ +qp ]
        %                                                [ -qp ]
        % its Jacobian  dq(v(t))/dv : C(v) = [     +C  -C  ]
        %                                    [     -C  +C  ]
        

if info.mode >= MODE_DC
    % - constants -
    phi_b = 0.75;
    m = 0.5;
    % - load parameter -
            Is =  ckt.models{dev.model}.Is;
            n = ckt.models{dev.model}.n;
            vt = ckt.models{dev.model}.vt;
            cjo = ckt.models{dev.model}.cjo;
             % - variables -
            if(dev.nodeP) vp = data.x(dev.nodeP); else vp = 0; end
            if(dev.nodeN) vn = data.x(dev.nodeN); else vn = 0; end
            % - current -
            if(vp == vn) return; end
            % - current with Shockley equation -
            Id0 = Is*(exp((vp-vn)/(n*vt))-1); 
            % - d(i(v(t))/dv = G -
            Gd0 = (Is/(n*vt))*exp((vp-vn)/(n*vt)); 
            Idn0 = Id0 - Gd0*(vp-vn);
             % - i -
            if(dev.nodeP) data.i(dev.nodeP) = data.i(dev.nodeP) + Idn0; end
            if(dev.nodeN) data.i(dev.nodeN) = data.i(dev.nodeN) - Idn0; end
            % - G -
            if(dev.senPP) data.G(dev.senPP) = data.G(dev.senPP) +Gd0; end
            if(dev.senNN) data.G(dev.senNN) = data.G(dev.senNN) +Gd0; end
            if(dev.senPN) data.G(dev.senPN) = data.G(dev.senPN) -Gd0; end
            if(dev.senNP) data.G(dev.senNP) = data.G(dev.senNP) -Gd0; end

            if info.mode >= MODE_TRAN
                % - charges -
                qd = cjo* (m-1)*phi_b*((1-(vp-vn)/phi_b)^(-m+1)) - cjo* (m-1)*phi_b; 
                % - q -
                if(dev.nodeP) data.q(dev.nodeP) = data.i(dev.nodeP) + qd; end
                if(dev.nodeN) data.q(dev.nodeN) = data.i(dev.nodeN) - qd; end
                % - cap -
                Cd = cjo*((1-(vp-vn)/phi_b)^(-m)); 
                % - dq(v(t))/dv = C -
                if(dev.senPP) data.C(dev.senPP) = data.C(dev.senPP) +Cd; end
                if(dev.senNN) data.C(dev.senNN) = data.C(dev.senNN) +Cd; end
                if(dev.senPN) data.C(dev.senPN) = data.C(dev.senPN) -Cd; end
                if(dev.senNP) data.C(dev.senNP) = data.C(dev.senNP) -Cd; end
            end
    end

return