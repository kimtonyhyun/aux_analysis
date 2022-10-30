classdef model
    properties (SetAccess = private)
        regressors
        num_regressors
    end
    methods
        function obj = model(regressors)
            if ~iscell(regressors)
                % Allows avoiding cell curly braces for single regressor
                % models, e.g. m = model(velocity_regressor);
                obj.regressors = {regressors};
                obj.num_regressors = 1;
            else
                obj.regressors = regressors;
                obj.num_regressors = length(regressors);
            end
        end
        
        function model_desc = get_desc(obj)
            model_desc = '';
            for k = 1:obj.num_regressors
                r = obj.regressors{k};
                model_desc = strcat(model_desc, r.name);
                if k ~= obj.num_regressors
                    model_desc = strcat(model_desc, ',');
                end
            end
        end
        
        function [rn, kn] = get_regressor_by_name(obj, name)
            rn = [];
            kn = [];
            for k = 1:obj.num_regressors
                r = obj.regressors{k};
                if strcmp(name, r.name)
                    rn = r;
                    kn = k;
                    break;
                end
            end
        end
    end
end