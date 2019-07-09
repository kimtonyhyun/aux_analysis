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

Each arm of the Duopus (dual-axis) microscope is controlled by ScanImage. Thus, the data is saved in ScanImage TIFF format.

The TIFF data can be loaded into the Matlab workspace by:
```
>> M = load_scanimage_tif('ctx_00001.tif');
```
where "ctx_00001.tif" is the filename of the TIFF file. The analysis PC should, of course, have enough RAM to load the entire movie into memory.

## Inspect the movie's fluorescence values

I like to start by inspecting the fluorescence values of the movie: namely, for each frame the minimum, average, and maximum pixel values. This is performed as follows:
```
>> F = compute_fluorescence_stats(M);
```
