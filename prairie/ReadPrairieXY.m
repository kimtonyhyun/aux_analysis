function XYZ = ReadPrairieXY(xyfile)

s = xml2struct_prairie(xyfile);

s = s.StageLocations.StageLocation;
N = length(s);

XYZ = zeros(N,3);
for i = 1:N
    XYZ(i,:) = [str2double(s{i}.Attributes.x);
                str2double(s{i}.Attributes.y);
                str2double(s{i}.Attributes.z)]';
end