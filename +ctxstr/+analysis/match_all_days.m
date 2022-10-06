clear all;

mouse_name = dirname;

% Note: All sessions that are considered a part of the "8-day learning"
% protocol should be listed as a subdirectory, even if the corresponding
% DaySummary is missing for one or both brain areas.
session_dirs = dir(sprintf('%s-*', mouse_name));
session_dirs = session_dirs([session_dirs.isdir]);
num_sessions = length(session_dirs);

session_names = cell(num_sessions,1);
for k = 1:num_sessions
    session_names{k} = session_dirs(k).name;
end

% List of all pairs of sessions for cell matching
pairs = generate_pairs(num_sessions);
num_pairs = size(pairs, 1);

% Preallocate matching results
ctx_matches = cell(num_sessions, num_sessions);
ctx_infos = cell(num_sessions, num_sessions);

str_matches = cell(num_sessions, num_sessions);
str_infos = cell(num_sessions, num_sessions);

idx_ctx = 1;
idx_str = 1;

%% Load all Ctx DaySummary's

ds_ctx = cell(num_sessions,1);
for k = 1:num_sessions
    try
        ds_ctx{k} = DaySummary('', fullfile(session_names{k}, 'ctx/union_15hz/dff'));
    catch
        cprintf('red', 'Warning: Could not load CTX DaySummary from %s!\n', session_names{k});
    end
end

%% Match Ctx sessions

while (idx_ctx <= num_pairs)
    p = pairs(idx_ctx,:);
    ds1 = ds_ctx{p(1)};
    ds2 = ds_ctx{p(2)};
    if isempty(ds1) || isempty(ds2)
        cprintf('red', 'SKIP  %s (Day %d) to %s (Day %d) match due to missing DS\n',...
            session_names{p(1)}, p(1), session_names{p(2)}, p(2));
    else
        cprintf('blue', 'Matching %s (Day %d) to %s (Day %d)...\n',...
            session_names{p(1)}, p(1), session_names{p(2)}, p(2));

        [m_AtoB, m_BtoA, info] = run_alignment(ds_ctx{p(1)}, ds_ctx{p(2)});
        close all;

        ctx_matches{p(1),p(2)} = m_AtoB;
        ctx_matches{p(2),p(1)} = m_BtoA;

        info.filters_2to1 = [];
        info.filters_1to2 = [];
        ctx_infos{p(1), p(2)} = info;
    end
    idx_ctx = idx_ctx + 1;
end
clear ds1 ds2;

%% Load all Str DaySummary's

ds_str = cell(num_sessions,1);
for k = 1:num_sessions
    try
        ds_str{k} = DaySummary('', fullfile(session_names{k}, 'str/union_15hz/dff'));
    catch
        cprintf('red', 'Warning: Could not load STR DaySummary from %s!\n', session_names{k});
    end
end

%% Match Str sessions

while (idx_str <= num_pairs)
    p = pairs(idx_str,:);
    ds1 = ds_str{p(1)};
    ds2 = ds_str{p(2)};
    if isempty(ds1) || isempty(ds2)
        cprintf('red', 'SKIP  %s (Day %d) to %s (Day %d) match due to missing DS\n',...
            session_names{p(1)}, p(1), session_names{p(2)}, p(2));
    else
        cprintf('blue', 'Matching %s (Day %d) to %s (Day %d)...\n',...
            session_names{p(1)}, p(1), session_names{p(2)}, p(2));

        [m_AtoB, m_BtoA, info] = run_alignment(ds1, ds2);
        close all;

        str_matches{p(1),p(2)} = m_AtoB;
        str_matches{p(2),p(1)} = m_BtoA;

        info.filters_2to1 = [];
        info.filters_1to2 = [];
        str_infos{p(1), p(2)} = info;
    end
    idx_str = idx_str + 1;
end
clear ds1 ds2;

%% Save results

save('all_matches.mat', 'mouse_name', 'session_names',...
     'ctx_matches', 'ctx_infos', 'str_matches', 'str_infos', '-v7.3');