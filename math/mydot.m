function Xdot = mydot(X, w)

N = size(X,1);
omega = w*[1:(N-1)/2]';
Xdot = zeros(size(X));
% Xdot(1,:) = 0;
Xdot(3:2:N,:) = +omega.*X(2:2:N,:);
Xdot(2:2:N,:) = -omega.*X(3:2:N,:);

return
