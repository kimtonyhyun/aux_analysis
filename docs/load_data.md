---
layout: default
title: 1. Load raw data
nav_order: 2
---

# 1. Load raw data
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Load ScanImage TIFF files

Each arm of the Duopus (dual-axis) microscope is controlled by ScanImage. Thus, the data is saved in [ScanImage TIFF format](http://scanimage.vidriotechnologies.com/display/SI2019/Output+Files).

The TIFF data can be loaded into the Matlab workspace by:
```
>> M = load_scanimage_tif('ctx_00001.tif');
```
where `'ctx_00001.tif'` is the filename of the TIFF file. The PC needs to have, of course, enough RAM to load the entire movie into memory.

## Inspect the movie's fluorescence values

Next, I like to start by inspecting the fluorescence values of the movie: namely, for each frame the minimum, average, and maximum pixel values. This is performed as follows:
```
>> F = compute_fluorescence_stats(M);
09-Jul-2019 14:58:29: Frames 2500 of 32100 examined...
...
09-Jul-2019 14:59:06: Frames 30000 of 32100 examined...
```
The output matrix `F` is a `[num_frames x 3]` matrix where:

- The first column is the minimum pixel value over the frame;
- The second column is the average pixel value over the frame;
- And the third column is the maximum pixel value over the frame.

These fluorescence values can be visualized by:
```
>> plot(F);
```
which yields a plot like the following:
