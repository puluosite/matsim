function ckt = runAnalysis(ckt, analysisName);
analysisIndex = 0;
for i=1:ckt.numAnalyses
    if strcmp(ckt.analyses{i}.name, analysisName)
        analysisIndex = i;
        break
    end
end
if(analysisIndex == 0)
    error(['Analysis named ''',analysisName,''' does not exist']);
end
if ~ckt.devStampIndComputed
    ckt = computeDeviceStampIndices(ckt);
    ckt.devStampIndComputed = 1;
end
disp(['''',ckt.analyses{analysisIndex}.name,''' run'])
ckt = feval(ckt.analyses{analysisIndex}.hRun, ckt, analysisIndex);
disp(['''',ckt.analyses{analysisIndex}.name,''' done'])
return
