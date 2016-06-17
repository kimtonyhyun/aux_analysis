rc=atsif_setfileaccessmode(0); %sets up the sif library to set the access property to load the entire file

 [FileName,PathName,FilterIndex]=uigetfile('*.sif;*.SIF', 'Select SIF'); % opens dialog to let the user select sif to open
absfilepath=strcat(PathName,FileName);; % sets up the file name
rc=atsif_readfromfile(absfilepath); % attempt to open the file

if (rc == 22002) % check that the file was successfully opened
  signal=0;
  [rc,present]=atsif_isdatasourcepresent(signal);  % check there is a signal present
  if present
    [rc,no_frames]=atsif_getnumberframes(signal);  % query the number of frames contained in the file (e.g. in the instance of a kinetic series there may be more than 1
    if (no_frames > 0)
        [rc,size]=atsif_getframesize(signal);
        [rc,left,bottom,right,top,hBin,vBin]=atsif_getsubimageinfo(signal,0); % get the dimensions of the frame to open
        xaxis=0;
        [rc,data]=atsif_getframe(signal,0,size); % retrieve the frame data
        [rc,pattern]=atsif_getpropertyvalue(signal,'ReadPattern');
        if(pattern == '0') %FVB
           calibvals = zeros(1,size);
           for i=1:size,[rc,calibvals(i)]=atsif_getpixelcalibration(signal,xaxis,(i)); %gets the x-calibration of each pixel (either pixel no. or wavelength
           end 
           plot(calibvals,data); % display the 1D data      
           title('spectrum');
		   %set up the axis labelling appropriately
           [rc,xtype]=atsif_getpropertyvalue(signal,'XAxisType');
           [rc,xunit]=atsif_getpropertyvalue(signal,'XAxisUnit');
           [rc,ytype]=atsif_getpropertyvalue(signal,'YAxisType');
           [rc,yunit]=atsif_getpropertyvalue(signal,'YAxisUnit');
           xlabel({xtype;xunit});
           ylabel({ytype;yunit});
        elseif(pattern == '4') % image
            width = ((right - left)+1)/hBin;
            height = ((top-bottom)+1)/vBin;
           newdata=reshape(data,width,height); % reshape the 1D array to a 2D array for display
           imagesc(newdata);
        else
		  %TODO - implement for single-track, multi-track & random track
		  disp('It is not possible to display this acquisition format at this time...')
		end
    end    
  end
else
  disp('Could not load file.  ERROR - ');
  disp(rc);
end
