%init directory

simHome = pwd;
simDirs{1} = 'analyses';
simDirs{2} = 'ckt';
simDirs{3} = 'devices';
simDirs{5} = 'math';
simDirs{6} = 'util';
%simDirs{7} = 'regression';

disp(' ')
disp('simulator directories:')
for i=1:length(simDirs)
    newDir = [simHome,'/',simDirs{i}];
    path(path, newDir);
    disp(newDir);
end
disp(' ')

cd(simHome);
format short e
