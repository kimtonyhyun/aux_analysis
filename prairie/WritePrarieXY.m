function WritePrarieXY(fid, XYZ)

fprintf(fid,'<?xml version="1.0" encoding="utf-8"?>\n');
fprintf(fid,'<StageLocations>\n');

nXYZ = size(XYZ,1);
for i = 1:nXYZ
    xyline = sprintf('  <StageLocation index="%d" x="%.2f" y="%.2f" z="%.2f" />\n',...
                     i, XYZ(i,1), XYZ(i,2), XYZ(i,3));
    fprintf(fid,xyline);
end

fprintf(fid,'</StageLocations>');