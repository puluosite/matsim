% Simple ckt with RLC and Diode

function ckt = diode_rlc()

% - initialize circuit
ckt = initCircuit('diode_rlc');  % \util\initCircuit.m

% - models -
diode = {'diode','Is', 1e-16, 'n', 1, 'vt', 2.57e-2,'cjo',2e-12};

ckt = addDevice(ckt, 'Vin', {'in','0'}, {'vol', 0, 'freq', 100, 'phase', 0, 'amplitude', 10});  

% add diode
ckt = addDevice(ckt, 'D1', {'in','a'}, {'model', diode}); 
%ckt = addDevice(ckt, 'R3', {'in','a'}, {'res', 5});
ckt = addDevice(ckt,  'C1', {'in','a'}, { 'cap', 1e-6});
ckt = addDevice(ckt,  'R1', {'a','b'}, {'res', 5});
ckt = addDevice(ckt,  'C2', {'b','0'}, { 'cap', 1e-3});
ckt = addDevice(ckt,  'L1', {'b','c'}, {'ind', 0.1});
ckt = addDevice(ckt,  'C3', {'c','0'}, { 'cap', 1e-3});
ckt = addDevice(ckt,  'R2', {'c','0'}, {'res', 1000});

% ckt = addDevice(ckt, 'Vin', {'1','0'}, {'vol', 0, 'freq', 50, 'phase', 0, 'amplitude', 10}); 
% ckt = addDevice(ckt,  'C1', {'1','2'}, { 'cap', 1e-3});
% ckt = addDevice(ckt,  'L1', {'2','0'}, {'ind', 0.1});
% ckt = addDevice(ckt,  'R1', {'2','0'}, {'res', 5});

return


