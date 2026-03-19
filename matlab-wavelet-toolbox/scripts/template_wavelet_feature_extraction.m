%% Template: Multi-Scale Wavelet Texture Feature Extraction
% Extract energy, entropy, mean, and std from wavelet subbands for tissue
% classification. Builds feature vectors ready for ML classifier input.
% MATLAB R2025b | Wavelet Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Wavelet Toolbox
%   - Statistics and Machine Learning Toolbox

%% TODO: Configure your data paths and parameters
imageDir    = '';  % TODO: Directory containing images (e.g., './dataset/')
outputPath  = '';  % TODO: Path to save feature table (e.g., './features.mat')
waveletName = 'sym8';
decompLevel = 3;          % TODO: Number of decomposition levels
roiSize     = [64, 64];   % TODO: ROI patch size (set [] to use full image)

%% Step 1: Gather image file list and labels
fileList = dir(fullfile(imageDir, '*.png'));  % TODO: Adjust pattern
numImages = numel(fileList);
fprintf('Found %d images\n', numImages);
labels = strings(numImages, 1);
for i = 1:numImages
    tokens = split(fileList(i).name, '_');
    labels(i) = tokens{1};  % TODO: Adjust label parsing
end

%% Step 2: Define feature extraction function
function feats = extractWaveletFeatures(img, wname, nLev)
    maxLev = wmaxlev(size(img), wname);
    level = min(nLev, maxLev);
    [C, S] = wavedec2(img, level, wname);
    feats = [];
    for lev = 1:level
        [cH, cV, cD] = detcoef2('all', C, S, lev);
        for sb = 1:3
            switch sb, case 1, co=cH; case 2, co=cV; case 3, co=cD; end
            energy = sum(co(:).^2) / numel(co);
            p = co(:).^2 / (sum(co(:).^2) + eps);
            ent = -sum(p .* log2(p + eps));
            feats = [feats, energy, ent, mean(abs(co(:))), std(co(:))]; %#ok<AGROW>
        end
    end
    cA = appcoef2(C, S, wname, level);
    feats = [feats, mean(cA(:)), std(cA(:)), sum(cA(:).^2)/numel(cA), median(cA(:))];
end

%% Step 3: Build feature names
featureNames = {};
for lev = 1:decompLevel
    for sb = {'H','V','D'}
        for m = {'Energy','Entropy','MeanAbs','Std'}
            featureNames{end+1} = sprintf('L%d_%s_%s', lev, sb{1}, m{1}); %#ok<SAGROW>
        end
    end
end
featureNames = [featureNames, {'Approx_Mean','Approx_Std','Approx_Energy','Approx_Median'}];
numFeatures = numel(featureNames);

%% Step 4: Extract features from all images
featureMatrix = zeros(numImages, numFeatures);
for i = 1:numImages
    img = imread(fullfile(imageDir, fileList(i).name));
    if ndims(img) == 3, img = rgb2gray(img); end
    img = im2double(img);
    if ~isempty(roiSize)
        [r, c] = size(img);
        r0 = max(1, floor((r-roiSize(1))/2)+1);
        c0 = max(1, floor((c-roiSize(2))/2)+1);
        img = img(r0:r0+roiSize(1)-1, c0:c0+roiSize(2)-1);
    end
    featureMatrix(i,:) = extractWaveletFeatures(img, waveletName, decompLevel);
    if mod(i,50)==0, fprintf('Processed %d/%d\n', i, numImages); end
end

%% Step 5: Build feature table
featureTable = array2table(featureMatrix, 'VariableNames', featureNames);
featureTable.Label = categorical(labels);
fprintf('Feature table: %d samples x %d features\n', height(featureTable), numFeatures);

%% Step 6: Feature analysis visualization
figure('Name', 'Wavelet Features', 'Position', [100 100 1000 400]);
subplot(1,2,1); bar(var(featureMatrix));
xlabel('Feature Index'); ylabel('Variance'); title('Feature Variance'); grid on;
subplot(1,2,2); imagesc(corr(featureMatrix)); colorbar; colormap(jet);
title('Feature Correlation'); xlabel('Feature'); ylabel('Feature');

%% Step 7: Classification (uncomment to run)
% cv = cvpartition(featureTable.Label, 'HoldOut', 0.3);
% mdl = fitcecoc(featureTable(training(cv),:), 'Label', 'Learners', 'svm');
% pred = predict(mdl, featureTable(test(cv),:));
% fprintf('Accuracy: %.2f%%\n', 100*sum(pred==featureTable.Label(test(cv)))/nnz(test(cv)));

%% Step 8: Save features
save(outputPath, 'featureTable', 'featureNames', 'waveletName', 'decompLevel');
fprintf('Features saved to: %s\n', outputPath);
