function [ckt, modelIndex] = addModel(ckt, modelParms)
% - check if the model is already in the circuit -
modelIndex = 0;
for i=1:ckt.numModels
    if isequal(ckt.models{i}.parms, modelParms)
        % - do not add - the model is already in the ciruit -
        modelIndex = i;
        return
    end
end

% - extract model parameters -
model.model = modelParms{1};
model.parms = modelParms;
switch model.model
    case 'mosRabaey'
        % - default values -
        model.kf = 1e-24;
        for i=1:length(modelParms)/2
            parmName = modelParms{2*i};
            parmValue = modelParms{2*i+1};
            switch parmName
                case 'type'
                    model.type   = parmValue;
                case 'vt0'
                    model.vt0    = parmValue;
                case 'gamma'
                    model.gamma  = parmValue;
                case 'beta'
                    model.beta   = parmValue;
                case 'lambda'
                    model.lambda = parmValue;
                case 'ld'
                    model.ld     = parmValue;
                case 'wd'
                    model.wd     = parmValue;
                case 'tox'
                    model.tox    = parmValue;
                case 'cov'
                    model.cov    = parmValue;
                case 'cj'
                    model.cj     = parmValue;
                case 'mj'
                    model.mj     = parmValue;
                case 'pb'
                    model.pb     = parmValue;
                case 'cjsw'
                    model.cjsw   = parmValue;
                case 'mjsw'
                    model.mjsw   = parmValue;
                case 'pbsw'
                    model.pbsw   = parmValue;
                case 'af'
                    model.af     = parmValue;
                case 'kf'
                    model.kf     = parmValue;
                otherwise
                    error(['Unknown parameter ''',parmName,''' of model ''',model.model,'''']);
            end
        end
    % - add Diode by Fang - 
    case 'diode'
        for i=1:length(modelParms)/2
            parmName = modelParms{2*i};
            parmValue = modelParms{2*i+1};
            switch parmName
                case 'Is'
                    model.Is = parmValue;
                case 'n'
                    model.n = parmValue;
                case 'vt'
                    model.vt = parmValue;
                case 'cjo'
                    model.cjo = parmValue;
                otherwise
                    error(['Unknown parameter ''',parmName,''' of model ''',model.model,'''']);
            end
        end
        
    % -END -
    otherwise
        error(['Unknown model ''',model.model,'''']);
end
% - add the model to the circuit -
ckt.numModels = ckt.numModels+1;
ckt.models{ckt.numModels} = model;
modelIndex = ckt.numModels;
return
