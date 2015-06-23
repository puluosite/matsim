function [ckt,result] = nonLinearSolver(ckt, solverType, parms)
switch solverType
    case 'Newton'
        % Newton iteration
        hInitGuess = parms{1};
        hf_dfdx    = parms{2};
        hDamp      = parms{3};
        hCheckConv = parms{4};
        absTol     = parms{5};
        relTol     = parms{6};
        maxIter    = parms{7};
        % - initial guess -
        x = feval(hInitGuess, ckt);
        for i=1:maxIter
%             disp(['iter#', num2str(i)])
            % - calculate function and Jacobian -
            [ckt, f, dfdx] = feval(hf_dfdx, ckt, x);
            % - solve for dx -
            dx = dfdx\-f;
            % dx = gmres(dfdx,-f);
            % - apply damping if needed -
            if isa(hDamp, 'function_handle')
                % - damp/limit dx -
                dx = feval(hDamp, ckt, x, dx);
            end
            % - calculate new x -
            xnew = x + dx;
            % - check convergence -
            [nonConv, result.err.absErr, result.err.relErr] =...
                feval(hCheckConv, x, xnew, dx, absTol, relTol);
            if(nonConv==0)
                % - converged! -
                result.nonConv = nonConv;
                result.soln.x = xnew;
                result.soln.f = f;
                result.soln.dfdx = dfdx;
                result.iter = i;
                return
            else
                % - update solution -
                x = xnew;
            end
        end
        % - did not converge in maxIter -
        result.nonConv = nonConv;
        result.soln.x = xnew;
        result.soln.f = f;
        result.soln.dfdx = dfdx;
        error(['Nonlinear solver ''',solverType,''' did not converge in ', num2str(maxIter),' iterations']);

    otherwise
        error(['Unknown nonlinear solver ''',solverType,'''']);
        return
end

return






% --- debug shooting-DEC Jacobian ---
% 
% x = feval(hInitGuess, ckt);
% 
% [ckt, f1, dfdx1] = feval(hf_dfdx, ckt, x);
% 
% dfdx1 = zeros(size(dfdx1));
% for i = 1:length(x)
%     if i<=ckt.numUnkns
%         switch ckt.unknUnits{i}
%             case 'V'
%                 dx = 1e-3;
%             case 'A'
%                 dx = 1e-9;
%         end
%     else
%         dx = 1e-3*x(i);
%     end
%     x2 = x;
%     x2(i) = x2(i) + dx;
%     [ckt, f2, tmp] = feval(hf_dfdx, ckt, x2);
%     dfdx2(:,i) = (f2 - f1)/dx;
% end

