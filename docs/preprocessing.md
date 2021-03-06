---
layout: default
title: 2. Preprocess movie
nav_order: 3
---

# 2. Preprocess movie
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Correct for slow changes in the movie brightness

Over the course of a recording, the brightness of the calcium movie can change. This is usually a gradual decrease over the session, though not always. This effect can come from light bleaching of the indicator each day, or extraneous factors like the slow loss of immersion fluid.

I correct for the slow changes in movie brightness with the function `meancorr_movie`:
```
>> meancorr_movie('ctx.hdf5', '');
meancorr_movie: Output movie will be saved as "ctx_uc.hdf5"
09-Jul-2019 15:48:06: Examining chunk 1 of 13 from ctx.hdf5...
...
09-Jul-2019 15:49:33: Examining chunk 13 of 13 from ctx.hdf5...
09-Jul-2019 15:49:40: Done!
meancorr_movie: Please select one of following fits:
  1: exp2 (Rsq=0.0936)
  2: poly1 (Rsq=0.0311)
  >> 
```
The function `meancorr_movie` computes the average fluorescence value for each frame, and then attempts to fit a decaying exponential function or a linear function to the measurements. The results are shown in a plot:

![meancorr_movie fits](meancorr_fits.png)

where the raw data are black dots, and the fits are shown in red (decaying exponential) or blue (linear fit). For this example, the decaying exponential fit is clearly better, so I type in `1` at the prompt:
```
...
meancorr_movie: Please select one of following fits:
  1: exp2 (Rsq=0.0936)
  2: poly1 (Rsq=0.0311)
  >> 1
Fit selected (exp2)!
09-Jul-2019 15:56:36: Computing mean correction for frames 1 to 2500 (out of 32100)...
...
09-Jul-2019 15:58:11: Computing mean correction for frames 30001 to 32100 (out of 32100)...
09-Jul-2019 15:58:17: Done!
```

When done, `meancorr_movie` generates a new movie file (by default by appending `_uc` to the input filename, _e.g._ `ctx_uc.hdf5` in this example). The original file (_i.e._ `ctx.hdf5`) can be deleted at this point.

---

## Motion correction

Next, run motion correction ([NoRMCorre](https://github.com/flatironinstitute/NoRMCorre)) using the `run_normcorre` "wrapper" function as follows:
```
>> run_normcorre('ctx_uc.hdf5', '');
run_normcorre: Output movie will be saved as "ctx_uc_nc.hdf5"
ctx_uc.hdf5: Nonrigid NC grid size is [128 128] px, with max shift of 50 px
<Some Matlab warnings about temporary variables>
50 out of 32100 frames registered, iteration 1 out of 2 
...
32100 out of 32100 frames registered, iteration 2 out of 2 
run_normcorre: Finished in 203.7 minutes!
```
Depending on the specs of your analysis machine, the motion correction of a ~32000 frame movie will take a few hours.

The funtion `run_normcorre` generates two new files:

- `ctx_uc_nc.hdf5`: The motion corrected movie ("nc" is short for NoRMCorre),
- `ctx_uc_nc.mat`: Motion correction parameters for each frame. The contents of this MAT file can be used, for example, to correct alternative color channels of the same recording.

Note: I would not yet delete the original movie (`ctx_uc.hdf5`) until the motion corrected movie has been manually inspected to be of acceptable quality.

### (Optional) Applying pre-computed NC parameters to a new movie

As discussed above, each run of `run_normcorre` will produce an auxiliary `*.mat` file that stores the motion correction parameters for each frame. These parameters can later be applied to other movies, as shown below.

An important use case for this feature is when we have simultaneously-acquired multi-color recordings from a single field-of-view. For example, we may have GCaMP expressed pan-neuronally and a static fluorophor (e.g. tdTomato) expressed in a specific cellular subtype. In this case, we may want to compute the motion correction parameters from the static channel, then apply those parameters onto the active (i.e. GCaMP) channel.

Suppose we applied NoRMCorre to the tdTomato channel, and obtained the following files:
- `str-tdt_uc_nc.hdf5`: Motion corrected movie (`-tdt` indicates tdTomato),
- `str-tdt_uc_nc.mat`: Associated motion correction parameters.

Our goal now is to apply the tdTomato motion correction parameters to the GCaMP movie:
- `str_uc.hdf5`: Pre-motion corrected GCaMP movie.

First, load the contents of `str-tdt_uc_nc.mat` into the Matlab workspace. This can be performed by double-clicking the file in the "Current Folder" window of Matlab, or by the following command:
```
>> load('str-tdt_uc_nc.mat')
```
which loads the variables `info` and `shifts` into the workspace.

Next, the motion correction parameters can be applied to the GCaMP movie as follows:
```
>> apply_shifts('str_uc.hdf5', shifts, info.nc_options);
```

---

## Z-score the movie

Next, we z-score the movie (pixelwise) as follows:
```
>> zscore_movie('ctx_uc_nc.hdf5', '');
zscore_movie: Output movie will be saved as "ctx_uc_nc_zsc.hdf5"
09-Jul-2019 19:26:29: Reading frames 1 to 2500 for STD image (out of 32100)...
...
09-Jul-2019 19:27:48: Reading frames 30001 to 32100 for STD image (out of 32100)...
zscore_movie: Press enter to proceed >>
```

The function `zscore_movie` first computes, for each pixel, the mean value and the standard deviation over all frames. The "standard deviation image" is then shown, along with a prompt to continue with the z-scoring of the movie. By default, the output file has `_zsc` appended to the filename, _e.g._ `ctx_uc_nc_zsc.hdf5`.

Note: For archival purposes, storing either `ctx_uc_nc.hdf5` or `ctx_uc_nc_zsc.hdf5` is sufficient. It's possible to recover one from the other. I usually store the pre-z-scored movie (_i.e._ `ctx_uc_nc.hdf5`).

---

## Temporally bin the movie

For running cell extraction algorithms (_e.g._ CNMF) and for visual inspection purposes, I like to temporally downsample the movie by averaging every N frames together. Typically, I use N=8 for movies that are ~30k--50k frames long.

The temporal binning is performed by:
```
>> bin_movie_in_time('ctx_uc_nc_zsc.hdf5', '', 8);
bin_movie_in_time: Output movie will be saved as "ctx_uc_nc_zsc_ti8.hdf5"
Warning: Source HDF5 file lacks "Params" directory
Warning: Frame rate of file "ctx_uc_nc_zsc.hdf5" is unknown
09-Jul-2019 19:30:32: Temporally binning Trial 1 of 5...
...
09-Jul-2019 19:31:23: Temporally binning Trial 5 of 5...
09-Jul-2019 19:31:23: Done!
```
where the last parameter (8, in the above case) is the number of frames to be averaged. The function `bin_movie_in_time` then generates a new HDF5 file with `_tiN` appended to the name where N is the binning parameter.

(Aside: the console output of `bin_movie_in_time` reports that it's proceeding in units of "Trials", but this can be safely ignored. The function was originally intended to bin trial-based recordings with non-imaging ITI periods---where it was important to bin frames only within the same trial.)

__Important: Do not delete the original, non-time-binned movie.__ It is not possible to recover the full temporal resolution from the time-binned movie.
