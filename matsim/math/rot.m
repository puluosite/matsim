function ind = rot(ind, shift, N) 
ind = mod(ind+shift*length(ind)-1,N)+1;
return
