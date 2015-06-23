function ckt = analysisTran(ckt, analysisIndex)
global anIndTran

anIndTran = analysisIndex;
ckt = createToleranceVectors(ckt);
% ckt = initialCondition(ckt);

% - function handles and parameters for nonlinear solver -
solverParms = {@initGuess, @f_dfdx, 0, @checkConv,...
    ckt.analyses{anIndTran}.tol.absTol,...
    ckt.analyses{anIndTran}.tol.relTol,...
    ckt.analyses{anIndTran}.maxStepIter};

% - constant timestep -
nsteps = ckt.analyses{anIndTran}.nsteps;
ckt.analyses{anIndTran}.h = ckt.analyses{anIndTran}.tstop/nsteps;
ckt.analyses{anIndTran}.data.time = ckt.analyses{anIndTran}.h*(0:nsteps);

% - allocate memory for matrices and vectors -
numTranUnkns = length(ckt.analyses{anIndTran}.data.time)*ckt.numUnkns;
ckt.analyses{anIndTran}.data.G      = sparse(numTranUnkns, numTranUnkns);
ckt.analyses{anIndTran}.data.C      = sparse(numTranUnkns, numTranUnkns);
ckt.analyses{anIndTran}.soln.dfdx   = sparse(numTranUnkns, numTranUnkns);
ckt.analyses{anIndTran}.data.i      = zeros(numTranUnkns, 1);
ckt.analyses{anIndTran}.data.q      = zeros(numTranUnkns, 1);
ckt.analyses{anIndTran}.data.f      = zeros(numTranUnkns, 1);
ckt.analyses{anIndTran}.data.x_flat = zeros(numTranUnkns, 1);

% - create Omega matrix -
ckt = createOmega(ckt, ckt.analyses{anIndTran}.diffFormula);

% - how often to display for transient progress  -
N = 5;
fraction = (1:N)/N;
fc = 1;

