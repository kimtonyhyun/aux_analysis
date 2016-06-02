clear all; close all;
addpath('C:/Users/kimth/Documents/microscope/matlab/_prairie');

% Specify the XY file corresponding to the map
%------------------------------------------------------------
xyfile = fullfile(pwd,'fittedXYZ.xy');
XYZ = ReadPrairieXY(xyfile);

% We assume that each image is contained in a subfolder
%------------------------------------------------------------
ds = dir();     % Enumerate all contents of this directory

clim = [0 4096]/2;

idx = 1; % Index into the XYZ list
for i = 1:length(ds)
    if(~ds(i).isdir || ... % If not a directory, then not an image. Skip.
        strcmp(ds(i).name,'.') || strcmp(ds(i).name,'..'))
        continue;
    end
    
    % Process single image
    %------------------------------------------------------------
    source = fullfile(pwd,ds(i).name);
    
    % Read the XML file
    xmlfile = dir(fullfile(source,'*.xml')); xmlfile = xmlfile.name;
    [~, p] = ReadPrairieXMLFile(fullfile(source,xmlfile));

    fov_x = str2double(p.pixelsPerLine)*str2double(p.micronsPerPixel_XAxis);
    fov_y = str2double(p.linesPerFrame)*str2double(p.micronsPerPixel_YAxis);
    
    % Look for TIF image in the specified directory
    tiffile = dir(fullfile(source,'*.tif')); tiffile = tiffile.name;
    A = imread(fullfile(source,tiffile));
    
    % Locate the image in global coordinate space by using the XYZ list
    RA = imref2d(size(A),...
                 XYZ(idx,1) + [0 fov_x],...
                 XYZ(idx,2) + [0 fov_y]);
    
    imshow(fliplr(A),RA,clim); hold on;
    
    % Increment the XYZ index
    idx = idx + 1;
end

% Format the plot
axis image;
colormap gray;
xlabel('X_p [um]');
ylabel('Y_p [um]');
set(gca,'XDir','Reverse');