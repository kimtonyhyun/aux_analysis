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

num_trials_per_page = 8;
num_imaged_trials = length(session.info.imaged_trials);

trial_chunks = make_frame_chunks(num_imaged_trials, num_trials_per_page);
num_pages = size(trial_chunks, 1);

for k = 1:num_pages
    trials_to_show = session.info.imaged_trials(trial_chunks(k,1):trial_chunks(k,2));
    ctxstr.show_ctxstr_trials(trials_to_show, session, trials, ctx, str, tdt);
    fprintf('Page %d/%d: Showing Trials %d to %d...\n', k, num_pages,...
        trials_to_show(1), trials_to_show(end));
    pause;
end