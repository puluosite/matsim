function [data, dev] = loadMOSFET_Rabaey(ckt, deviceIndex, data, info, dev, thisDeviceParmIndices)

global MODE_DC
global MODE_TRAN
global MODE_SEN
global MODE_SEN2

% - flicker noise model-
useId = 1;

if info.mode >= MODE_DC
    % - constants -
    eox = 3.45E-11;
    k   = 1.38062e-23;
    T   = 300;
    % - device geometry -
    W = dev.W;
    L = dev.L;
    % - model static parameters -
    type   =      ckt.models{dev.model}.type;
    vt0    = type*ckt.models{dev.model}.vt0;
    gamma  = type*ckt.models{dev.model}.gamma;
    beta   = type*ckt.models{dev.model}.beta;
    lambda = type*ckt.models{dev.model}.lambda;
    bWL    = beta*W/L;
    % - model dynamic parameters -
    tox   = ckt.models{dev.model}.tox;
    cov   = ckt.models{dev.model}.cov;
    cox   = eox/tox;
    % - model noise -
    kf = ckt.models{dev.model}.kf;
    % - variables -
    if(dev.nodeD) vd = data.x(dev.nodeD); else vd = 0; end
    if(dev.nodeG) vg = data.x(dev.nodeG); else vg = 0; end
    if(dev.nodeS) vs = data.x(dev.nodeS); else vs = 0; end
    if(dev.nodeB) vb = data.x(dev.nodeB); else vb = 0; end
    % - voltages across -
    if type*vd >= type*vs
        % - source and drain are in place -
        reverse = 0; 
        vds = type*(vd-vs);  vdb = type*(vd-vb);
        vsb = type*(vs-vb);  vgb = type*(vg-vb);
        vgd = type*(vg-vd);  vgs = type*(vg-vs);
        % - vector indices -
        nodeD = dev.nodeD;   nodeS = dev.nodeS;
        % - matrix indices -
        senDD = dev.senDD;   senSD = dev.senSD;
        senDG = dev.senDG;   senSG = dev.senSG;
        senDS = dev.senDS;   senSS = dev.senSS;
        senDB = dev.senDB;   senSB = dev.senSB;
    else
        % - interchange source and drain -
        reverse = 1;
        vds = type*(vs-vd);  vdb = type*(vs-vb);
        vsb = type*(vd-vb);  vgb = type*(vg-vb);
        vgd = type*(vg-vs);  vgs = type*(vg-vd);
        % - vector indices -
        nodeD = dev.nodeS;   nodeS = dev.nodeD;
        % - matrix indices -
        senSS = dev.senDD;   senSG = dev.senDG;
        senSD = dev.senDS;   senSB = dev.senDB;
        senDS = dev.senSD;   senDG = dev.senSG;
        senDD = dev.senSS;   senDB = dev.senSB;
    end
    % - analysis of threshold in the presence of body effect -
    % phi = 0.6;
    % vt = vt0 + gamma * (sqrt(phi + vsb) - sqrt(phi));
    vt = vt0;
    dvtdvsb = 0;
    % - currents/(trans)conductances -
    if vgs < vt
        % - cutoff - 
        region = 0;
        ids = 0;
        gm  = 0;
        gds = 0;
        gdb = 0;
    elseif vds < vgs-vt
        % - linear -
        region = 1;
        % - current -
        ids = bWL*((vgs-vt)*vds - 0.5*vds*vds)*(1+lambda*vds);
        % - gm = dids/dvgs -
        gm  = bWL*vds*(1+lambda*vds);
        % - gds = dids/dvds -
        gds = bWL*((vgs-vt)*(1+2*lambda*vds)-vds-1.5*lambda*vds*vds);
        % - gdb = dids/dvsb = dids/dvt * dvt/dvsb
        gdb = -bWL*vds*(1+lambda*vds) * dvtdvsb;
    else
        % - saturation -
        region = 2;
        % - current -
        ids  = 0.5*bWL*(vgs-vt)*(vgs-vt)*(1+lambda*vds);
        % - gm = dids/dvgs -
        gm = bWL*(vgs-vt)*(1+lambda*vds);
        % - gds = dids/dvds -
        gds = 0.5*bWL*(vgs-vt)*(vgs-vt)*lambda;
        % - gdb = dids/dvsb = dids/dvt * dvt/dvsb
        gdb = -bWL*(vgs-vt)*(1+lambda*vds) * dvtdvsb;
    end
    dev.region = region;
    % - i -
    ids = type*ids;
    if(nodeD) data.i(nodeD) = data.i(nodeD) +ids; end
    if(nodeS) data.i(nodeS) = data.i(nodeS) -ids; end
    % - G -
    gds = max(gds, ckt.gmin);
    if(senDD) data.G(senDD) = data.G(senDD) +gds          ; end
    if(senDS) data.G(senDS) = data.G(senDS) -gds -gm +gdb ; end
    if(senDG) data.G(senDG) = data.G(senDG)      +gm      ; end
    if(senDB) data.G(senDB) = data.G(senDB)          -gdb ; end
    if(senSD) data.G(senSD) = data.G(senSD) -gds          ; end
    if(senSS) data.G(senSS) = data.G(senSS) +gds +gm -gdb ; end
    if(senSG) data.G(senSG) = data.G(senSG)      -gm      ; end
    if(senSB) data.G(senSB) = data.G(senSB)          +gdb ; end
    dev.gds = gds;
    % - white noise -
    multNw = 8/3*k*T;
    if gm+gds >= 0
        Nw = multNw*(gm+gds);                                                                       %     Nw = multNw*(gm+gds)*kf/1e-25;
    else
        Nw = NaN;
