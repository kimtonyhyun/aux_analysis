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

Over the course of a recording, the brightness of the calcium movie can change (usually a gradual decrease, though not always). This effect can come from light bleaching of the indicator each day, or extraneous factors like the slow loss of immersion fluid.

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

When done, `meancorr_movie` generates a new movie file (by default by appending `_uc` to the input filename, _e.g._ `ctx_uc.hdf5` in this example). The original file (_e.g._ `ctx.hdf5`) can be deleted at this point.
