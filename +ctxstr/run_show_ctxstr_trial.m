clear all;

dataset_name = dirname;

path_to_ctx = 'ctx/union_15hz/cascade';
path_to_str = 'str/union_15hz/cascade';

ctx = load(get_most_recent_file(path_to_ctx, 'rec_*.mat'), 'traces'); ctx.traces = ctx.traces'; % [Cells x Time]
str = load(get_most_recent_file(path_to_str, 'rec_*.mat'), 'traces'); str.traces = str.traces';

tdt = load_tdt(path_to_str);

session = load('ctxstr.mat');
ctx.t = mean(reshape(session.ctx.frame_times, [2 16000]), 1); % Assume ctx data temporally binned by factor 2
ctx.fps = 15;

str.t = mean(reshape(session.str.frame_times, [3 16000]), 1); % Assume str data temporally binned by factor 3
str.fps = 15;

% Note that 'trials' includes all behavioral trials in the Saleae record,
% even those that are not captured by imaging. The subset of trials with
% imaging are in 'session.info.imaged_trials'
trials = ctxstr.load_trials;

%%

ctxstr.show_ctxstr_trials(91:100, session, trials, ctx, str, tdt);