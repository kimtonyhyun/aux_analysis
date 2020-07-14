clear all; close all;

% Load traces

ctx_data = load(get_most_recent_file('ctx/union/ls', 'rec_*'));
str_data = load(get_most_recent_file('str/union/ls', 'rec_*'));

ctx_traces = ctx_data.traces; % [Frames x num_cells]
str_traces = str_data.traces;

num_ctx_cells = size(ctx_traces, 2);
num_str_cells = size(str_traces, 2);

%% Resample

% Recall:
% - Ctx recording begins before Str
% - Ctx recording ends before Str
%
% Idea:
% Resample the cortical trace at the timepoints of the striatum trace.
%

meta = load('ctxstr.mat'); % Metadata

% Get the last striatum frame index before the cortex recording ends
last_str_idx = find(meta.str.frame_times < meta.ctx.frame_times(end), 1, 'last');

t = meta.str.frame_times(1:last_str_idx); % Common time
str_tr_matched = str_traces(1:last_str_idx, :);
ctx_tr_matched = interp1(meta.ctx.frame_times, ctx_traces, t, 'linear');

%% Save resampled data to Rec file

str_data.info.type = 'resampled';
str_rec = save_rec(str_data.info, str_data.filters, str_tr_matched);

ctx_data.info.type = 'resample';
ctx_rec = save_rec(ctx_data.info, ctx_data.filters, ctx_tr_matched);
