clear all;

vid = VideoReader('oh5_19-11-06_downDeepCut_resnet50_DualLowerNov22shuffle1_1030000_labeled.mp4');
dlc = load('dlc_bottom.mat');

%%
clear all;

vid = VideoReader('oh5_19-11-06_upDeepCut_resnet50_DualUpperNov13shuffle1_1030000_labeled.mp4');
dlc = load('dlc_side.mat');

%%

coords = dlc.tail;

A = vid.readFrame;
h = image(A);
axis image;
hold on;
dot = plot(1, 1, 'wx');
hold off;

for k = 2:1000
    A = vid.readFrame;
    coord = coords(k,:);
    
    set(h, 'CData', A);
    set(dot, 'XData', coord(1), 'YData', coord(2)); 
end