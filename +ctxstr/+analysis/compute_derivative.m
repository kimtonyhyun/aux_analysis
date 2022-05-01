function yp = compute_derivative(t, y)
% Assumes that t is evenly spaced. The derivative yp is computed for each
% element of t.

dt = t(2) - t(1);

% Note: An extrapolating method, like Akima, must be used.
y2 = interp1(t, y, t+dt/2, 'makima');
y1 = interp1(t, y, t-dt/2, 'makima');
yp = (y2-y1)/dt;