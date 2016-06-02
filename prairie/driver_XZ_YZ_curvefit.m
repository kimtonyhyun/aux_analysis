clear all; close all;
addpath('../_prairie');

% STEP 1: Fitting of curve in the XZ plane
%------------------------------------------------------------

% Format: Row is XYZ position (Prairie coordinates) when in focus
data_xz = [1301.54 -1500.00 -965.75;
           1100.50 -1500.00 -1056.08;
           902.57  -1500.00 -1139.03;
           698.74 -1499.32 -1238.75;
           499.88 -1498.39 -1369.65;
           301.79 -1498.39 -1522.15;
           100.90 -1498.39 -1748.75;
           1500.24 -1498.39 -878.60;
           1700.82 -1498.39 -794.73;
           1907.74 -1498.39 -707.92;
           2100.56 -1498.39 -656.53;
          ];
 
subplot(211);
plot(data_xz(:,1),data_xz(:,3),'o');
hold on;
axis equal;
xlabel('X_p [um]');
ylabel('Z_p [um]');
grid on;
set(gca,'XDir','Reverse');

p_xz = polyfit(data_xz(:,1),data_xz(:,3),2);
xpcont = linspace(min(data_xz(:,1)),max(data_xz(:,1)),1e3);
zpcont = polyval(p_xz,xpcont);
plot(xpcont,zpcont,'r','linewidth',2);

legend('Measured',...
       sprintf('Quadratic fit (R=%.1f mm)',abs(1/(2*p_xz(1))/1e3)),...
       'Location','SouthWest');
% return;

% STEP 2: Fitting of curve in the YZ plane
%------------------------------------------------------------

% Format: Row is XYZ position (Prairie coordinates) when in focus
data_yz = [1501.95 -1498.39 -879.13;
           1501.95 -1709.03 -837.53;
           1501.95 -1903.24 -818.53;
           1501.95 -2102.89 -783.73;
           1501.95 -2300.82 -762.38;
           1501.95 -2500.77 -750.65;
           1501.95 -2700.88 -741.00;
           1501.95 -2902.06 -725.40;
           1501.95 -3105.43 -721.50;
           1501.95 -3299.49 -716.67;
           1501.95 -3500.21 -716.67;
          ];

subplot(212);
plot(data_yz(:,2),data_yz(:,3),'o');
hold on;
axis equal;
xlabel('Y_p [um]');
ylabel('Z_p [um]');
grid on;
set(gca,'XDir','Reverse');

p_yz = polyfit(data_yz(:,2),data_yz(:,3),2);
y_cont = linspace(min(data_yz(:,2)),max(data_yz(:,2)),1e3);
yz_cont = polyval(p_yz,y_cont);
plot(y_cont,yz_cont,'r','linewidth',2);
legend('Measured',...
       sprintf('Quadratic fit (R=%.1f mm)',abs(1/(2*p_yz(1))/1e3)),...
       'Location','SouthWest');
% return;

% STEP 3: Show the XZ and YZ measurements in 3D
%------------------------------------------------------------
figure;
plot3(data_xz(:,1),data_xz(:,2),data_xz(:,3),'o'); hold on;
plot3(data_yz(:,1),data_yz(:,2),data_yz(:,3),'rx');
axis equal;
grid on;
xlabel('X_p [um]');
ylabel('Y_p [um]');
zlabel('Z_p [um]');
view([-37.5+90 30]);
set(gca,'XDir','Reverse');
set(gca,'YDir','Reverse');
% return;

% STEP 4: Output XYZ positions to Prairie-readable list
%------------------------------------------------------------
write = 1;

% Tiling parameters
xlimits = [2000 500]; % Slow axis
ylimits = [-1500 -3000]; % Fast axis
tile_size = 200; % um
height_offset = -50; % um (negative means deeper in tissue)

% No more tiling parameters below
xlimits = sort(xlimits);
ylimits = sort(ylimits);
xs = xlimits(1):tile_size:xlimits(2); xs = xs';
ys = ylimits(1):tile_size:ylimits(2); ys = ys';
Nxs = length(xs);
Nys = length(ys);

% Fill in slow axis
XYZ = [kron(xs,ones(Nys,1)) zeros(Nxs*Nys,2)];

% Fill in fast axis bidirectionally
for i = 1:length(xs)
    XYZ(Nys*(i-1)+1:Nys*i,2) = ys;
    ys = flipud(ys);
end

% Compute the z coordinates
y0 = mean(data_xz(:,2));
for i = 1:size(XYZ,1)
    x = XYZ(i,1); y = XYZ(i,2);
    XYZ(i,3) = polyval(p_xz,x)+...
               (polyval(p_yz,y)-polyval(p_yz,y0))+...
               height_offset;
end

plot3(XYZ(:,1),XYZ(:,2),XYZ(:,3),'k.-');
plot3(XYZ(1,1),XYZ(1,2),XYZ(1,3),'ko'); % Start position

legend('XZ measurement',...
       'YZ measurement',...
       'Tiling coordinates',...
       'Tiling start point');

if(write)
    fid = fopen('fittedXYZ.xy','w'); %#ok<*UNRCH>
    WritePrarieXY(fid,XYZ);
    fclose(fid);
end