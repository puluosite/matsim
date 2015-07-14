% 09/13/09
% Simple Test Circuit
%
% Author:
%   Fang Gong
%

clear all
close all

% --- load circuit ---
ckt = diode_rlc();

% --- simulation parameters ---
method     = 'bdf2';
%T          = 1.0e-14;     % initial guess for oscillation period
%nsteps     = 100;         % timesteps per period  
%nT         = 5;           % for how many periods to run transient
%fixPhaseOf = 'v(in)';  % solution phase is fixed by forcing ths unknown be some value at t=0  % change by Fang
%method     = 'bdf2';
%reltol     = 1e-3;
%tolerances = {'vAbsTol', 1e-6, 'vRelTol', reltol, 'iAbsTol', 1e-12, 'iRelTol', reltol};

% --- analysis flow ---
doTran        = 1;
doShooting    = 0;
doShootingPPV = 0;

% --- transient ---
if(doTran)
    x0guess = zeros(ckt.numUnkns, 1);
   % x0guess(getUnknIndex(ckt, fixPhaseOf)) = 3.0;
    tranName = 'theTran';
    ckt = addAnalysis(ckt, 'tran', tranName, {'nsteps', 20/0.01, 'tstop', 2e10, 'setic', x0guess, 'method', method});
    ckt = runAnalysis(ckt, tranName);
    anTran = ckt.analyses{getAnalysisIndex(ckt, tranName)}            
    % plot transient waveform
    figure
    plot(anTran.data.time, anTran.data.x, '-x')
    title('Transient')
    xlabel('Time [ns]')
    ylabel('Circuit Unknowns [V or A]')
    % save circuit state at the end of transient
    legend(ckt.unknNames, 'Interpreter', 'none')
    tran_xEnd = anTran.data.x(:,length(anTran.data.time));
    save('tran_xEnd', 'tran_xEnd');
else
    % load the circuit state (from previously ran transient) 
    load('tran_xEnd', 'tran_xEnd');
end
        
% % --- shooting (PSS) ---
if(doShooting)
    x0guess = tran_xEnd;
    fix = {fixPhaseOf, tran_xEnd(getUnknIndex(ckt, fixPhaseOf))};
    method='shooting'
    pssType = 'pss';
    pssName = 'PSS (conventional)';
    ckt = addAnalysis(ckt, pssType, pssName, [{'T', T, 'nsteps', nsteps, 'setiguess', x0guess, 'method', method, 'fix', fix}]);
    figure
    ckt = runAnalysis(ckt, pssName);
    anPSSshooting = ckt.analyses{getAnalysisIndex(ckt, pssName)}
    % plot PSS waveform
    figure
    h = plot(anPSSshooting.data.time/1e-9, anPSSshooting.data.x(:,:), '-x');
    title(pssName)
    xlabel('Time [ns]')
    ylabel('Circuit Unknowns')
    legend(h, ckt.unknNames, 'Interpreter', 'none')
    a = axis;
    axis([0 anPSSshooting.data.time(nsteps+1)/1e-9 a(3) a(4)]);
    save('circuit_data', 'ckt');
else
     pssName = 'PSS (conventional)';
     load('circuit_data', 'ckt');
end
%     
% % --- shooting ppv ---
% if(doShootingPPV)
%     anPPVname = ['PPV from ', pssName];
%     ckt = addAnalysis(ckt, 'ppv', anPPVname, {'pss', pssName, 'MoMaMe', 0});
%     ckt = runAnalysis(ckt, anPPVname);
%     anPPVshooting = ckt.analyses{getAnalysisIndex(ckt, anPPVname)}
%     anPPVshooting.data
%     disp('Eigenvalues of the monodromy matrix of adjoint system:')
%     disp(eig(anPPVshooting.data.Omega))
%     disp(['The oscillatory eigenvalue is ', num2str(anPPVshooting.data.lambda1)])
%     % plot PPV waveforms
%     figure
%     h = plot(anPPVshooting.data.time/1e-9, anPPVshooting.data.ppv, '-s');
%     legend(h, ckt.eqnNames, 'Interpreter', 'none');
%     xlabel('Time [ns]')
%     ylabel('Circuit PPVs')
%     title(anPPVname);
%     a = axis;
%     axis([0 anPPVshooting.data.time(nsteps+1)/1e-9 a(3) a(4)]);
% end
