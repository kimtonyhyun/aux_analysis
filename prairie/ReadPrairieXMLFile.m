% Tony Hyun Kim
% 2013 06 29
% Returns the contents of Prairie XML file as two structs:
%   s: Complete XML contents as a struct
%   p: "PVStateShard" elements as a struct, contains all parameters 
%      relevant to pixel to real space calibration
function [s, p] = ReadPrairieXMLFile(filename)

s = xml2struct_prairie(filename);
frame = s.PVScan.Sequence.Frame;
if iscell(frame) % If multiple frames, find info on the first
    frame = frame{1};
end
pvstate = frame.PVStateShard.Key;

p = struct();
for i = 1:length(pvstate)
    p = setfield(p,...
                 pvstate{i}.Attributes.key,...
                 pvstate{i}.Attributes.value); %#ok<SFLD>
end