% - loop through time -
for t = 1:nsteps+1
    ckt.analyses{anIndTran}.t = t;
    tptIndices = (t-1)*ckt.numUnkns+1:(t)*ckt.numUnkns;
    % - dislay transient progress -
    if t-1 >= fraction(fc)*nsteps
        disp(['''',ckt.analyses{anIndTran}.name,''' ',num2str(100*fraction(fc)),'%']);
        fc = fc + 1;
    end
    if t == 1
        % - solution at t=0 is initial condition -
        ckt.analyses{anIndTran}.data.x_flat(tptIndices) = ckt.analyses{anIndTran}.ic.x;
        [ckt, ckt.analyses{anIndTran}.soln.f(tptIndices), ...
            ckt.analyses{anIndTran}.soln.dfdx(tptIndices, tptIndices)] = ...
            feval(@f_dfdx, ckt, ckt.analyses{anIndTran}.data.x_flat(tptIndices));
        continue
    end
        
    % - call nonlinear solver -
    [ckt,result] = nonLinearSolver(ckt, 'Newton', solverParms);
    
    % - check if solver did the job -
    if result.nonConv == 0
        % - do it only if sensitivity if needed by shooting -
        % - calculate function and Jacobian at solution point -
        [ckt, result.soln.f, result.soln.dfdx] = feval(@f_dfdx, ckt, result.soln.x);
        ckt.analyses{anIndTran}.data.x_flat(tptIndices)          = result.soln.x;
        ckt.analyses{anIndTran}.soln.f(tptIndices)               = result.soln.f;
        ckt.analyses{anIndTran}.soln.dfdx(tptIndices,tptIndices) = result.soln.dfdx;
    else
        error(['Analysis ''',ckt.analyses{anIndTran}.name,''' did not converge (time=',num2str(ckt.analyses{anIndTran}.data.time(t)),')']);
    end
end
% - save solution in matrix form -
ckt.analyses{anIndTran}.data.x = zeros(ckt.numUnkns, nsteps+1);
for t=1:nsteps+1
    tptIndices = (t-1)*ckt.numUnkns+1:t*ckt.numUnkns;
    ckt.analyses{anIndTran}.data.x(:, t) = ckt.analyses{anIndTran}.data.x_flat(tptIndices);
end    
return








% -------------------------------------------------------------------------
% -                                                                       -
% -      Absolute and relative tolerance vectors for analysis unknowns    -
% -                                                                       -
% -------------------------------------------------------------------------

function ckt = createToleranceVectors(ckt)
global anIndTran
global VOLTAGE_UNIT
global CURRENT_UNIT
ckt.analyses{anIndTran}.tol.absTol = zeros(ckt.numUnkns, 1);
ckt.analyses{anIndTran}.tol.relTol = zeros(ckt.numUnkns, 1);
voltageUnknIndices = find(strcmp(ckt.unknUnits, VOLTAGE_UNIT));
currentUnknIndices = find(strcmp(ckt.unknUnits, CURRENT_UNIT));
ckt.analyses{anIndTran}.tol.absTol(voltageUnknIndices) = ckt.analyses{anIndTran}.tol.vAbsTol;
ckt.analyses{anIndTran}.tol.absTol(currentUnknIndices) = ckt.analyses{anIndTran}.tol.iAbsTol;
ckt.analyses{anIndTran}.tol.relTol(voltageUnknIndices) = ckt.analyses{anIndTran}.tol.vRelTol;
ckt.analyses{anIndTran}.tol.relTol(currentUnknIndices) = ckt.analyses{anIndTran}.tol.iRelTol;
return













% -------------------------------------------------------------------------
% -                                                                       -
% -                         Create Omega matrix                           -
% -                                                                       -
% -------------------------------------------------------------------------

function [ckt] = createOmega(ckt, diffFormula)
global anIndTran

% - [0    ] = Omega*[x]
%   [dx/dt]      
%
% - Omega = [0       ]
%           [wx      ] - 'be'
%           [wxx     ] - 'bdf2'
%           [ xxx    ] - 'bdf2'
%           [  xxx   ]     .
%           [   ...  ]     .
%           [    xxx ]     .
%           [     xxx]     .

% - number of rows and columns -
N = ckt.analyses{anIndTran}.nsteps+1;
% - coeficiens of backward differentiation formulae -
[alphaBE, betaBE] = bdf('be');
[alphaXX, betaXX] = bdf(diffFormula);
orderBE = length(alphaBE)-1;
orderXX = length(alphaXX)-1;
h = ckt.analyses{anIndTran}.h;
% z = zeros(1, orderXX-orderBE);
% - coefficients of backward Euler and user-provided method -
coeffsBE = -alphaBE/h/betaBE;
coeffsXX = -alphaXX/h/betaXX;
% - bdf coefficients -
coeffs      = [kron(ones(N,1), coeffsXX)];
coeffs(1,1) = 0;
coeffs(1,2) = coeffsBE(2);
coeffs(2,1) = coeffsBE(1);
% - bdf coefficients used at every timestep for every circuit unknown -
Coeffs   = kron(coeffs, ones(ckt.numUnkns,1));
% - Omega diagonals -
diags = -[0:orderXX]*ckt.numUnkns;
% - populate corresponding Omega diagonals by bdf coefficients -
ckt.analyses{anIndTran}.data.Omega = spdiags(Coeffs, diags, N*ckt.numUnkns, N*ckt.numUnkns);
% - bdf coefficient of current x fused at every timestep -
ckt.analyses{anIndTran}.data.coeff0 = coeffs(:,1);
% - order of bdf formulae used at every timestep -
ckt.analyses{anIndTran}.data.order = [0; orderBE; kron(ones(N-2,1), orderXX)];
return









% -------------------------------------------------------------------------
% -                                                                       -
% -            Initial guess for solution at the next timepoint           -
% -                                                                       -
% -------------------------------------------------------------------------

function xinit = initGuess(ckt)
global anIndTran
t = ckt.analyses{anIndTran}.t-1;
tptIndices = (t-1)*ckt.numUnkns+1:(t)*ckt.numUnkns;
xinit = ckt.analyses{anIndTran}.data.x_flat(tptIndices);
return









% -------------------------------------------------------------------------
% -                                                                       -
% -                 Transient iteration for a timepoint                   -
% -                                                                       -
% -------------------------------------------------------------------------

function [ckt, f, dfdx] = f_dfdx(ckt, x)
global anIndTran
global MODE_TRAN

% - evaluate devices in 'tran' mode -
t = ckt.analyses{anIndTran}.t;
info.mode = MODE_TRAN;
info.time = ckt.analyses{anIndTran}.data.time(t);
[ckt, data] = loadCircuit(ckt, x, info);

% - save data from devices -
tptIndices = (t-1)*ckt.numUnkns+1:t*ckt.numUnkns;
ckt.analyses{anIndTran}.data.G(tptIndices, tptIndices) = data.G;
ckt.analyses{anIndTran}.data.C(tptIndices, tptIndices) = data.C;
ckt.analyses{anIndTran}.data.i(tptIndices)             = data.i;
ckt.analyses{anIndTran}.data.q(tptIndices)             = data.q;

% - at initial timepoint no need to compute f and df/dx -
if t==1
    f = data.i;
    dfdx = data.G;
    return
end

% - differetiation in time -
bdfLength  = ckt.analyses{anIndTran}.data.order(t) + 1;
bdfIndices = (t-bdfLength)*ckt.numUnkns+1:t*ckt.numUnkns;
dqdt   = ckt.analyses{anIndTran}.data.Omega(tptIndices, bdfIndices) * ckt.analyses{anIndTran}.data.q(bdfIndices);
dqdtdv = ckt.analyses{anIndTran}.data.coeff0(t) * data.C;

% - function and Jacobian -
f    = data.i + dqdt;
dfdx = data.G + dqdtdv;

return
