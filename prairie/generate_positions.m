function XYZ = generate_positions(profile_ap, profile_ml, bounds, step_size)

% ASSUMED ORIENTATION OF THE MOUSE RELATIVE TO THE PRAIRIE:
%   - Mouse head orientation (e.g. AP axis) is in the +x direction
%   - Mouse ML axis is in the +y direction
%   - All data in microns (though displayed in mm)
%
% See "run_generate_positions" for how to invoke this function

% Fit along the AP axis (assumed to be XZ plane)
%------------------------------------------------------------
subplot(2,2,1);
plot(profile_ap(:,1)/1e3, profile_ap(:,3)/1e3, 'o');
hold on;
grid on;
axis equal;
set(gca, 'XDir', 'Reverse');
xlabel('X [mm]');
ylabel('Z [mm]');
title('Profile along AP');

p_ap = polyfit(profile_ap(:,1), profile_ap(:,3), 2);
x = linspace(min(profile_ap(:,1)), max(profile_ap(:,1)), 1e3);
z_ap = polyval(p_ap, x);
plot(x/1e3, z_ap/1e3, 'k--');

% Fit along the ML axis (assumed to be YZ plane)
%------------------------------------------------------------
subplot(2,2,3);
plot(profile_ml(:,2)/1e3, profile_ml(:,3)/1e3, 'rd');
hold on;
grid on;
axis equal;
set(gca, 'XDir', 'Reverse');
xlabel('Y [mm]');
zlabel('Z [mm]');
title('Profile along ML');

p_ml = polyfit(profile_ml(:,2), profile_ml(:,3), 2);
y = linspace(min(profile_ml(:,2)), max(profile_ml(:,2)), 1e3);
z_ml = polyval(p_ml, y);
plot(y/1e3, z_ml/1e3, 'k--');

% Show the measurements in 3D
%------------------------------------------------------------
subplot(2,2,[2 4]);
plot3(profile_ap(:,1)/1e3, profile_ap(:,2)/1e3, profile_ap(:,3)/1e3, 'o'); hold on;
plot3(profile_ml(:,1)/1e3, profile_ml(:,2)/1e3, profile_ml(:,3)/1e3, 'rd');

bounds_closed = [bounds; bounds(1,:)];
plot3(bounds_closed(:,1)/1e3, bounds_closed(:,2)/1e3, bounds_closed(:,3)/1e3, 'k--');

axis equal;
grid on;
xlabel('X [mm]');
ylabel('Y [mm]');
zlabel('Z [mm]');
view([-37.5+90 30]);
set(gca,'XDir','Reverse');
set(gca,'YDir','Reverse');

% Generate XYZ positions. Remarks:
%   - Fast axis is along the AP direction (less Z movement)
%------------------------------------------------------------

hs = step_size/2; % "Half size"
x_limits = [min(bounds(:,1))+hs max(bounds(:,1))-hs];
y_limits = [min(bounds(:,2))+hs max(bounds(:,2))-hs];

xs = x_limits(1):step_size:x_limits(2); xs = xs';
ys = y_limits(1):step_size:y_limits(2); ys = ys';
Nxs = length(xs);
Nys = length(ys);

% Fill in slow axis
XY = [zeros(Nxs*Nys,1) kron(ys,ones(Nxs,1))];

% Fill in fast axis bidirectionally
for i = 1:length(ys)
    XY(Nxs*(i-1)+1:Nxs*i,1) = xs;
    xs = flipud(xs);
end

% Check if XY point is within bound. If so, evaluate Z and transfer it to
% final list of positions
x_ref = mean(profile_ml(:,1));
eval_z = @(x,y) fit_z(x, y, p_ap, p_ml, x_ref);

XYZ = [];
for i = 1:size(XY,1)
    x = XY(i,1);
    y = XY(i,2);
    if inpolygon(x, y, bounds(:,1), bounds(:,2))
        z = eval_z(x,y);
        XYZ = [XYZ; x y z]; %#ok<AGROW>
    end
end

plot3(XYZ(:,1)/1e3, XYZ(:,2)/1e3, XYZ(:,3)/1e3, 'k.-');
plot3(XYZ(1,1)/1e3, XYZ(1,2)/1e3, XYZ(1,3)/1e3, 'ko'); % First tile

end % generate_positions

function z = fit_z(xq, yq, p_ap, p_ml, x0)
    z = polyval(p_ml, yq) + ...
        (polyval(p_ap, xq) - polyval(p_ap, x0));
end % eval_z