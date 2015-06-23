function ckt = deleteAnalysis(ckt, analysisIndex)
ckt.analyses(analysisIndex) = [];
ckt.numAnalyses = ckt.numAnalyses - 1;
return
