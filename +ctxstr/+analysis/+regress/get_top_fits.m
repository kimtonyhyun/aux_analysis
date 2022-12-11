function [ctx_top_fits, str_top_fits] = get_top_fits(reg, model_no)

ctx_top_fits = ctxstr.analysis.regress.sort_R2s(reg.ctx_fit.results.R2(:,model_no));
str_top_fits = ctxstr.analysis.regress.sort_R2s(reg.str_fit.results.R2(:,model_no));
