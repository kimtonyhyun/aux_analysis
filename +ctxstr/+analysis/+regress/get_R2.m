function [R2_val, R2_err] = get_R2(reg, brain_area, cell_idx, model_no)

switch brain_area
    case 'ctx'
        R2_val = reg.ctx_fit.results.R2(cell_idx, model_no);
        R2_err = reg.ctx_fit.results.error(cell_idx, model_no);
    case 'str'
        R2_val = reg.str_fit.results.R2(cell_idx, model_no);
        R2_err = reg.str_fit.results.error(cell_idx, model_no);
end