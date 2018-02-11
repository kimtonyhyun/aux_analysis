function h = select_pois(Cn, ds, old_pois)
% Allows for selection of points of interest on top of an image (e.g.
% correlation image as defined by CNMF). Over remote connections more
% responsive than Matlab's built-in 'ginput'.
%
% Retrieve selected POIs via:
%   pois = h.UserData
% Note that h is handle to the figure, and hence its property needs to be
% retrieved before the figure is closed!
%
if (nargin < 3)
    old_pois = [];
end

figure;
h = imagesc(Cn);
axis image;
% colormap gray;
hold on;
plot_boundaries_with_transform(ds, 'g');
if ~isempty(old_pois)
    plot(old_pois(:,1), old_pois(:,2), 'r*', 'HitTest', 'off');
end

set(h, 'ButtonDownFcn', @add_poi);

end % select_pois

function add_poi(h, e)
    coord = e.IntersectionPoint(1:2);
    
    % Provide immediate visual feedback
    plot(coord(1), coord(2), 'm*');
    
    % Add to persistent list
    h.UserData = [h.UserData; coord];
end