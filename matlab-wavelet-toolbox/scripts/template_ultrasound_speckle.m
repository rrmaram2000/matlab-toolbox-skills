%% Template: Ultrasound Speckle Reduction via Wavelet Denoising
% Reduce multiplicative speckle noise in ultrasound images using log-domain
% wavelet denoising. Compare wdenoise2 with custom coefficient thresholding.
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
inputPath  = '';  % TODO: Path to ultrasound image (e.g., 'us_liver.png')
outputDir  = '';  % TODO: Path to save results
waveletName = 'sym8';
boundaryMode = 'symmetric';
decompLevel = 4;  % TODO: Adjust decomposition depth

%% Step 1: Load ultrasound image
img = imread(inputPath);
if ndims(img) == 3
    img = rgb2gray(img);
end
img = im2double(img);

% Simulate speckle if needed (comment out for real US data)
% TODO: Remove simulation block if using actual ultrasound data
rng(42, 'twister');
speckleVar = 0.04;  % TODO: Speckle variance
noisy = imnoise(img, 'speckle', speckleVar);

%% Step 2: Log-compress for homomorphic filtering
% Speckle is multiplicative: observed = clean * noise
% In log domain: log(observed) = log(clean) + log(noise) -> additive
epsilon = 1e-10;  % Avoid log(0)
logImg = log(noisy + epsilon);

%% Step 3: Check decomposition level
maxLev = wmaxlev(size(logImg), waveletName);
decompLevel = min(decompLevel, maxLev);
fprintf('Using decomposition level: %d (max: %d)\n', decompLevel, maxLev);

%% Step 4: Method 1 — wdenoise2 in log domain
logDenoised = wdenoise2(logImg, decompLevel, ...
    'Wavelet', waveletName, ...
    'DenoisingMethod', 'Bayes', ...
    'ThresholdRule', 'Median', ...
    'NoiseEstimate', 'LevelDependent');
denoised_wdenoise = exp(logDenoised);
denoised_wdenoise = min(max(denoised_wdenoise, 0), 1);

%% Step 5: Method 2 — Custom coefficient thresholding (BayesShrink-style)
[C, S] = wavedec2(logImg, decompLevel, waveletName);

% Estimate noise sigma from finest diagonal detail
[~, ~, cD1] = detcoef2('all', C, S, 1);
sigmaNoiseLog = median(abs(cD1(:))) / 0.6745;

Cmod = C;
for lev = 1:decompLevel
    [cH, cV, cD] = detcoef2('all', C, S, lev);
    subbands = {cH, cV, cD};
    thresholded = cell(1, 3);
    for sb = 1:3
        coeffs = subbands{sb};
        % BayesShrink: sigma_signal^2 = max(sigma_coeff^2 - sigma_noise^2, 0)
        sigmaCoeff = std(coeffs(:));
        sigmaSig = sqrt(max(sigmaCoeff^2 - sigmaNoiseLog^2, 0));
        if sigmaSig > 0
            thr = sigmaNoiseLog^2 / sigmaSig;
        else
            thr = max(abs(coeffs(:)));  % Kill all coefficients
        end
        % Soft thresholding
        thresholded{sb} = sign(coeffs) .* max(abs(coeffs) - thr, 0);
    end
    Cmod = setDetailCoeffs(Cmod, S, lev, thresholded{1}, thresholded{2}, thresholded{3});
end
logDenoisedCustom = waverec2(Cmod, S, waveletName);
denoised_custom = exp(logDenoisedCustom);
denoised_custom = min(max(denoised_custom, 0), 1);

%% Step 6: Tissue boundary preservation analysis
% Compute gradient magnitude as boundary proxy
[Gx, Gy] = imgradientxy(img, 'sobel');
gradOrig = sqrt(Gx.^2 + Gy.^2);
[Gx, Gy] = imgradientxy(denoised_wdenoise, 'sobel');
gradWden = sqrt(Gx.^2 + Gy.^2);
[Gx, Gy] = imgradientxy(denoised_custom, 'sobel');
gradCust = sqrt(Gx.^2 + Gy.^2);

% Boundary correlation (higher = better preservation)
bcWden = corr2(gradOrig, gradWden);
bcCust = corr2(gradOrig, gradCust);
fprintf('\n--- Boundary Preservation ---\n');
fprintf('wdenoise2 (Bayes): Gradient correlation = %.4f\n', bcWden);
fprintf('Custom BayesShrink: Gradient correlation = %.4f\n', bcCust);

%% Step 7: Quantitative metrics
fprintf('\nwdenoise2: PSNR=%.2f dB, SSIM=%.4f\n', psnr(denoised_wdenoise, img), ssim(denoised_wdenoise, img));
fprintf('Custom:    PSNR=%.2f dB, SSIM=%.4f\n', psnr(denoised_custom, img), ssim(denoised_custom, img));

%% Step 8: Visualize results
figure('Name', 'Ultrasound Speckle Reduction', 'Position', [100 100 1200 800]);

subplot(2,3,1); imshow(img, []); title('Original');
subplot(2,3,2); imshow(noisy, []); title('With Speckle');
subplot(2,3,3); imshow(denoised_wdenoise, []); title(sprintf('wdenoise2 (BC=%.3f)', bcWden));
subplot(2,3,4); imshow(denoised_custom, []); title(sprintf('Custom (BC=%.3f)', bcCust));
subplot(2,3,5); imshow(abs(img - denoised_wdenoise), []); title('Residual (wdenoise2)');
subplot(2,3,6); imshow(abs(img - denoised_custom), []); title('Residual (Custom)');

%% Step 9: Save results
if ~isfolder(outputDir), mkdir(outputDir); end
imwrite(denoised_wdenoise, fullfile(outputDir, 'us_denoised_wdenoise.png'));
imwrite(denoised_custom, fullfile(outputDir, 'us_denoised_custom.png'));
saveas(gcf, fullfile(outputDir, 'us_speckle_comparison.png'));
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
