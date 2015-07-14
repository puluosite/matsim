function ckt = analysisDC(ckt, analysisIndex)
global dcAnIndex

dcAnIndex = analysisIndex;
ckt = createToleranceVectors(ckt);

% ---  initialize iteration counter ---
ckt.analyses{analysisIndex}.iter = 0;

ckt.analyses{analysisIndex}.grad.calcGradStatus = ckt.analyses{analysisIndex}.grad.calcGrad;

% - set device parameters -
for i=1:ckt.analyses{analysisIndex}.extra.numExtra
    if strcmp(ckt.analyses{analysisIndex}.extra.unkn{i}.type, 'circuit parameter')
        parmName = ckt.analyses{analysisIndex}.extra.unkn{i}.name;
        parmValue = ckt.analyses{analysisIndex}.extra.unkn{i}.iguess;
        devIndices = ckt.analyses{analysisIndex}.extra.unkn{i}.deviceIndices;
        multipliers = ckt.analyses{analysisIndex}.extra.unkn{i}.multipliers;
        ckt = setDevParms(ckt, devIndices, parmName, parmValue*multipliers);
    end
    ckt.analyses{analysisIndex}.iguess.extra(i) = ckt.analyses{analysisIndex}.extra.unkn{i}.iguess;
end

% - function handles and parameters for nonlinear solver -
solverParms = {@initGuess, @f_dfdx, @damp, @checkConv,...
    ckt.analyses{dcAnIndex}.tol.absTol,...
    ckt.analyses{dcAnIndex}.tol.relTol,...
    ckt.analyses{dcAnIndex}.maxIter};

% - call nonlinear solver -
[ckt,result] = nonLinearSolver(ckt, 'Newton', solverParms);

% - check if solver did the job -
if result.nonConv == 0
%     result.iter
    % - if DC solution gradient calculation was requested -
    if ckt.analyses{analysisIndex}.grad.calcGradStatus
        % - set flag to indicate it's time to calculate the gradient -
        ckt.analyses{analysisIndex}.grad.calcGradStatus = 2;
    end
    % - calculate function and Jacobian at solution point -
    [ckt, result.soln.f, result.soln.dfdx] = feval(@f_dfdx, ckt, result.soln.x);
    ckt.analyses{dcAnIndex}.soln = result.soln;
    ckt.analyses{dcAnIndex}.iter = result.iter;
