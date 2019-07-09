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
