function printDCsoln(ckt, anName)

anIndex = getAnalysisIndex(ckt, anName);
if ~strcmp(ckt.analyses{anIndex}.type, 'dc')
    error(['''',anName,''' is bnot a DC analysis.'])
end
str = sprintf(['DC solution for ''',anName,''' analysis:\n']);
for i=1:ckt.numUnkns
    str = [str, sprintf('%8s = % .6e\n', ckt.unknNames{i}, ckt.analyses{anIndex}.soln.x(i))];
end
disp(str)
    
