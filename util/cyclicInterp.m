% --------------------------------------------------------------
% - Returns a point on a periodic waveform at a given time     -
% --------------------------------------------------------------
%  t  : time samples along one period excluding the end point 
%  x  : waveform alond one period excluding the end point     
%  T  : the period                                            
%  ti : time of desired waveform sample                       
%  xi : desired waveform sample                               
% --------------------------------------------------------------

function xi = cyclicInterp(t, x, T, ti)

for v = 1:size(x,1)
    xi(v,1) = interp1([t,T], [x(v,:),x(v,1)], mod(ti,T));
end

return
