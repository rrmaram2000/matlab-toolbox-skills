# Mask R-CNN Nuclei Instance Segmentation — With Skill

## Prompt
"Train a Mask R-CNN to detect and segment individual cell nuclei in H&E histopathology images. Include creating the detector, training, inference with segmentObjects, and visualization."

## Skill Consultation
The agent consulted:
- `matlab-deep-learning/SKILL.md` — Critical Rules section
- `matlab-deep-learning/knowledge/cards/detection-instance-seg.md` — Mask R-CNN API
- `matlab-deep-learning/scripts/template_maskrcnn_instance_seg.m` — Reference template

## Key API Decisions (Guided by Skill)
1. **Model creation**: `maskrcnn("resnet50-coco", classNames, InputSize=inputSize)` — the correct R2025b constructor
2. **Training**: `trainMaskRCNN(trainData, detector, options)` — separate creation and training
3. **Inference**: `segmentObjects(trainedDetector, testImg, Threshold=0.5)` — returns `[masks, labels, scores, bboxes]`
4. **Training options**: Uses `trainingOptions("adam", ...)` with validation data

## What the Skill Prevented
- Did NOT use `trainMaskRCNNObjectDetector` (does not exist in MATLAB R2025b)
- Did NOT conflate model creation with training into a single function call
- Used correct output order from `segmentObjects`: `[masks, labels, scores, bboxes]`

## Output
- 162-line complete pipeline with quantitative evaluation
- Per-nucleus coloring visualization
- Area distribution histogram
