function [tup, tdn, Tup, Tdn] = period(t, x, level)

Ncross = 0;
where = sign(x(1)-level);
for i = 2:length(x)
    if sign(x(i)-level) * sign(x(i-1)-level) <= 0
        Ncross = Ncross + 1;
        crossTime(Ncross) = interp1(x(i-1:i),t(i-1:i),level);
        crossDirection(Ncross) = sign(x(i)-x(i-1));
    end
end

upInd = find(crossDirection==+1);
dnInd = find(crossDirection==-1);

Tup = diff(crossTime(upInd));
Tdn = diff(crossTime(dnInd));

tup = crossTime(upInd(1:length(upInd)-1));
tdn = crossTime(dnInd(1:length(dnInd)-1));
