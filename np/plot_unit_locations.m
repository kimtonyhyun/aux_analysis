function plot_unit_locations(spike_data, marker, color)

locs = spike_data.unit_locations;
num_units = spike_data.num_units;

plot(locs(:,1), locs(:,2), marker, 'Color', color);

for k = 1:num_units
    si_unit_id = spike_data.orig_unit_ids(k);
    loc = locs(k,:);
    text(loc(1), loc(2), num2str(si_unit_id), 'Color', color);
end

set(gca, 'TickLength', [0 0]);
grid on;
xlabel('x (um)');
ylabel('y (um)');