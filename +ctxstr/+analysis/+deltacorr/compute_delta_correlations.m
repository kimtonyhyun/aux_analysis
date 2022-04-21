clear all;

mdata = load('all_matches.mat');

A_idx = 7;
B_idx = 8;

day_name_A = mdata.session_names{A_idx};
day_name_B = mdata.session_names{B_idx};

day_A = load(fullfile(day_name_A, 'corrdata.mat'));
day_B = load(fullfile(day_name_B, 'corrdata.mat'));

%%

% Indices below refer to cell #'s in the Rec files
ctx_matched_inds = generate_matched_inds(mdata.ctx_matches{A_idx, B_idx});
str_matched_inds = generate_matched_inds(mdata.str_matches{A_idx, B_idx});

% Indices below refer to cell #'s in the correlation matrices
ctx_matched_inds = [day_A.ctx_info.rec2ind(ctx_matched_inds(:,1)) day_B.ctx_info.rec2ind(ctx_matched_inds(:,2))];
str_matched_inds = [day_A.str_info.rec2ind(str_matched_inds(:,1)) day_B.str_info.rec2ind(str_matched_inds(:,2))];

%%

C_ctx_A = day_A.C_ctx(ctx_matched_inds(:,1), ctx_matched_inds(:,1));
C_ctx_B = day_B.C_ctx(ctx_matched_inds(:,2), ctx_matched_inds(:,2));
D_ctx = C_ctx_B - C_ctx_A;

C_str_A = day_A.C_str(str_matched_inds(:,1), str_matched_inds(:,1));
C_str_B = day_B.C_str(str_matched_inds(:,2), str_matched_inds(:,2));
D_str = C_str_B - C_str_A;

C_ctxstr_A = day_A.C_ctxstr(ctx_matched_inds(:,1), str_matched_inds(:,1));
C_ctxstr_B = day_B.C_ctxstr(ctx_matched_inds(:,2), str_matched_inds(:,2));
D_ctxstr = C_ctxstr_B - C_ctxstr_A;

%%

% figure;
% ctxstr.vis.show_correlations(C_ctx_A, C_str_A, C_ctxstr_A, day_name_A);
% 
% figure;
% ctxstr.vis.show_correlations(C_ctx_B, C_str_B, C_ctxstr_B, day_name_B);

ctxstr.vis.show_correlations(D_ctx, D_str, D_ctxstr,...
    sprintf('%s—%s', day_name_B, day_name_A), 'delta');