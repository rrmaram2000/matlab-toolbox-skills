# Mask R-CNN Nuclei Instance Segmentation — Without Skill

## Prompt
"Train a Mask R-CNN to detect and segment individual cell nuclei in H&E histopathology images. Include creating the detector, training, inference with segmentObjects, and visualization."

## Key Issue: Hallucinated Function
The agent used `trainMaskRCNNObjectDetector` — a function that **does not exist** in MATLAB R2025b.

### Runtime Verification
```matlab
>> which('trainMaskRCNNObjectDetector')
'trainMaskRCNNObjectDetector' not found.

>> which('maskrcnn')
/Applications/MATLAB_R2025b.app/toolbox/vision/vision/maskrcnn.m
```

## What Went Wrong
1. **`trainMaskRCNNObjectDetector`** — hallucinated combined create-and-train function. The correct workflow is `maskrcnn()` to create the detector, then `trainMaskRCNN()` to train it.
2. **`detect()` instead of `segmentObjects()`** — used generic object detection inference instead of the instance segmentation function.
3. **Wrong output order** — `[bboxes, scores, labels, masks]` instead of `[masks, labels, scores, bboxes]`.

## Verdict
**FAIL** — Script crashes immediately at `trainMaskRCNNObjectDetector`. The function name sounds plausible (similar to `trainRCNNObjectDetector` which did exist in older MATLAB) but does not exist for Mask R-CNN in R2025b.
