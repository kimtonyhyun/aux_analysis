clear all;

ds = DaySummary([], '1P/ext1/ls');
ds2 = DaySummary([], '2P/ext1/ls');

%%

corrlist_1p2p = compute_corrlist(ds, ds2);
corrlist_1p = compute_corrlist(ds);
corrlist_2p = compute_corrlist(ds2);

%%

browse_corrlist(corrlist_1p2p, ds, ds2, 'names', {'1P', '2P'}, 'zsc');

%%

browse_corrlist(corrlist_1p, ds, ds, 'names', '1P');

%%

browse_corrlist(corrlist_2p, ds2, ds2, 'names', '2P');

%%

