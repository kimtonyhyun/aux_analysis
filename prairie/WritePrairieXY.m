function WritePrarieXY(filename, XYZ)
% Format a matrix of XYZ positions into an XML file compatible with Prairie
% View 4.0.0.18

fid = fopen(filename, 'w');

fprintf(fid,'<?xml version="1.0" encoding="utf-8"?>\n');
fprintf(fid,'<StageLocations>\n');

nXYZ = size(XYZ,1);
for i = 1:nXYZ
    xyline = sprintf('  <StageLocation index="%d" x="%.2f" y="%.2f" z="%.2f" />\n',...
                     i, XYZ(i,1), XYZ(i,2), XYZ(i,3));
    fprintf(fid,xyline);
end

fprintf(fid,'</StageLocations>');

fclose(fid);