%% Template: Low-Dose CT Denoising with Wavelet Thresholding
% Reduce quantum noise in low-dose CT images using multiple wdenoise2
% thresholding rules with subband-adaptive processing and edge preservation.
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
inputPath  = '';  % TODO: Path to low-dose CT slice (e.g., 'ct_lowdose.dcm')
outputDir  = '';  % TODO: Path to save results
waveletName = 'sym8';
boundaryMode = 'symmetric';  % Recommended for medical images

%% Step 1: Load CT data
% TODO: Adjust loading for your data format (DICOM, PNG, MAT, etc.)
info = dicominfo(inputPath);
img = double(dicomread(info));
% Normalize to [0, 1] for processing
imgMin = min(img(:));
imgMax = max(img(:));
imgNorm = (img - imgMin) / (imgMax - imgMin);

%% Step 2: Determine maximum decomposition level
maxLev = wmaxlev(size(imgNorm), waveletName);
fprintf('Max decomposition level: %d\n', maxLev);
decompLevel = min(4, maxLev);  % TODO: Adjust level as needed

%% Step 3: Apply wdenoise2 with SURE thresholding
denoisedSURE = wdenoise2(imgNorm, decompLevel, ...
    'Wavelet', waveletName, ...
    'DenoisingMethod', 'SURE', ...
    'ThresholdRule', 'Soft', ...
    'NoiseEstimate', 'LevelDependent');

%% Step 4: Apply wdenoise2 with Minimax thresholding
denoisedMinimax = wdenoise2(imgNorm, decompLevel, ...
    'Wavelet', waveletName, ...
    'DenoisingMethod', 'Minimax', ...
    'ThresholdRule', 'Soft', ...
    'NoiseEstimate', 'LevelDependent');

%% Step 5: Apply wdenoise2 with UniversalThreshold
denoisedUniv = wdenoise2(imgNorm, decompLevel, ...
    'Wavelet', waveletName, ...
    'DenoisingMethod', 'UniversalThreshold', ...
    'ThresholdRule', 'Soft', ...
    'NoiseEstimate', 'LevelDependent');

%% Step 6: Subband-adaptive thresholding (manual approach)
[C, S] = wavedec2(imgNorm, decompLevel, waveletName);
% Estimate noise from finest-scale diagonal detail
[cH1, cV1, cD1] = detcoef2('all', C, S, 1);
sigmaNoise = median(abs(cD1(:))) / 0.6745;

% Apply level-dependent thresholds
Cadapt = C;
for lev = 1:decompLevel
    % Extract detail coefficients at each level
    [cH, cV, cD] = detcoef2('all', C, S, lev);
    % Scale threshold by level (coarser levels get lower threshold)
    scaleFactor = 1.0 / sqrt(lev);
    thr = scaleFactor * sigmaNoise * sqrt(2 * log(numel(cH)));
    % Soft thresholding
    cH = sign(cH) .* max(abs(cH) - thr, 0);
    cV = sign(cV) .* max(abs(cV) - thr, 0);
    cD = sign(cD) .* max(abs(cD) - thr, 0);
    % Write back thresholded coefficients
    Cadapt = setDetailCoeffs(Cadapt, S, lev, cH, cV, cD);
end
denoisedAdapt = waverec2(Cadapt, S, waveletName);

%% Step 7: Edge preservation analysis
edgeOrig  = edge(imgNorm, 'Canny', 0.1);
edgeSURE  = edge(denoisedSURE, 'Canny', 0.1);
edgeMini  = edge(denoisedMinimax, 'Canny', 0.1);
edgeUniv  = edge(denoisedUniv, 'Canny', 0.1);
edgeAdapt = edge(denoisedAdapt, 'Canny', 0.1);

% Edge preservation index (higher is better)
epiSURE  = sum(edgeOrig(:) & edgeSURE(:))  / sum(edgeOrig(:));
epiMini  = sum(edgeOrig(:) & edgeMini(:))  / sum(edgeOrig(:));
epiUniv  = sum(edgeOrig(:) & edgeUniv(:))  / sum(edgeOrig(:));
epiAdapt = sum(edgeOrig(:) & edgeAdapt(:)) / sum(edgeOrig(:));

fprintf('\n--- Edge Preservation Index ---\n');
fprintf('SURE:              %.4f\n', epiSURE);
fprintf('Minimax:           %.4f\n', epiMini);
fprintf('UniversalThreshold:%.4f\n', epiUniv);
fprintf('Subband-Adaptive:  %.4f\n', epiAdapt);

%% Step 8: Visualize results
figure('Name', 'CT Denoising Comparison', 'Position', [50 50 1400 700]);

subplot(2,3,1); imshow(imgNorm, []); title('Original Low-Dose CT');
subplot(2,3,2); imshow(denoisedSURE, []); title(sprintf('SURE (EPI=%.3f)', epiSURE));
subplot(2,3,3); imshow(denoisedMinimax, []); title(sprintf('Minimax (EPI=%.3f)', epiMini));
subplot(2,3,4); imshow(denoisedUniv, []); title(sprintf('Universal (EPI=%.3f)', epiUniv));
subplot(2,3,5); imshow(denoisedAdapt, []); title(sprintf('Adaptive (EPI=%.3f)', epiAdapt));

subplot(2,3,6);
bar([epiSURE, epiMini, epiUniv, epiAdapt]);
set(gca, 'XTickLabel', {'SURE','Minimax','Universal','Adaptive'});
ylabel('Edge Preservation Index'); title('Method Comparison');
grid on;

%% Step 9: Save results
if ~isfolder(outputDir), mkdir(outputDir); end
imwrite(denoisedSURE, fullfile(outputDir, 'ct_denoised_sure.png'));
imwrite(denoisedAdapt, fullfile(outputDir, 'ct_denoised_adaptive.png'));
saveas(gcf, fullfile(outputDir, 'ct_denoising_comparison.png'));
fprintf('Results saved to: %s\n', outputDir);

%% Local Functions
function C = setDetailCoeffs(C, S, lev, cH, cV, cD)
    % Write detail coefficients back into wavedec2 coefficient vector C
    N = size(S,1) - 2;
    first = prod(S(1,:));
    for k = N:-1:(lev+1)
        first = first + 3 * prod(S(N+2-k,:));
    end
    first = first + 1;
    len = prod(S(N+2-lev,:));
    C(first : first+len-1) = cH(:);
    C(first+len : first+2*len-1) = cV(:);
    C(first+2*len : first+3*len-1) = cD(:);
end
