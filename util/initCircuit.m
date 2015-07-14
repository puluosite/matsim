function ckt = initCircuit(name)
global VOLTAGE_UNIT
global CURRENT_UNIT

global MODE_DC
global MODE_TRAN
global MODE_SEN
global MODE_SEN2

VOLTAGE_UNIT = 'V';
CURRENT_UNIT = 'A';

MODE_DC   = 1;
MODE_TRAN = 2;
MODE_SEN  = 3;
MODE_SEN2 = 4;

ckt.name = name;

ckt.gmin        = 1e-9;

ckt.groundNodeIntroduced = 0;
ckt.devStampIndComputed  = 0;

ckt.numDevices  = 0;
ckt.numModels   = 0;
ckt.numNodes    = 0;
ckt.numEqns     = 0;
ckt.numUnkns    = 0;
ckt.numAnalyses = 0;

ckt.nodeKCLeqnIndices = [];
ckt.nodeNames         = [];
ckt.eqnNames          = [];
ckt.unknNames         = [];
ckt.devNames          = [];
ckt.eqnUnits          = [];
ckt.unknUnits         = [];
ckt.analyses          = [];

return
