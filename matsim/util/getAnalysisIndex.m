function analysisIndex = getAnalysisIndex(ckt, analysisName)
% - loop through analyses -
for i=1:ckt.numAnalyses
    if strcmp(ckt.analyses{i}.name, analysisName)
        analysisIndex = i;
        return
    end
end
% - no analysis with requested name -
analysisIndex = 0;
return
