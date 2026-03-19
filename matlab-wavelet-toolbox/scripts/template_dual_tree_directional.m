%% Template: Dual-Tree CWT Directional Analysis for Vessels/Fibers
% Use dualtree2/idualtree2 for 6-directional analysis of biomedical structures.
% Extract directional energy maps for retinal vessels and fiber orientation.
% MATLAB R2025b | Wavelet Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Wavelet Toolbox
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath   = '';  % TODO: Path to image (e.g., 'retinal_fundus.png')
outputDir   = '';  % TODO: Path to save results
decompLevel = 4;   % TODO: Number of decomposition levels

%% Step 1: Load and prepare image
img = imread(inputPath);
if ndims(img) == 3, img = rgb2gray(img); end
img = im2double(img);
[rows, cols] = size(img);
% Pad to even dimensions (required by dualtree2)
padR = mod(rows, 2); padC = mod(cols, 2);
if padR || padC
    img = padarray(img, [padR, padC], 'symmetric', 'post');
end

%% Step 2: Dual-tree complex wavelet decomposition
% Provides 6 directional subbands per level: +/-15, +/-45, +/-75 degrees
[A, D] = dualtree2(img, 'Level', decompLevel);
dirLabels = {'+15','-15','+45','-45','+75','-75'};
numDirs = 6;

%% Step 3: Extract directional energy at each level
energyMaps = cell(decompLevel, numDirs);
totalEnergy = zeros(decompLevel, numDirs);
for lev = 1:decompLevel
    for d = 1:numDirs
        energyMaps{lev, d} = abs(D{lev}(:,:,d)).^2;
        totalEnergy(lev, d) = sum(energyMaps{lev, d}(:));
    end
    totalEnergy(lev, :) = totalEnergy(lev, :) / sum(totalEnergy(lev, :));
end

%% Step 4: Compute dominant orientation map (finest level)
dominantDir = zeros(size(D{1}, 1), size(D{1}, 2));
maxE = zeros(size(D{1}, 1), size(D{1}, 2));
for d = 1:numDirs
    emap = energyMaps{1, d};
    mask = emap > maxE;
    dominantDir(mask) = d;
    maxE(mask) = emap(mask);
end

%% Step 5: Directional filtering — enhance specific orientations
% TODO: Select target direction(s) to enhance (1-6)
targetDirs = [3, 4];  % +/-45 degrees (e.g., diagonal vessels)
D_filtered = D;
for lev = 1:decompLevel
    for d = 1:numDirs
        if ~ismember(d, targetDirs)
            D_filtered{lev}(:,:,d) = 0;
        end
    end
end
enhanced = idualtree2(A, D_filtered);
enhanced = enhanced(1:rows, 1:cols);

%% Step 6: Multi-scale directional summary
fprintf('\n--- Directional Energy Summary ---\n');
for lev = 1:decompLevel
    [mxE, mxD] = max(totalEnergy(lev, :));
    fprintf('Level %d: Dominant = %s deg (%.1f%%)\n', lev, dirLabels{mxD}, mxE*100);
end

%% Step 7: Visualize
figure('Name', 'Directional Analysis', 'Position', [50 50 1200 800]);
subplot(2,3,1); imshow(img(1:rows,1:cols), []); title('Original');
subplot(2,3,2);
combinedE = zeros(size(energyMaps{1,1}));
for d = 1:numDirs, combinedE = combinedE + energyMaps{1,d}; end
imagesc(combinedE); colorbar; colormap(hot); title('Total Energy L1'); axis image;
subplot(2,3,3); imagesc(dominantDir); colorbar; colormap(hsv(numDirs));
title('Dominant Orientation'); axis image;
subplot(2,3,4); imshow(enhanced, []); title(sprintf('Enhanced (dirs %s)', mat2str(targetDirs)));
subplot(2,3,5); bar(totalEnergy');
xlabel('Direction'); ylabel('Normalized Energy');
set(gca, 'XTickLabel', dirLabels); title('Energy Distribution'); grid on;
legend(arrayfun(@(x) sprintf('L%d',x), 1:decompLevel, 'UniformOutput', false));
subplot(2,3,6);
angles = deg2rad([15,-15,45,-45,75,-75]);
[sa, si] = sort(angles); se = totalEnergy(1, si);
polarplot([sa, sa(1)], [se, se(1)], '-o', 'LineWidth', 2);
title('Orientation Rose (L1)');

%% Step 8: Save results
if ~isfolder(outputDir), mkdir(outputDir); end
imwrite(mat2gray(enhanced), fullfile(outputDir, 'directional_enhanced.png'));
save(fullfile(outputDir, 'directional_features.mat'), 'totalEnergy', 'energyMaps', 'dominantDir');
saveas(gcf, fullfile(outputDir, 'directional_analysis.png'));
fprintf('Results saved to: %s\n', outputDir);
