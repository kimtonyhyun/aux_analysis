function active_frac = get_active_frac(reg, brain_area, cell_idx)

switch brain_area
    case 'ctx'
        active_frac = reg.ctx_fit.results.active_fracs(cell_idx);
    case 'str'
        active_frac = reg.str_fit.results.active_fracs(cell_idx);
end