%         disp([num2str(dev.name), '  : channel thermal noise computation :  gm + gds < 0'])      
        error([num2str(dev.name), '  : channel thermal noise computation :  gm + gds < 0'])      
    end
    % HACK
    Nw = 0;
    if(senDD) data.Nw(senDD) = data.Nw(senDD) +Nw ; end
    if(senDS) data.Nw(senDS) = data.Nw(senDS) -Nw ; end
    if(senSD) data.Nw(senSD) = data.Nw(senSD) -Nw ; end
    if(senSS) data.Nw(senSS) = data.Nw(senSS) +Nw ; end
    % - flicker noise -
    if cox ~= 0
        if useId
            Nf = kf*abs(ids)/(cox*W*L);
        else
            Nf = kf*gm*gm/(cox*W*L);
            if gm < 0
                error([num2str(dev.name), '  : channel flicker noise computation :  gm < 0'])
            end
        end
    else
        Nf = NaN;
    end
    % HACK
    Nf = 0;
    if(senDD) data.Nf(senDD) = data.Nf(senDD) +Nf ; end
    if(senDS) data.Nf(senDS) = data.Nf(senDS) -Nf ; end
    if(senSD) data.Nf(senSD) = data.Nf(senSD) -Nf ; end
    if(senSS) data.Nf(senSS) = data.Nf(senSS) +Nf ; end
    if info.mode >= MODE_TRAN
        % - mos dynamics -
        % - assume drain and source are in place - 
        % - assume saturation -
        capov = W*cov;
        % - caps -
        cgs = capov + 2/3*W*L*cox;
        cgd = capov;
        % - charges -
        qgs = cgs*(vg-vs);
        qgd = cgd*(vg-vd);
        % - q -
        if(dev.nodeD) data.q(dev.nodeD) = data.q(dev.nodeD)      -qgd ; end % +qdb
        if(dev.nodeG) data.q(dev.nodeG) = data.q(dev.nodeG) +qgs +qgd ; end %      +qgb
        if(dev.nodeS) data.q(dev.nodeS) = data.q(dev.nodeS) -qgs      ; end %           +qsb
       %if(dev.nodeB) data.q(dev.nodeB) = data.q(dev.nodeB)           ; end % -qdb -qsb -qgb
        % - C -
        if(dev.senDD) data.C(dev.senDD) = data.C(dev.senDD)      +cgd ; end % +cdb
        if(dev.senDG) data.C(dev.senDG) = data.C(dev.senDG)      -cgd ; end %
       %if(dev.senDS) data.C(dev.senDS) = data.C(dev.senDS)           ; end %
       %if(dev.senDB) data.C(dev.senDB) = data.C(dev.senDB)           ; end % -cdb
        if(dev.senGD) data.C(dev.senGD) = data.C(dev.senGD)      -cgd ; end %
        if(dev.senGG) data.C(dev.senGG) = data.C(dev.senGG) +cgs +cgd ; end %      +cgb
        if(dev.senGS) data.C(dev.senGS) = data.C(dev.senGS) -cgs      ; end %
       %if(dev.senGB) data.C(dev.senGB) = data.C(dev.senGB)           ; end %      -cgb
       %if(dev.senSD) data.C(dev.senSD) = data.C(dev.senSD)           ; end %
        if(dev.senSG) data.C(dev.senSG) = data.C(dev.senSG) -cgs      ; end %
        if(dev.senSS) data.C(dev.senSS) = data.C(dev.senSS) +cgs      ; end %           +csb
       %if(dev.senSB) data.C(dev.senSB) = data.C(dev.senSB)           ; end %           -csb
       %if(dev.senBD) data.C(dev.senBD) = data.C(dev.senBD)           ; end % -cdb
       %if(dev.senBG) data.C(dev.senBG) = data.C(dev.senBG)           ; end %      -cgb
       %if(dev.senBS) data.C(dev.senBS) = data.C(dev.senBS)           ; end %           -csb
       %if(dev.senBB) data.C(dev.senBB) = data.C(dev.senBB)           ; end % +cdb +cgb +csb
        if info.mode >= MODE_SEN                    
            % - loop through sensitivity parameters present in this device -
            for par = thisDeviceParmIndices
                switch info.parms{par}.name
                    case 'W'
                        % - di/dpar -
                        didsdpar = ids/W;
                        % - dq/dpar -
                        dqgs = qgs/W;
                        dqgd = qgd/W;
                        if info.mode >= MODE_SEN2
                            % - dC/dpar -
                            dcgs = cgs/W;
                            dcgd = cgd/W;
                            % - dG/dpar -
                            dgds = gds/W;
                            dgm  = gm /W;
                            dgdb = gdb/W;
                            % - sensitivity d(W*L)/dW for flicker noise sensitivity -
                            dWL = L;
                        end
                    case 'L'
                        % - di/dpar -
                        didsdpar = -ids/L;
                        % - dq/dpar -
                        dqgs = 2/3*W*cox*(vg-vs);
                        dqgd = 0;
                        if info.mode >= MODE_SEN2
                            % - dC/dpar -
                            dcgs = 2/3*W*cox;
                            dcgd = 0;
                            % - dG/dpar -
                            dgds = -gds/L;
                            dgm  = -gm /L;
                            dgdb = -gdb/L;
                            % - sensitivity d(W*L)/dL for flicker noise sensitivity -
                            dWL = W;
                        end
                    otherwise
                        error('No such MOSFET parameter')
                end
                % - di/dpar -
                if(nodeD) data.didpar(nodeD, par) = data.didpar(nodeD, par) +didsdpar; end
                if(nodeS) data.didpar(nodeS, par) = data.didpar(nodeS, par) -didsdpar; end
                % - dq/dpar -
                if(dev.nodeD) data.dqdpar(dev.nodeD, par) = data.dqdpar(dev.nodeD, par)       -dqgd ; end % +dqdb       
                if(dev.nodeG) data.dqdpar(dev.nodeG, par) = data.dqdpar(dev.nodeG, par) +dqgs +dqgd ; end %       +dqgb 
                if(dev.nodeS) data.dqdpar(dev.nodeS, par) = data.dqdpar(dev.nodeS, par) -dqgs       ; end %              +dqsb 
               %if(dev.nodeB) data.dqdpar(dev.nodeB, par) = data.dqdpar(dev.nodeB, par)             ; end % -dqdb  -dqgb -dqsb                   
                if info.mode >= MODE_SEN2
                    % - dNw/dpar (white noise sensitivity)-
                    dNw = multNw*(dgm+dgds);
                    if(senDD) data.dNw_dpar{par}(senDD) = data.dNw_dpar{par}(senDD) +dNw ; end
                    if(senDS) data.dNw_dpar{par}(senDS) = data.dNw_dpar{par}(senDS) -dNw ; end
                    if(senSD) data.dNw_dpar{par}(senSD) = data.dNw_dpar{par}(senSD) -dNw ; end
                    if(senSS) data.dNw_dpar{par}(senSS) = data.dNw_dpar{par}(senSS) +dNw ; end
                    % - dNf/dpar (flicker noise sensitivity)-
                    if cox ~= 0
                        if useId
                            dabsids = didsdpar*sign(ids);
                            dNf = ( kf*dabsids  * cox*W*L - kf*abs(ids) * cox*dWL ) / (cox*W*L) / (cox*W*L);
                        else
                            dNf = ( kf*2*gm*dgm * cox*W*L - kf*gm*gm    * cox*dWL ) / (cox*W*L) / (cox*W*L);
                        end
                    else
                        dNf = NaN;
                    end
                    if(senDD) data.dNf_dpar{par}(senDD) = data.dNf_dpar{par}(senDD) +dNf ; end
                    if(senDS) data.dNf_dpar{par}(senDS) = data.dNf_dpar{par}(senDS) -dNf ; end
                    if(senSD) data.dNf_dpar{par}(senSD) = data.dNf_dpar{par}(senSD) -dNf ; end
                    if(senSS) data.dNf_dpar{par}(senSS) = data.dNf_dpar{par}(senSS) +dNf ; end
                end               
            end
            if info.mode >= MODE_SEN2
                if par
                    % - dG/dpar -
                    if(senDD) data.dGdpar{par}(senDD) = data.dGdpar{par}(senDD) +dgds            ; end
                    if(senDG) data.dGdpar{par}(senDG) = data.dGdpar{par}(senDG)       +dgm       ; end
                    if(senDS) data.dGdpar{par}(senDS) = data.dGdpar{par}(senDS) -dgds -dgm +dgdb ; end
                    if(senDB) data.dGdpar{par}(senDB) = data.dGdpar{par}(senDB)            -dgdb ; end
                    if(senSD) data.dGdpar{par}(senSD) = data.dGdpar{par}(senSD) -dgds            ; end
                    if(senSG) data.dGdpar{par}(senSG) = data.dGdpar{par}(senSG)       -dgm       ; end
                    if(senSS) data.dGdpar{par}(senSS) = data.dGdpar{par}(senSS) +dgds +dgm -dgdb ; end
                    if(senSB) data.dGdpar{par}(senSB) = data.dGdpar{par}(senSB)            +dgdb ; end
                    % - dC/dpar -
                    if(dev.senDD) data.dCdpar{par}(dev.senDD) = data.dCdpar{par}(dev.senDD)        +dcgd ; end % +dcdb
                    if(dev.senDG) data.dCdpar{par}(dev.senDG) = data.dCdpar{par}(dev.senDG)        -dcgd ; end % 
                   %if(dev.senDS) data.dCdpar{par}(dev.senDS) = data.dCdpar{par}(dev.senDS)              ; end % 
                   %if(dev.senDB) data.dCdpar{par}(dev.senDB) = data.dCdpar{par}(dev.senDB)              ; end % -dcdb
                    if(dev.senGD) data.dCdpar{par}(dev.senGD) = data.dCdpar{par}(dev.senGD)        -dcgd ; end % 
                    if(dev.senGG) data.dCdpar{par}(dev.senGG) = data.dCdpar{par}(dev.senGG)  +dcgs +dcgd ; end %       +dcgb
                    if(dev.senGS) data.dCdpar{par}(dev.senGS) = data.dCdpar{par}(dev.senGS)  -dcgs       ; end % 
                   %if(dev.senGB) data.dCdpar{par}(dev.senGB) = data.dCdpar{par}(dev.senGB)              ; end %       -dcgb
                   %if(dev.senSD) data.dCdpar{par}(dev.senSD) = data.dCdpar{par}(dev.senSD)              ; end % 
                    if(dev.senSG) data.dCdpar{par}(dev.senSG) = data.dCdpar{par}(dev.senSG)  -dcgs       ; end % 
                    if(dev.senSS) data.dCdpar{par}(dev.senSS) = data.dCdpar{par}(dev.senSS)  +dcgs       ; end %             +dcsb
                   %if(dev.senSB) data.dCdpar{par}(dev.senSB) = data.dCdpar{par}(dev.senSB)              ; end %             -dcsb
                   %if(dev.senBD) data.dCdpar{par}(dev.senBD) = data.dCdpar{par}(dev.senBD)              ; end % -dcdb
                   %if(dev.senBG) data.dCdpar{par}(dev.senBG) = data.dCdpar{par}(dev.senBG)              ; end %       -dcgb
                   %if(dev.senBS) data.dCdpar{par}(dev.senBS) = data.dCdpar{par}(dev.senBS)              ; end %             -dcsb
                   %if(dev.senBB) data.dCdpar{par}(dev.senBB) = data.dCdpar{par}(dev.senBB)              ; end % +dcdb +dcgb +dcsb
                end
                switch region
                    case 0
                        % - cutoff - 
                        dgmdvds  = 0;
                        dgmdvgs  = 0;
                        dgdsdvds = 0;
                        dgdsdvgs = 0;
                        dgdbdvds = 0;
                        dgdbdvgs = 0;
                    case 1
                        % - linear -
                        dgmdvds  = bWL*(1+2*lambda*vds);
                        dgmdvgs  = 0;
                        dgdsdvds = bWL*((vgs-vt)*2*lambda-1-3*lambda*vds); 
                        dgdsdvgs = bWL*(1+2*lambda*vds);
                        % - HARD CODE -
                        dgdbdvds = 0;
                        dgdbdvgs = 0;
                    case 2
                        dgmdvds = bWL*(vgs-vt)*lambda;
                        dgmdvgs = bWL*(1+lambda*vds);
                        dgdsdvds = 0;
                        dgdsdvgs = bWL*(vgs-vt)*lambda;
                        % - HARD CODE -
                        dgdbdvds = 0;
                        dgdbdvgs = 0;
                end
                % - dG/dv -
                dgdsdvds = type*dgdsdvds;
                dgdsdvgs = type*dgdsdvgs;
                dgmdvds  = type*dgmdvds ;
                dgmdvgs  = type*dgmdvgs ;
                % - change in vd causes only vds to change -
                % - change in vg causes only vgs to change -
                % - change in vs causes both vds and vgs to change in the opposite direction -
                dgdsdv(1) = +dgdsdvds;          dgmdv(1) = +dgmdvds;         dgdbdv(1) = +dgdbdvds;          node(1) = nodeD;
                dgdsdv(2) = +dgdsdvgs;          dgmdv(2) = +dgmdvgs;         dgdbdv(2) = +dgdbdvgs;          node(2) = dev.nodeG;
                dgdsdv(3) = -dgdsdvds-dgdsdvgs; dgmdv(3) = -dgmdvds-dgmdvgs; dgdbdv(3) = -dgdbdvds-dgdbdvgs; node(3) = nodeS;
                % - dNw/dv (white noise senitivity) -
                dNw_dv = multNw*(dgmdv+dgdsdv);
                % - dNf/dv (flicker noise senitivity) -
                if cox ~= 0
                    if useId
                        didsdv(1) = +gds;
                        didsdv(2) = +gm;
                        didsdv(3) = -gds-gm;
                        dabsidsdv = didsdv*sign(ids);
                        dNf_dv = kf*dabsidsdv/(cox*W*L);
                    else
                        dNf_dv = kf*2*gm*dgmdv/(cox*W*L);
                    end
                else
                    dNf_dv = NaN*dgmdv;
                end
                for i=1:3
                    n = node(i);
                    if n > 0
                        % - dG/dv -
                        if(senDD) data.dGdv{n}(senDD) = data.dGdv{n}(senDD) +dgdsdv(i)                      ; end
                        if(senDG) data.dGdv{n}(senDG) = data.dGdv{n}(senDG)            +dgmdv(i)            ; end
                        if(senDS) data.dGdv{n}(senDS) = data.dGdv{n}(senDS) -dgdsdv(i) -dgmdv(i) +dgdbdv(i) ; end
                        if(senDB) data.dGdv{n}(senDB) = data.dGdv{n}(senDB)                      -dgdbdv(i) ; end
                        if(senSD) data.dGdv{n}(senSD) = data.dGdv{n}(senSD) -dgdsdv(i)                      ; end
                        if(senSG) data.dGdv{n}(senSG) = data.dGdv{n}(senSG)            -dgmdv(i)            ; end
                        if(senSS) data.dGdv{n}(senSS) = data.dGdv{n}(senSS) +dgdsdv(i) +dgmdv(i) -dgdbdv(i) ; end
                        if(senSB) data.dGdv{n}(senSB) = data.dGdv{n}(senSB)                      +dgdbdv(i) ; end
                        % - dNw/dv (white noise senitivity) -
                        if(senDD) data.dNw_dv{n}(senDD) = data.dNw_dv{n}(senDD) +dNw_dv(i) ; end
                        if(senDS) data.dNw_dv{n}(senDS) = data.dNw_dv{n}(senDS) -dNw_dv(i) ; end
                        if(senSD) data.dNw_dv{n}(senSD) = data.dNw_dv{n}(senSD) -dNw_dv(i) ; end
                        if(senSS) data.dNw_dv{n}(senSS) = data.dNw_dv{n}(senSS) +dNw_dv(i) ; end
                        % - dNf/dv (flicker noise senitivity) -
                        if(senDD) data.dNf_dv{n}(senDD) = data.dNf_dv{n}(senDD) +dNf_dv(i) ; end
                        if(senDS) data.dNf_dv{n}(senDS) = data.dNf_dv{n}(senDS) -dNf_dv(i) ; end
                        if(senSD) data.dNf_dv{n}(senSD) = data.dNf_dv{n}(senSD) -dNf_dv(i) ; end
                        if(senSS) data.dNf_dv{n}(senSS) = data.dNf_dv{n}(senSS) +dNf_dv(i) ; end
                    end
                end
                % - specifically for op amp DEC experiment -
                if par
                    if isfield(info, 'time') & ~info.time
                        dev.t0.gm       = gm;
                        dev.t0.dgmdW    = dgm;
                        dev.t0.xIndices = node;
                        dev.t0.dgmdx    = dgmdv;
                    end
                end
            end                    
        end
    end
end