else
    ckt = reportError(ckt, ...
        ['Analysis ''',ckt.analyses{dcAnIndex}.name,''' did not converge']);
    return
end
return






% -------------------------------------------------------------------------
% -                                                                       -
% -      Absolute and relative tolerance vectors for analysis unknowns    -
% -                                                                       -
% -------------------------------------------------------------------------

function ckt = createToleranceVectors(ckt)
global dcAnIndex
global VOLTAGE_UNIT
global CURRENT_UNIT

numExtra = ckt.analyses{dcAnIndex}.extra.numExtra;

% - get indices of voltage and current unknowns -
voltageUnknIndices = find(strcmp(ckt.unknUnits, VOLTAGE_UNIT));
currentUnknIndices = find(strcmp(ckt.unknUnits, CURRENT_UNIT));

% - populate tolerance vector locations for circuit unknowns -
ckt.analyses{dcAnIndex}.tol.absTol = [];
ckt.analyses{dcAnIndex}.tol.relTol = [];
ckt.analyses{dcAnIndex}.tol.absTol(voltageUnknIndices,1) = ckt.analyses{dcAnIndex}.tol.vAbsTol;
ckt.analyses{dcAnIndex}.tol.absTol(currentUnknIndices,1) = ckt.analyses{dcAnIndex}.tol.iAbsTol;
ckt.analyses{dcAnIndex}.tol.relTol(voltageUnknIndices,1) = ckt.analyses{dcAnIndex}.tol.vRelTol;
ckt.analyses{dcAnIndex}.tol.relTol(currentUnknIndices,1) = ckt.analyses{dcAnIndex}.tol.iRelTol;

% - populate tolerance vector locations for extra unknowns -
ckt.analyses{dcAnIndex}.tol.absTol(ckt.analyses{dcAnIndex}.extraUnknIndices) = ckt.analyses{dcAnIndex}.tol.extraAbsTol;
ckt.analyses{dcAnIndex}.tol.relTol(ckt.analyses{dcAnIndex}.extraUnknIndices) = ckt.analyses{dcAnIndex}.tol.extraRelTol;
return






% -------------------------------------------------------------------------
% -                                                                       -
% -                          Initial guess vector                         -
% -                                                                       -
% -------------------------------------------------------------------------

function xiguess = initGuess(ckt)
global dcAnIndex
xiguess = [ckt.analyses{dcAnIndex}.iguess.x; ckt.analyses{dcAnIndex}.iguess.extra];
return






% -------------------------------------------------------------------------
% -                                                                       -
% -                             Apply damping                             -
% -                                                                       -
% -------------------------------------------------------------------------

function dx = damp(ckt, x, dx)
global dcAnIndex

% - damp change in extra unknowns -
for i=1:ckt.analyses{dcAnIndex}.extra.numExtra
    unknIndex = ckt.analyses{dcAnIndex}.extraUnknIndices(i);
    damp = ckt.analyses{dcAnIndex}.extra.unkn{i}.damping;
    dxMax = damp*abs(x(unknIndex));
    if abs(dx(unknIndex)) > dxMax
        dx(unknIndex) = sign(dx(unknIndex)) * dxMax;
    end
end

return









% -------------------------------------------------------------------------
% -                                                                       -
% -                             DC iteration                              -
% -                                                                       -
% -------------------------------------------------------------------------


function [ckt, f, dfdx] = f_dfdx(ckt, x)
global dcAnIndex
global MODE_SEN

% - iteration counter -
ckt.analyses{dcAnIndex}.iter = ckt.analyses{dcAnIndex}.iter+1;

% - say hi -
dispID = ['''', ckt.analyses{dcAnIndex}.name, ''''];
disp([dispID, ' iter ', num2str(ckt.analyses{dcAnIndex}.iter)]);

% - number of total, core, and extra unknowns -
numCoreUnkns  = ckt.analyses{dcAnIndex}.numCoreUnkns;
numExtraUnkns = ckt.analyses{dcAnIndex}.extra.numExtra;
numTotalUnkns = numCoreUnkns + numExtraUnkns;
extraUnknIndices = ckt.analyses{dcAnIndex}.extraUnknIndices;

% - extra unknowns were updated by a nonlinear solver - update circuit parameters -
for e=1:numExtraUnkns
    switch ckt.analyses{dcAnIndex}.extra.unkn{e}.type
        case 'circuit parameter'
            parmValue = x(extraUnknIndices(e));
            parmName = ckt.analyses{dcAnIndex}.extra.unkn{e}.name;
            devIndices = ckt.analyses{dcAnIndex}.extra.unkn{e}.deviceIndices;
            multipliers = ckt.analyses{dcAnIndex}.extra.unkn{e}.multipliers;
            ckt = setDevParms(ckt, devIndices, parmName, parmValue*multipliers);
    end
    disp([dispID, ' extra unknown : ',ckt.analyses{dcAnIndex}.extra.unkn{e}.name,' : ' num2str(x(extraUnknIndices(e)))]);
end

if ckt.analyses{dcAnIndex}.grad.calcGradStatus == 2
    % - sensitivity computation is ahead - include gradient variables to parameter list -
    parms           = [ckt.analyses{dcAnIndex}.extra.unkn, ckt.analyses{dcAnIndex}.grad.var];
    numGradVars     = ckt.analyses{dcAnIndex}.grad.numGradVar;   
    numParms        = numExtraUnkns + numGradVars;
    gradParmIndices = numExtraUnkns+1:numParms;
else
    parms           = ckt.analyses{dcAnIndex}.extra.unkn;
    numParms        = numExtraUnkns;
end

% - get data from devices -
info = [];
info.time = 0;
% info.mode = MODE_DC;
info.mode = MODE_SEN;
info.parms = parms;
[ckt, data] = loadCircuit(ckt, x, info);

% - extra function and its sensitivities -
[fextra, dfextra_dxcore, dfextra_dparms, ckt.analyses{dcAnIndex}.data.measures] = ...
    evaluateDEC_DC(ckt, ckt.analyses{dcAnIndex}.extra.eqn, parms, x(1:numCoreUnkns), dcAnIndex, dispID);

f = [data.i; fextra];

% - compute Jacobian -
dfdx = sparse(numTotalUnkns, numTotalUnkns);

% - core block -
dfdx(1:numCoreUnkns, 1:numCoreUnkns) = data.G;

% - extra columns -
dfdx(1:numCoreUnkns, extraUnknIndices) = data.didpar(:,1:numExtraUnkns); 

% - extra rows -
dfdx(extraUnknIndices, 1:numCoreUnkns) = dfextra_dxcore; 

% - extra corner -
dfdx(extraUnknIndices, extraUnknIndices) = dfextra_dparms(:, 1:numExtraUnkns); 

% f = data.i;
% dfdx = data.G;


% -------------------------------------------------------------------------
% -                                                                       -
% -                       DC solution sensitivity                         -
% -                                                                       -
% -------------------------------------------------------------------------

if ckt.analyses{dcAnIndex}.grad.calcGradStatus == 2

    % - say hi -
    disp(['''', ckt.analyses{dcAnIndex}.name, ''' sensitivity run'])    

    % - derivative of all DC equations w.r.t. all gradient variables -
    df_dgammaP = [data.didpar(:, gradParmIndices); dfextra_dparms(:, gradParmIndices)];

    % - solve for the sensitivity w.r.t. all (rhs has multiple columns) gammaP -
    grad = -dfdx\df_dgammaP;

    % - save sensitivities of DC solution -
    ckt.analyses{dcAnIndex}.grad.dx_dgammaP      = grad(1:numCoreUnkns,   :);
    for par=1:numGradVars
        ckt.analyses{dcAnIndex}.grad.var{par}.dx_dgammaP = ...
            ckt.analyses{dcAnIndex}.grad.dx_dgammaP(:, par);
    end

    % - save gradient of extra unknowns -
    disp(['''', ckt.analyses{dcAnIndex}.name, ''' sensitivity done'])
    ckt.analyses{dcAnIndex}.grad.dxextra_dgammaP = grad(extraUnknIndices, :);
end

return

