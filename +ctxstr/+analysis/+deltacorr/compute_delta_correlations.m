clear all;

day_name_A = 'oh28-0202';
day_name_B = 'oh28-0209';

day_A = load(fullfile(day_name_A, 'corrdata.mat'));
day_B = load(fullfile(day_name_B, 'corrdata.mat'));

%%

ctx_matches = load('ctx_matches.mat');
str_matches = load('str_matches.mat');

ctx_match_AtoB = ctx_matches.m_1to8;
str_match_AtoB = str_matches.m_1to8;

% Indices below refer to cell #'s in the Rec files
ctx_matched_inds = generate_matched_inds(ctx_match_AtoB);
str_matched_inds = generate_matched_inds(str_match_AtoB);

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

ctxstr.vis.show_correlations(D_ctx, D_str, D_ctxstr,...
    sprintf('%s—%s', day_name_B, day_name_A), 'delta');