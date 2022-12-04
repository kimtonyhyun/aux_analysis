function [md, ds_list, match_list] = generate_md(ds_cell, match_cell, session_names, sessions_to_keep)

num_sessions = length(sessions_to_keep);

ds_list = cell(num_sessions, 3);
for k = 1:num_sessions
    session_id = sessions_to_keep(k);
    ds_list{k,1} = session_id;
    ds_list{k,2} = ds_cell{session_id};
    ds_list{k,3} = sprintf('%s (Day %d)', session_names{session_id}, session_id);
end

% TODO: Allow for other matching paradigms, e.g. "full" matching
match_list = cell(num_sessions-1, 4);
for k = 1:num_sessions-1
    sess1_id = sessions_to_keep(k);
    sess2_id = sessions_to_keep(k+1);
    match_list{k,1} = sess1_id;
    match_list{k,2} = sess2_id;
    match_list{k,3} = match_cell{sess1_id, sess2_id};
    match_list{k,4} = match_cell{sess2_id, sess1_id};
end

md = MultiDay(ds_list, match_list);