function M = load_andor_kinetic(source)
% Loads an Andor kinetic series from a SIF file. Based on `sifreadexample`
%

rc = atsif_readfromfile(source);
if (rc == 22002)
    signal = 0;
    [~, present] = atsif_isdatasourcepresent(signal);
    if present
        [~, num_frames] = atsif_getnumberframes(signal);
        [~, exposure_time] = atsif_getpropertyvalue(signal, 'ExposureTime');
        
        fprintf('File "%s" contains %d frames, exposure time %s sec. Loading...\n',...
            source, num_frames, exposure_time);
        
        if (num_frames > 0)
            % Determine the movie pixel size
            [~, left, bottom, right, top, h_bin, v_bin] = atsif_getsubimageinfo(signal, 0);
            height = (top-bottom+1) / h_bin;
            width  = (right-left+1) / v_bin;
            
            M = zeros(height, width, num_frames, 'uint16');
            
            [~, size] = atsif_getframesize(signal);
            for k = 1:num_frames
                [~, data] = atsif_getframe(signal, k-1, size);
                data = reshape(data, width, height)'; % Unwrap
                data = flipud(data);
                M(:,:,k) = data;
            end
        end
    end
    
    atsif_closefile;
else
    fprintf('Could not load file with Error %d!\n', rc);
end