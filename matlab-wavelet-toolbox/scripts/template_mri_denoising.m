%% Template: MRI Rician Noise Removal via Wavelet Denoising
% Remove Rician noise from MRI slices using wdenoise2 with Bayes and SURE
% thresholding. Compare denoising levels and quantify improvement with PSNR/SSIM.
% MATLAB R2025b | Wavelet Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Wavelet Toolbox
%   - Image Processing Toolbox (for PSNR/SSIM metrics)

%% TODO: Configure your data paths and parameters
inputPath  = '';  % TODO: Path to your MRI slice (e.g., 'brain_t1.png')
outputDir  = '';  % TODO: Path to save results (e.g., './results/')
waveletName = 'sym8';       % Symlet-8 — good for MRI textures
boundaryMode = 'symmetric'; % Recommended for medical images
noiseStdEst = 25;           % TODO: Estimated noise standard deviation (for simulation)

%% Step 1: Load and prepare MRI data
img = imread(inputPath);
if ndims(img) == 3
    img = rgb2gray(img);
end
img = im2double(img);

% Simulate Rician noise for benchmarking (skip if already noisy)
% TODO: Comment out the next 3 lines if your image is already noisy
rng(42, 'twister');
noisy = sqrt((img + noiseStdEst/255 * randn(size(img))).^2 + ...
             (noiseStdEst/255 * randn(size(img))).^2);
noisy = min(max(noisy, 0), 1);

%% Step 2: Determine maximum decomposition level
maxLev = wmaxlev(size(noisy), waveletName);
fprintf('Maximum decomposition level for %s: %d\n', waveletName, maxLev);

% TODO: Choose decomposition level (do not exceed maxLev)
decompLevel = min(4, maxLev);

%% Step 3: Denoise with Bayes method
denoisedBayes = wdenoise2(noisy, decompLevel, ...
    'Wavelet', waveletName, ...
    'DenoisingMethod', 'Bayes', ...
    'ThresholdRule', 'Median', ...
    'NoiseEstimate', 'LevelDependent');

%% Step 4: Denoise with SURE method
denoisedSURE = wdenoise2(noisy, decompLevel, ...
    'Wavelet', waveletName, ...
    'DenoisingMethod', 'SURE', ...
    'ThresholdRule', 'Soft', ...
    'NoiseEstimate', 'LevelDependent');

%% Step 5: Compare denoising at multiple levels
levels = 2:min(5, maxLev);
psnrBayes = zeros(numel(levels), 1);
ssimBayes = zeros(numel(levels), 1);

for k = 1:numel(levels)
    lev = levels(k);
    denoised = wdenoise2(noisy, lev, ...
        'Wavelet', waveletName, ...
        'DenoisingMethod', 'Bayes', ...
        'ThresholdRule', 'Median', ...
        'NoiseEstimate', 'LevelDependent');
    psnrBayes(k) = psnr(denoised, img);
    ssimBayes(k) = ssim(denoised, img);
end

%% Step 6: Compute quality metrics
psnrNoisy    = psnr(noisy, img);
psnrBayesFinal = psnr(denoisedBayes, img);
psnrSUREFinal  = psnr(denoisedSURE, img);
ssimNoisy    = ssim(noisy, img);
ssimBayesFinal = ssim(denoisedBayes, img);
ssimSUREFinal  = ssim(denoisedSURE, img);

fprintf('\n--- Denoising Results ---\n');
fprintf('Noisy:       PSNR = %.2f dB, SSIM = %.4f\n', psnrNoisy, ssimNoisy);
fprintf('Bayes (L%d):  PSNR = %.2f dB, SSIM = %.4f\n', decompLevel, psnrBayesFinal, ssimBayesFinal);
fprintf('SURE  (L%d):  PSNR = %.2f dB, SSIM = %.4f\n', decompLevel, psnrSUREFinal, ssimSUREFinal);

%% Step 7: Visualize results
figure('Name', 'MRI Rician Denoising', 'Position', [100 100 1200 800]);

subplot(2,3,1); imshow(img, []); title('Original');
subplot(2,3,2); imshow(noisy, []); title(sprintf('Noisy (PSNR=%.1f)', psnrNoisy));
subplot(2,3,3); imshow(denoisedBayes, []); title(sprintf('Bayes (PSNR=%.1f)', psnrBayesFinal));
subplot(2,3,4); imshow(denoisedSURE, []); title(sprintf('SURE (PSNR=%.1f)', psnrSUREFinal));
subplot(2,3,5); imshow(abs(img - denoisedBayes), []); title('Residual (Bayes)');

subplot(2,3,6);
plot(levels, psnrBayes, '-o', 'LineWidth', 2);
xlabel('Decomposition Level'); ylabel('PSNR (dB)');
title('PSNR vs. Level (Bayes)'); grid on;

%% Step 8: Save results
if ~isfolder(outputDir)
    mkdir(outputDir);
end
imwrite(denoisedBayes, fullfile(outputDir, 'mri_denoised_bayes.png'));
imwrite(denoisedSURE, fullfile(outputDir, 'mri_denoised_sure.png'));
saveas(gcf, fullfile(outputDir, 'mri_denoising_comparison.png'));
fprintf('Results saved to: %s\n', outputDir);
