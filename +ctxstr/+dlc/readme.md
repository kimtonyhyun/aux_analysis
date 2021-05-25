## Brief instructions for DeepLabCut (DLC) / "Skeleton" analysis

The instructions assume that you have access to:
- The Saleae log for the session (e.g. `oh08-0208.logicdata`),
- The video file used for DLC (e.g. `oh28-0208-down.mp4`),
- DLC output (e.g. `oh28-0208-downDLC_resnet50_oh28May10shuffle1_1030000.csv`).

## 1. Parse the Saleae data

First, parse the Saleae data (as usual):
```
>> ctxstr.parse_saleae('behavior.csv');
Loading Saleae data into memory... Done in 12.5 seconds!
Encoder: 391.7 rotations over 1121.2 seconds (18.7 minutes)
Computed velocity over dt=0.250 second windows
Detected 2 pulses per reward
Detected 256 rewards, excluding the first (free) reward
On average, reward delivered after 750.3 encoder clicks
Lick responses in 234 out of 256 rewards (91.4% hit rate, using 1.0 second response window)
Found 135836 behavior frames at 122.59 FPS
Found 0 opto periods
250 of 256 trials (rewards) fully contained in the imaging period
Found 32000 ctx frames at 29.98 FPS
Found 48000 str frames at 44.69 FPS
```
This creates `ctxstr.mat` in the working directory, which contains (among others) the variable `behavior`, which we will use later in this tutorial.

## 2. Import the DLC output

Next, we need to "import" the DLC output. With the contents of `ctxstr.mat` loaded to the workspace (i.e. the variable `behavior`), use:
```
>> ctxstr.dlc.import(behavior, 'oh28-0208-downDLC_resnet50_oh28May10shuffle1_1030000.csv', 'medfilt', 5);
Found 135836 frames in DeepLabCut CSV output
Expected 135836 behavioral frames from Saleae log
Median filtering window is 5
```
Some details:
- The `import` function checks the number of (behavioral) frames contained in the DLC output (i.e. CSV file) against the expected number of frames from the Saleae log.
- Use the optional `medfilt` option to remove outliers in the DLC output. It seems that a median filtering window of 5 (as in the above example) works well. Still, it may be worthwhile to investigate a few different median filtering windows for each new dataset.

The `import` function generates `dlc.mat` in the working directory. This MAT file contains the XY coordinates of 6 body locations. Namely, the 4 limbs `front_left`, `front_right`, `hind_left`, `hind_right`, and the `nose` and `tail`.

At this point, one can visualize all DLC coordinates as traces (e.g. to look for outliers):
```
>> dlc = load('dlc.mat');
>> ctxstr.dlc.plot_coords(dlc);
```
In addition, one can play back the behavioral video with the DLC coordinates overlaid, by using:
```
>> ctxstr.dlc.verify(dlc, 'oh28-0208-down.mp4');
```
## 3. Compute the skeleton

Finally, we convert the DLC coordinates to a "skeletal" representation. We use the following definition:
![ctxstr_skeleton_defn](https://user-images.githubusercontent.com/2081503/119430195-304f1380-bcc5-11eb-9548-8cc691238475.png)

The skeleton coordinates can be calculated as:
```
>> dlc = load('dlc.mat');
>> ctxstr.dlc.compute_skeleton(dlc);
```
which creates `skeleton.mat` to the working directory.

We can visualize the "skeletal" mouse movement aligned to other behavioral variables (e.g. reward delivery, licking, encoder velocity) using:
```
>> load('ctxstr.mat')
>> sdata = load('skeleton.mat');
>> ctxstr.dlc.show_skeleton(sdata, behavior);
```
