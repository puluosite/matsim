function ckt = addAnalysis(ckt, analysisType, analysisName, analysisParms)

if getAnalysisIndex(ckt, analysisName)~=0
    error(['Analysis ''',analysisName,''' already exists']);
end

analysis.type = analysisType;
analysis.name = analysisName;

% - common analysis parameters -
analysis.tol.vAbsTol = getParmValue(analysisParms, 1e-6,  'vAbsTol');
analysis.tol.vRelTol = getParmValue(analysisParms, 1e-3,  'vRelTol');
analysis.tol.iAbsTol = getParmValue(analysisParms, 1e-12, 'iAbsTol');
analysis.tol.iRelTol = getParmValue(analysisParms, 1e-3,  'iRelTol');
analysis.maxIter     = getParmValue(analysisParms, 50,    'maxIter');

switch analysis.type

    case 'dc'
        % - set algorithm handle -
        analysis.hRun = @analysisDC;
        
        % - parse analysis parameters -
        zeroIguess = zeros(ckt.numUnkns, 1);
        providedIguess = getParmValue(analysisParms, zeroIguess, 'iguess');
        analysis.numCoreUnkns = ckt.numUnkns;

        % - extra equations, extra unknowns, and sensitivity parameters -
        extraEqns  = getParmValue(analysisParms, [], 'extraEqns' );
        extraUnkns = getParmValue(analysisParms, [], 'extraUnkns');
        gradVars   = getParmValue(analysisParms, [], 'gradient'  );
        
        % - parse extra equations -
        analysis.extra.eqn       = parseDEC_DC(ckt, extraEqns);
        
        % - parse extra unknowns -
        [unkn, unknData]         = parseGamma(ckt, extraUnkns, 1);
        analysis.extra.unkn      = unkn;
        analysis.iguess.extra    = unknData.iguess;
        analysis.tol.extraAbsTol = unknData.absTol;
        analysis.tol.extraRelTol = unknData.relTol;       
        
        % - parse gradient variables for sensitivity ananlysis -
        analysis.grad.var        = parseGamma(ckt, gradVars, 1);
        analysis.grad.numGradVar = length(analysis.grad.var);
        analysis.grad.calcGrad   = analysis.grad.numGradVar & 1;

        % - sanity check -
        numExtraEqns  = length(analysis.extra.eqn);
        numExtraUnkns = length(analysis.extra.unkn);
        if numExtraEqns ~= numExtraUnkns
            error('Number of extra equations must be same as number of extra unknowns')
        end
        analysis.extra.numExtra   = numExtraEqns;        
        analysis.extraUnknIndices = analysis.numCoreUnkns + [1:analysis.extra.numExtra;];        
        
        % - all parameters passed -
        analysis.iguess.x = populateStateVector(ckt, providedIguess, zeroIguess);
        
    case 'tran'
        % - set algorithm handle -
        analysis.hRun = @analysisTran;
        
        % - parse analysis parameters -
        zeroIC = zeros(ckt.numUnkns, 1);
        providedIC           = getParmValue(analysisParms, zeroIC, 'ic'         );
        analysis.maxStepIter = getParmValue(analysisParms,     50, 'maxStepIter');
        analysis.nsteps      = getParmValue(analysisParms,    100, 'nsteps'     );
        analysis.tstop       = getParmValue(analysisParms,     [], 'tstop'      );
        analysis.diffFormula = getParmValue(analysisParms, 'bdf2', 'diffFormula');
        
        % - all parameters passed -
        analysis.ic.x        = populateStateVector(ckt, providedIC, zeroIC);

    case 'pss'
        % - set algorithm handle -
        analysis.hRun = @analysisPSS;        

        % - check for periodic sources in the circuit -
        [srcFreqs, fund] = getSrcFreqs(ckt);
        if length(srcFreqs) == 0
            % - autonomous circuit -
            analysis.forced = 0;
        elseif fund
            % - driven circuit -
            analysis.forced = 1;
            analysis.forcedT = 1/fund;
        else
            % - quasiperiodic circuit -
            error('QPSS is not implemented.')
        end

        % - parse analysis parameters -        
        zeroIguess = zeros(ckt.numUnkns, 1);
        providedIguess     = getParmValue(analysisParms, zeroIguess, 'iguess');
        analysis.tstab     = getParmValue(analysisParms,          0, 'tstab' );
        analysis.pssMethod = getParmValue(analysisParms, 'shooting', 'method');        
        switch analysis.pssMethod
            case 'shooting'
                analysis.diffFormula = getParmValue(analysisParms, 'bdf2', 'diffFormula');
                analysis.nsteps      = getParmValue(analysisParms,    100, 'nsteps'     );
                analysis.numCoreUnkns = ckt.numUnkns;
        end

        % - extra equations, extra unknowns, and sensitivity parameters -
        extraEqns  = getParmValue(analysisParms, [], 'extraEqns' );
        extraUnkns = getParmValue(analysisParms, [], 'extraUnkns');
        gradVars   = getParmValue(analysisParms, [], 'gradient'  );

        % - parse extra equations -
        analysis.extra.eqn       = parseDEC_PSS(ckt, extraEqns);
        
        % - parse extra unknowns -
        [unkn, unknData]         = parseGamma(ckt, extraUnkns, 1);
        analysis.extra.unkn      = unkn;
        analysis.iguess.extra    = unknData.iguess;
        analysis.tol.extraAbsTol = unknData.absTol;
        analysis.tol.extraRelTol = unknData.relTol;       
        
        % - parse gradient variables for sensitivity ananlysis -
        analysis.grad.var        = parseGamma(ckt, gradVars, 1);
        analysis.grad.numGradVar = length(analysis.grad.var);
        analysis.grad.calcGrad   = analysis.grad.numGradVar & 1;

        % - all parameters passed -
        analysis.iguess.x  = populateStateVector(ckt, providedIguess, zeroIguess);        
        
        % - sanity check -
        numExtraEqns  = length(analysis.extra.eqn);
        numExtraUnkns = length(analysis.extra.unkn);
        if numExtraEqns ~= numExtraUnkns
            error('Number of extra equations must be same as number of extra unknowns')
        end
        analysis.extra.numExtra   = numExtraEqns;        
        analysis.extraUnknIndices = analysis.numCoreUnkns + [1:analysis.extra.numExtra;];        
        for e=1:analysis.extra.numExtra
            if strcmp(analysis.extra.eqn{e}.type, 'oscillation period') & analysis.forced
                % - forced circuit -
                error('Can not constraint a period of a forced circuit.');
            end
        end   
        for i=1:analysis.extra.numExtra
            switch analysis.extra.unkn{i}.type
                case 'oscillation period'
                    if analysis.forced
                        % - forced circuit -
                        error('Period of a forced circuit can not be an unknown (use periodic source parameter).');
                    end
                case 'circuit parameter'
                    if strcmp(analysis.extra.unkn{i}.name, 'freq')
                        if ~isequal(analysis.periodicSrcIndices, ...
                                sort(analysis.extra.unkn{i}.deviceIndices));
                            error('Periodic sources and sources with unknown frequency do not agree.');
                        end
                    end
            end
        end

    otherwise
        ckt = reportError(ckt, ['Unknown analysis type ''',analysisType,'''']);
        return

end

ckt.numAnalyses = ckt.numAnalyses+1;
ckt.analyses{ckt.numAnalyses} = analysis;

return










% -------------------------------------------------------------------------
% -                                                                       -
% -      Parse variables for sensitivity ananlysis or extra unknowns      -
% -                                                                       -
% -------------------------------------------------------------------------

function [var, unknData] = parseGamma(ckt, vars, isUnknown)
% - parse gradient variables -
var = {};
numVar = length(vars);
if isUnknown
    iguess = zeros(numVar,1);
    absTol = zeros(numVar,1);
    relTol = zeros(numVar,1);
end
for i = 1:numVar
    varParms = vars{i};
    var{i}.type    = getParmValue(varParms,    [], 'type'   );
    if isUnknown
        var{i}.damping = getParmValue(varParms,  0.1, 'damping');
        var{i}.absTol  = getParmValue(varParms,    0, 'absTol' );
        var{i}.relTol  = getParmValue(varParms, 1e-3, 'relTol' );
    end
    switch var{i}.type
        case 'oscillation period'
            var{i}.iguess        = getParmValue(varParms, [], 'iguess');
            var{i}.name          = 'T';
        case 'circuit parameter'                      
            var{i}.name          = getParmValue(varParms, [], 'name');
            var{i}.deviceNames   = getParmValue(varParms, [], 'deviceNames');
            var{i}.multipliers   = getParmValue(varParms, [], 'multipliers');
            var{i}.deviceIndices = getDeviceIndices(ckt, var{i}.deviceNames);
            if length(var{i}.multipliers)
                % - multipliers are provided -
                if length(var{i}.multipliers) ~= length(var{i}.deviceIndices)
                    error('Number of multipliers does not match the number of devices')
                end
            else
                % - extracting multipliers (not provided) -
                for d=1:length(var{i}.deviceIndices)
                    parmValue(d)          = getDeviceParm(ckt, var{i}.deviceIndices(d), var{i}.name);
                    var{i}.multipliers(d) = parmValue(d)/parmValue(1);
                end
            end
            if isUnknown
                parmValue     = getDeviceParm(ckt, var{i}.deviceIndices(1), var{i}.name);
                var{i}.iguess = getParmValue(varParms, parmValue/var{i}.multipliers(1), 'iguess');
            end
        otherwise
            error(['Unsupprted type for gradient variable ''',var{i}.type,''''])
    end
    if isUnknown
        iguess(i) = var{i}.iguess;
        absTol(i) = var{i}.absTol;
        relTol(i) = var{i}.relTol;
    end
end
if isUnknown
    unknData.iguess = iguess;
    unknData.absTol = absTol;
    unknData.relTol = relTol;
else
    unknData = [];
end
return








% -------------------------------------------------------------------------
% -                                                                       -
% -               Parse equations for DECs of DC analysis                 -
% -                                                                       -
% -------------------------------------------------------------------------

function [eqn] = parseDEC_DC(ckt, DECeqns)

eqn = {};
N = length(DECeqns);

for i = 1:N
    % - parse DECs -
    eqnParms = DECeqns{i};
    eqn{i}.type  = getParmValue(eqnParms, [], 'type');
    eqn{i}.value = getParmValue(eqnParms, [], 'value');
    switch eqn{i}.type
        case 'fix'
            eqn{i}.signalName  = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex = getUnknIndex(ckt, eqn{i}.signalName);
        case 'power consumption'                      
            eqn{i}.sourceName  = getParmValue(eqnParms, [], 'source');
            eqn{i}.sourceIndex = getDeviceIndex(ckt, eqn{i}.sourceName);
        case 'special fix Vgs-Vds'                      
            eqn{i}.deviceName  = getParmValue(eqnParms, [], 'deviceName');
            eqn{i}.deviceIndex = getDeviceIndex(ckt, eqn{i}.deviceName);
            eqn{i}.nodeD       = ckt.devices{eqn{i}.deviceIndex}.nodeD;
            eqn{i}.nodeG       = ckt.devices{eqn{i}.deviceIndex}.nodeG;
            eqn{i}.nodeS       = ckt.devices{eqn{i}.deviceIndex}.nodeS;
        case 'special scaled current'
            eqn{i}.signalName  = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex = getUnknIndex(ckt, eqn{i}.signalName);
            eqn{i}.sourceName  = getParmValue(eqnParms, [], 'source');
            eqn{i}.sourceIndex = getDeviceIndex(ckt, eqn{i}.sourceName);
        otherwise
            error(['Unsupprted equation type ''',eqn{i}.type,''''])
    end
end
return








% -------------------------------------------------------------------------
% -                                                                       -
% -               Parse equations for DECs of PSS analysis                -
% -                                                                       -
% -------------------------------------------------------------------------

function [eqn] = parseDEC_PSS(ckt, DECeqns)

eqn = {};
N = length(DECeqns);

for i = 1:N
    % - parse DECs -
    eqnParms = DECeqns{i};
    eqn{i}.type  = getParmValue(eqnParms, [], 'type');
    eqn{i}.value = getParmValue(eqnParms, [], 'value');
    switch eqn{i}.type
        case 'initial condition'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
        case 'oscillation period'
        case 'power consumption'                      
            eqn{i}.sourceName    = getParmValue(eqnParms, [], 'source');
            eqn{i}.sourceIndex   = getDeviceIndex(ckt, eqn{i}.sourceName);
        case 'minus power consumption'                      
            eqn{i}.sourceName    = getParmValue(eqnParms, [], 'source');
            eqn{i}.sourceIndex   = getDeviceIndex(ckt, eqn{i}.sourceName);
        case 'harmonic magnitude'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.harmonic      = getParmValue(eqnParms, [], 'harmonic');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
        case 'harmonic imaginary'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.harmonic      = getParmValue(eqnParms, [], 'harmonic');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
        case 'period set by sources'
            eqn{i}.parmName      = 'freq';
            eqn{i}.deviceNames   = getParmValue(eqnParms, [], 'deviceNames');
            eqn{i}.deviceIndices = getDeviceIndices(ckt, eqn{i}.deviceNames);
        case 'harmonic distortion'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.harmonic      = getParmValue(eqnParms, [], 'harmonic');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
        case 'harmonic phase'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.harmonic      = getParmValue(eqnParms, [], 'harmonic');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
        case 'special [R-1/gm=0]'
            eqn{i}.resName       = getParmValue(eqnParms, [], 'resName');
            eqn{i}.mosName       = getParmValue(eqnParms, [], 'mosName');
            eqn{i}.resIndex      = getDeviceIndex(ckt, eqn{i}.resName);
            eqn{i}.mosIndex      = getDeviceIndex(ckt, eqn{i}.mosName);
        case 'special [G-gm=0]'
            eqn{i}.resName       = getParmValue(eqnParms, [], 'resName');
            eqn{i}.mosName       = getParmValue(eqnParms, [], 'mosName');
            eqn{i}.resIndex      = getDeviceIndex(ckt, eqn{i}.resName);
            eqn{i}.mosIndex      = getDeviceIndex(ckt, eqn{i}.mosName);
        case 'special fix at Vdd-Vc/2'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
            eqn{i}.time          = getParmValue(eqnParms, [], 'time'); 
            eqn{i}.indVdd        = getDeviceIndex(ckt, 'Vdd');
            eqn{i}.indVc         = getDeviceIndex(ckt, 'Vc');
        case 'waveform sample'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
            eqn{i}.time          = getParmValue(eqnParms, [], 'time');
        case 'waveform slope'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
            eqn{i}.time          = getParmValue(eqnParms, [], 'time');
        case 'duty cycle'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
            eqn{i}.signalLevel   = getParmValue(eqnParms, [], 'signalLevel');
        case 'ppv harmonic magnitude'
            eqn{i}.eqnName       = getParmValue(eqnParms, [], 'equation');
            eqn{i}.harmonic      = getParmValue(eqnParms, [], 'harmonic');
            eqn{i}.eqnIndex      = getEqnIndex(ckt, eqn{i}.eqnName);
        case 'ppv dc'
            eqn{i}.eqnName       = getParmValue(eqnParms, [], 'equation');
            eqn{i}.eqnIndex      = getEqnIndex(ckt, eqn{i}.eqnName);
        case 'duty cycle'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
            eqn{i}.signalLevel   = getParmValue(eqnParms, [], 'signalLevel');
        case 'intercrossing'
            eqn{i}.signalNameP   = getParmValue(eqnParms, [], 'signal1');
            eqn{i}.signalNameN   = getParmValue(eqnParms, [], 'signal2');
            eqn{i}.signalIndexP  = getUnknIndex(ckt, eqn{i}.signalNameP);
            eqn{i}.signalIndexN  = getUnknIndex(ckt, eqn{i}.signalNameN);
        case 'opposite slopes'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
            eqn{i}.signalLevel   = getParmValue(eqnParms, [], 'signalLevel');
        case 'slopes ratio'
            eqn{i}.signalName    = getParmValue(eqnParms, [], 'signal');
            eqn{i}.signalIndex   = getUnknIndex(ckt, eqn{i}.signalName);
            eqn{i}.signalLevel   = getParmValue(eqnParms, [], 'signalLevel');
        case 'cw'
            % - no additional parameters -
        case 'cc'
            eqn{i}.offsetFreq    = getParmValue(eqnParms, [], 'offsetFreq');
        case 'cw+cc'
            eqn{i}.offsetFreq    = getParmValue(eqnParms, [], 'offsetFreq');
        case 'pnoise'
            eqn{i}.offsetFreq    = getParmValue(eqnParms, [], 'offsetFreq');
        case 'special [Q-factor]'
            eqn{i}.indName       = getParmValue(eqnParms, [], 'indName');
            eqn{i}.resName       = getParmValue(eqnParms, [], 'resName');
            eqn{i}.indIndex      = getDeviceIndex(ckt, eqn{i}.indName);
            eqn{i}.resIndex      = getDeviceIndex(ckt, eqn{i}.resName);
            Rvalue   = getDeviceParm(ckt, eqn{i}.resIndex, 'res');
            Lvalue   = getDeviceParm(ckt, eqn{i}.indIndex, 'ind');
            eqn{i}.k = Lvalue/Rvalue;            
        otherwise
            error(['Unsupprted equation type ''',eqn{i}.type,''''])
    end
end
return











% -------------------------------------------------------------------------
% -                                                                       -
% -    Parse values of state variables for initial condition or guess     -
% -                                                                       -
% -------------------------------------------------------------------------

function [x] = populateStateVector(ckt, data, x)
if iscell(data)
    % - data is a cell, e.g., {'v(dd)', 5, 'i(Vdd)', -0.001} -
    for i=1:length(data)/2
        unknName  = data{2*(i-1)+1};
        unknValue = data{2*i};
        unknIndex = getUnknIndex(ckt, unknName);
        if unknIndex
            x(unknIndex) = unknValue;
        else
            error(['Invalid circuit unknown name ''',unknName,'''']);
        end
    end
else
    % - data is a vector, e.g., [5 -0.001]' -
    x(1:ckt.numUnkns) = data(:);
end
return
