%% Template: CT Window/Level for Tissue Visualization
% Apply standard CT windowing presets (lung, bone, soft tissue, brain, liver)
% and display multiple views side-by-side for diagnostic comparison.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath = '';  % TODO: Path to your CT DICOM or image file
outputDir = '';  % TODO: Path to save results

%% Step 1: Load CT Image
% For DICOM files use dicomread; for standard images use imread
% img = dicomread(inputPath);  % Uncomment for DICOM
% info = dicominfo(inputPath);
img = imread(inputPath);  % TODO: Switch to dicomread for DICOM
if size(img, 3) == 3
    img = rgb2gray(img);
end
ctImage = double(img);

% TODO: If using raw DICOM, apply rescale slope/intercept for Hounsfield Units
% ctImage = double(img) * info.RescaleSlope + info.RescaleIntercept;
fprintf('CT image loaded: %d x %d, range [%.0f, %.0f] HU\n', ...
    size(ctImage, 1), size(ctImage, 2), min(ctImage(:)), max(ctImage(:)));

%% Step 2: Define CT Window Presets
% Each preset: [Window Width, Window Level] in Hounsfield Units
presets = struct();
presets.Lung       = struct('WW', 1500, 'WL', -600,  'desc', 'Lung parenchyma');
presets.Bone       = struct('WW', 2000, 'WL',  300,  'desc', 'Bone structures');
presets.SoftTissue = struct('WW',  400, 'WL',   40,  'desc', 'Soft tissue');
presets.Brain      = struct('WW',   80, 'WL',   40,  'desc', 'Brain parenchyma');
presets.Liver      = struct('WW',  150, 'WL',   30,  'desc', 'Liver/abdomen');

% TODO: Add custom presets as needed
% presets.Custom = struct('WW', 300, 'WL', 50, 'desc', 'Custom window');

%% Step 3: Apply Windowing Function
presetNames = fieldnames(presets);
numPresets = numel(presetNames);
windowedImages = cell(1, numPresets);

for k = 1:numPresets
    p = presets.(presetNames{k});
    wMin = p.WL - p.WW / 2;
    wMax = p.WL + p.WW / 2;

    % Clip intensities to window range and normalize to [0, 1]
    windowedImages{k} = mat2gray(ctImage, [wMin, wMax]);
end

%% Step 4: Display All Windows Side-by-Side Using Montage
% Build labeled montage array
tileRows = ceil(numPresets / 3);
tileCols = min(numPresets, 3);

figure('Name', 'CT Windowing Presets', 'Position', [50 50 400*tileCols 400*tileRows]);

for k = 1:numPresets
    subplot(tileRows, tileCols, k);
    imshow(windowedImages{k}, []);
    p = presets.(presetNames{k});
    title(sprintf('%s\nWW=%d, WL=%d', p.desc, p.WW, p.WL));
end

sgtitle('CT Window/Level Presets');

%% Step 5: Interactive Window/Level (Optional)
% TODO: Set custom window width and level
customWW = 400;  % TODO: Custom window width
customWL = 40;   % TODO: Custom window level

customMin = customWL - customWW / 2;
customMax = customWL + customWW / 2;
customWindowed = mat2gray(ctImage, [customMin, customMax]);

figure('Name', 'Custom CT Window');
imshow(customWindowed, []);
title(sprintf('Custom Window — WW=%d, WL=%d', customWW, customWL));

%% Step 6: Montage Display of All Presets
% Stack windowed images for montage
[rows, cols] = size(ctImage);
montageStack = zeros(rows, cols, 1, numPresets);
for k = 1:numPresets
    montageStack(:, :, 1, k) = windowedImages{k};
end

figure('Name', 'CT Windowing Montage');
montage(montageStack, 'Size', [1 numPresets], 'DisplayRange', [0 1]);
title('All CT Window Presets');

%% Step 7: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    for k = 1:numPresets
        fname = sprintf('ct_%s.png', lower(presetNames{k}));
        imwrite(windowedImages{k}, fullfile(outputDir, fname));
    end
    imwrite(customWindowed, fullfile(outputDir, 'ct_custom_window.png'));
    fprintf('Saved %d windowed images to: %s\n', numPresets + 1, outputDir);
end

%% Summary
fprintf('\n--- CT Windowing Summary ---\n');
for k = 1:numPresets
    p = presets.(presetNames{k});
    fprintf('  %-12s: WW=%4d, WL=%4d  (%s)\n', presetNames{k}, p.WW, p.WL, p.desc);
end
