function tracked_stats = track_stats(days, regs, brain_area, matched_cell, model_no)

num_matched_days = size(matched_cell,1);

% Format: [Day, Cell#, ActiveFrac, R2]
tracked_stats = zeros(num_matched_days, 4);

for k = 1:num_matched_days
    d = matched_cell(k,1);
    cell_idx = matched_cell(k,2);

    reg = regs{days==d};
    AF = ctxstr.analysis.regress.get_active_frac(reg, brain_area, cell_idx);
    R2 = ctxstr.analysis.regress.get_R2(reg, brain_area, cell_idx, model_no);

    tracked_stats(k,:) = [d, cell_idx, AF, R2];
end