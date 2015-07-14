% - fully differential ring oscilltor with 4 Maneatis delay cells -

function ckt = ring_4stgdiff_maneatis(Vctrl)

% - initialize circuit -
ckt = initCircuit('ring_4stgdiff_maneatis');

% - models -
nmos = {'mosRabaey', 'type', +1, 'vt0',  0.43, 'gamma',  0.4, 'beta', 117.7e-6,  'lambda',  0.06, 'ld', 0.005, 'wd', 0.015, 'tox', 5.8e-9, 'cov', 3.11E-10, 'cj', 0.002,   'mj', 0.496, 'pb', 0.917, 'cjsw', 2.75e-10, 'mjsw', 0.443, 'pbsw', 0.917};
pmos = {'mosRabaey', 'type', -1, 'vt0', -0.40, 'gamma', -0.4, 'beta', -30.34e-6, 'lambda', -0.1,  'ld', 0,     'wd', 0.015, 'tox', 5.8e-9, 'cov', 2.68E-10, 'cj', 0.00193, 'mj', 0.48,  'pb', 0.91,  'cjsw', 2.23e-10, 'mjsw', 0.32,  'pbsw', 0.91 };

% - parameters -
Wx   = 10e-6;
Wpx  = 3*Wx;
Wnx  = Wx;
Wp1  = 1*Wpx;
Wp2  = 2*Wpx;
Wp4  = 4*Wpx;
Wp8  = 8*Wpx;
Wn1  = 1*Wnx;
Wn2  = 2*Wnx;
Wn4  = 4*Wnx;

Wtail = Wn4;
Wpair = Wn2;
Wload = Wp1;

L   = 0.24e-6;
Cl  = 100e-15;

vc = 'vc';
bn = 'bn';
dd = 'dd';
ss = 'ss';

Vdd = 1.8;
ckt = addDevice(ckt, 'Vdd', {dd,'0'}, {'vol', Vdd});
ckt = addDevice(ckt, 'Vss', {ss,'0'}, {'vol', 0.0});
ckt = addDevice(ckt,  'Vc', {dd,vc}, {'vol', Vdd-Vctrl});

commonCellData = {nmos, pmos, Wtail, Wpair, Wload, L, Cl};

ckt = addManeatisCell(ckt, '1', commonCellData, 'op4', 'on4', 'op1', 'on1', vc, bn, dd, ss);
ckt = addManeatisCell(ckt, '2', commonCellData, 'on1', 'op1', 'op2', 'on2', vc, bn, dd, ss);
ckt = addManeatisCell(ckt, '3', commonCellData, 'on2', 'op2', 'op3', 'on3', vc, bn, dd, ss);
ckt = addManeatisCell(ckt, '4', commonCellData, 'on3', 'op3', 'op4', 'on4', vc, bn, dd, ss);

% Active Biasing
ckt = addDevice(ckt, 'Mn10_b',       {     bn,     'nb4_b',         ss,  ss}, {'model', nmos, 'W', Wn1,   'L', L});
ckt = addDevice(ckt, 'Mn11_b',       {'nb4_b',     'nb4_b',         ss,  ss}, {'model', nmos, 'W', Wn1,   'L', L});
ckt = addDevice(ckt, 'Mn13_b',       {'nb1_b',          bn,         ss,  ss}, {'model', nmos, 'W', Wn1,   'L', L});
ckt = addDevice(ckt, 'Mn14_b',       {'nb2_b',          dd,    'nb1_b',  ss}, {'model', nmos, 'W', Wn1,   'L', L});
ckt = addDevice(ckt, 'Mtail[bias]',  {'cm[bias]',       bn,         ss,  ss}, {'model', nmos, 'W', Wtail, 'L', L});
ckt = addDevice(ckt, 'Mpair[bias]',  {'o[bias]',        dd, 'cm[bias]',  ss}, {'model', nmos, 'W', Wpair, 'L', L});
ckt = addDevice(ckt, 'MampTop',      {'nb3_b',     'nb2_b',         dd,  dd}, {'model', pmos, 'W', Wp2,   'L', L});
ckt = addDevice(ckt, 'Mp11_b',       {     bn,          vc,    'nb3_b',  dd}, {'model', pmos, 'W', Wp2,   'L', L});
ckt = addDevice(ckt, 'Mamp1',        {'nb4_b',   'o[bias]',    'nb3_b',  dd}, {'model', pmos, 'W', Wp2,   'L', L});
ckt = addDevice(ckt, 'Mp13_b',       {'nb2_b',     'nb2_b',         dd,  dd}, {'model', pmos, 'W', Wp4,   'L', L});
ckt = addDevice(ckt, 'Mload1[bias]', {'o[bias]',        vc,         dd,  dd}, {'model', pmos, 'W', Wload, 'L', L});
ckt = addDevice(ckt, 'Mload2[bias]', {'o[bias]', 'o[bias]',         dd,  dd}, {'model', pmos, 'W', Wload, 'L', L});

return


function ckt = addManeatisCell(ckt, name, commonCellData, ip, in, op, on, vc, bn, dd, ss)
    nmos  = commonCellData{1};
    pmos  = commonCellData{2};
    Wtail = commonCellData{3};
    Wpair = commonCellData{4};
    Wload = commonCellData{5};
    L     = commonCellData{6};
    Cl    = commonCellData{7};
    cm = ['cm[',name,']'];
    ckt = addDevice(ckt,  ['Mtail[',name,']'], {cm, bn, ss, ss}, {'model', nmos, 'W', Wtail, 'L', L});
    ckt = addDevice(ckt, ['Mpair1[',name,']'], {on, ip, cm, ss}, {'model', nmos, 'W', Wpair, 'L', L});
    ckt = addDevice(ckt, ['Mpair2[',name,']'], {op, in, cm, ss}, {'model', nmos, 'W', Wpair, 'L', L});
    ckt = addDevice(ckt, ['Mload1[',name,']'], {on, on, dd, dd}, {'model', pmos, 'W', Wload, 'L', L});
    ckt = addDevice(ckt, ['Mload2[',name,']'], {on, vc, dd, dd}, {'model', pmos, 'W', Wload, 'L', L});
    ckt = addDevice(ckt, ['Mload3[',name,']'], {op, vc, dd, dd}, {'model', pmos, 'W', Wload, 'L', L});
    ckt = addDevice(ckt, ['Mload4[',name,']'], {op, op, dd, dd}, {'model', pmos, 'W', Wload, 'L', L});
    ckt = addDevice(ckt,     ['Cp[',name,']'],          {op,ss}, {'cap', Cl});
    ckt = addDevice(ckt,     ['Cn[',name,']'],          {on,ss}, {'cap', Cl});    
return

