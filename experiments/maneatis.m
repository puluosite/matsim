% 06/15/08
% Copyright (c) 2006-2008 Oregon State University. All rights reserved.
%
% Permission is hereby granted, without written agreement and without license
% or royalty fees, to use, copy, modify, and distribute this software and its
% documentation for any purpose, provided that the above copyright notice and
% the following two paragraphs appear in all copies of this software.
%
% IN NO EVENT SHALL OREGON STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
% DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
% OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF OREGON
% STATE UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% OREGON STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
% INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN
% "AS IS" BASIS, AND OREGON STATE UNIVERSITY HAS NO OBLIGATION TO PROVIDE
% MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
%
% Author:
%   2006-2008 Igor Vytyaz
%
% Advising professors:
%   Kartikeya Mayaram and Un-Ku Moon


%clear all
%close all

% --- load circuit ---
ckt = ring_4stgdiff_maneatis(3)

% --- simulation parameters ---
T          = 1.0e-14;     % initial guess for oscillation period
nsteps     = 100;         % timesteps per period  
nT         = 5;           % for how many periods to run transient
fixPhaseOf = 'v(op1)';  % solution phase is fixed by forcing ths unknown be some value at t=0  % change by Fang
method     = 'bdf2';
reltol     = 1e-3;
tolerances = {'vAbsTol', 1e-6, 'vRelTol', reltol, 'iAbsTol', 1e-12, 'iRelTol', reltol};

% --- analysis flow ---
doTran        = 1;
doShooting    = 1;
doShootingPPV = 0;

% --- transient ---
if(doTran)
    x0guess = zeros(ckt.numUnkns, 1);
    x0guess(getUnknIndex(ckt, fixPhaseOf)) = 3.0;
    tranName = 'theTran';
    ckt = addAnalysis(ckt, 'tran', tranName, {'nsteps', nT*nsteps, 'tstop', T*nT, 'setic', x0guess, 'method', method});
    ckt = runAnalysis(ckt, tranName);
    anTran = ckt.analyses{getAnalysisIndex(ckt, tranName)};            
    %plot transient waveform
    %figure
    %plot(anTran.data.time/1e-9, anTran.data.x, '-x')
    %title('Transient')
    %xlabel('Time [ns]')
    %ylabel('Circuit Unknowns [V or A]')
    %save circuit state at the end of transient
    %legend(ckt.unknNames, 'Interpreter', 'none')
    tran_xEnd = anTran.data.x(:,length(anTran.data.time));
    save('tran_xEnd', 'tran_xEnd');
else
    %load the circuit state (from previously ran transient) 
    load('tran_xEnd', 'tran_xEnd');
end
        
% --- shooting (PSS) ---
if(doShooting)
    x0guess = tran_xEnd;
    fix = {fixPhaseOf, tran_xEnd(getUnknIndex(ckt, fixPhaseOf))};
    method='shooting'
    pssType = 'pss';
    pssName = 'PSS (conventional)';
    ckt = addAnalysis(ckt, pssType, pssName, [{'T', T, 'nsteps', nsteps, 'setiguess', x0guess, 'method', method, 'fix', fix}]);
    figure
    ckt = runAnalysis(ckt, pssName);
    anPSSshooting = ckt.analyses{getAnalysisIndex(ckt, pssName)};
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
    
% --- shooting ppv ---
if(doShootingPPV)
    anPPVname = ['PPV from ', pssName];
    ckt = addAnalysis(ckt, 'ppv', anPPVname, {'pss', pssName, 'MoMaMe', 0});
    ckt = runAnalysis(ckt, anPPVname);
    anPPVshooting = ckt.analyses{getAnalysisIndex(ckt, anPPVname)}
    anPPVshooting.data
    disp('Eigenvalues of the monodromy matrix of adjoint system:')
    disp(eig(anPPVshooting.data.Omega))
    disp(['The oscillatory eigenvalue is ', num2str(anPPVshooting.data.lambda1)])
    % plot PPV waveforms
    figure
    h = plot(anPPVshooting.data.time/1e-9, anPPVshooting.data.ppv, '-s');
    legend(h, ckt.eqnNames, 'Interpreter', 'none');
    xlabel('Time [ns]')
    ylabel('Circuit PPVs')
    title(anPPVname);
    a = axis;
    axis([0 anPPVshooting.data.time(nsteps+1)/1e-9 a(3) a(4)]);
end
