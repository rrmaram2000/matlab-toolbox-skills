%% MRI + CT Image Fusion Using Wavelet-Based Multi-Resolution Analysis
% Fuse MRI and CT images using wavelet decomposition with proper
% coefficient-level fusion rules and quality assessment.
%
% MATLAB R2025b | Wavelet Toolbox | Image Processing Toolbox
%
% Workflow:
%   1. Load and align MRI and CT images
%   2. Check decomposition level limits with wmaxlev
%   3. Multi-level wavelet decomposition (wavedec2)
%   4. Fusion Rule: mean for approximation, max-absolute for details
%   5. Extract detail coefficients per level with detcoef2
%   6. Regional energy-based fusion as alternative
%   7. Reconstruct fused images
%   8. Compute quality metrics (mutual information, spatial frequency)

%% ---- USER CONFIGURATION ----
mriPath     = '';  % TODO: Path to MRI image (e.g., T1-weighted brain MRI)
ctPath      = '';  % TODO: Path to CT image (e.g., registered CT of same anatomy)
outputDir   = '';  % TODO: Path to save fused results
waveletName = 'sym8';   % Symlets for smooth medical images
decompLevel = 4;         % Desired decomposition depth

%% Step 1: Load and align images
mriImg = imread(mriPath);
ctImg  = imread(ctPath);

% Convert to grayscale if needed
if ndims(mriImg) == 3, mriImg = rgb2gray(mriImg); end
if ndims(ctImg) == 3,  ctImg  = rgb2gray(ctImg);  end

% CRITICAL: Use im2double (NOT double) to normalize to [0,1]
% double() on uint8 gives [0,255] which breaks wavelet coefficient scaling
mriImg = im2double(mriImg);
ctImg  = im2double(ctImg);

% Ensure same size (images must be co-registered)
if ~isequal(size(mriImg), size(ctImg))
    ctImg = imresize(ctImg, size(mriImg));
    fprintf('Warning: Images resized to match. Pre-registration recommended.\n');
end

fprintf('Image size: [%d x %d]\n', size(mriImg, 1), size(mriImg, 2));

%% Step 2: Check decomposition level limits
% wmaxlev computes the maximum useful decomposition level for the
% given image size and wavelet. Going beyond this produces empty coefficients.
maxLev = wmaxlev(size(mriImg), waveletName);

if decompLevel > maxLev
    fprintf('Warning: Requested level %d exceeds max %d for %s. Clamping.\n', ...
        decompLevel, maxLev, waveletName);
    decompLevel = maxLev;
end

fprintf('Wavelet: %s | Decomposition level: %d (max: %d)\n', ...
    waveletName, decompLevel, maxLev);

%% Step 3: Multi-level wavelet decomposition
% wavedec2 performs multi-level 2D discrete wavelet transform
% Returns coefficient vector C and bookkeeping matrix S
[C_mri, S_mri] = wavedec2(mriImg, decompLevel, waveletName);
[C_ct,  S_ct]  = wavedec2(ctImg,  decompLevel, waveletName);

% Length of approximation coefficients
approxLen = prod(S_mri(1,:));
fprintf('Decomposition complete: %d coefficients, approx size [%d x %d]\n', ...
    length(C_mri), S_mri(1,1), S_mri(1,2));

%% Step 4: Fusion Rule 1 — Mean Approximation + Max-Absolute Details
% Approximation (low-frequency): average captures shared anatomy
% Details (high-frequency): max-absolute preserves edges from both modalities
C_fused1 = C_mri;

% Mean fusion for approximation coefficients
C_fused1(1:approxLen) = 0.5 * C_mri(1:approxLen) + 0.5 * C_ct(1:approxLen);

% Max-absolute selection for ALL detail coefficients
for idx = (approxLen + 1):length(C_mri)
    if abs(C_ct(idx)) > abs(C_mri(idx))
        C_fused1(idx) = C_ct(idx);
    end
end

% Reconstruct fused image
fused_maxmean = waverec2(C_fused1, S_mri, waveletName);

%% Step 5: Fusion Rule 2 — Regional Energy-Based Detail Selection
% For each detail subband, compare local energy in a neighborhood
% and select coefficients from the image with higher local energy.
C_fused2 = C_mri;

% Mean fusion for approximation
C_fused2(1:approxLen) = 0.5 * C_mri(1:approxLen) + 0.5 * C_ct(1:approxLen);

% Energy-based fusion per level, per subband
kernel = ones(3) / 9;  % 3x3 averaging kernel for local energy

for lev = 1:decompLevel
    % Extract detail coefficients for each orientation at this level
    % detcoef2 returns 2D arrays for horizontal, vertical, diagonal subbands
    [cH_mri, cV_mri, cD_mri] = detcoef2('all', C_mri, S_mri, lev);
    [cH_ct,  cV_ct,  cD_ct]  = detcoef2('all', C_ct,  S_ct,  lev);

    subbands_mri = {cH_mri, cV_mri, cD_mri};
    subbands_ct  = {cH_ct,  cV_ct,  cD_ct};
    fused_subs   = cell(1, 3);

    for s = 1:3
        % Compute local energy maps
        energy_mri = conv2(subbands_mri{s}.^2, kernel, 'same');
        energy_ct  = conv2(subbands_ct{s}.^2, kernel, 'same');

        % Select coefficients from higher-energy source
        mask = energy_mri >= energy_ct;
        fused_subs{s} = subbands_mri{s} .* mask + subbands_ct{s} .* (~mask);
    end

    % Write fused detail coefficients back into the coefficient vector
    C_fused2 = setDetailCoeffs(C_fused2, S_mri, lev, ...
        fused_subs{1}, fused_subs{2}, fused_subs{3});
end

fused_energy = waverec2(C_fused2, S_mri, waveletName);

%% Step 6: Compute quality metrics
fprintf('\n=== Fusion Quality Metrics ===\n');

% Mutual Information: measures shared information between source and fused
mi_mm = mutualInfo(mriImg, fused_maxmean) + mutualInfo(ctImg, fused_maxmean);
mi_en = mutualInfo(mriImg, fused_energy)  + mutualInfo(ctImg, fused_energy);

fprintf('Total Mutual Information:\n');
fprintf('  Max-Mean:     %.4f\n', mi_mm);
fprintf('  Energy-Based: %.4f\n', mi_en);

% Spatial Frequency: measures edge/detail preservation
sf_mm = spatialFrequency(fused_maxmean);
sf_en = spatialFrequency(fused_energy);

fprintf('Spatial Frequency:\n');
fprintf('  Max-Mean:     %.4f\n', sf_mm);
fprintf('  Energy-Based: %.4f\n', sf_en);

% SSIM against both sources
ssim_mri_mm = ssim(fused_maxmean, mriImg);
ssim_ct_mm  = ssim(fused_maxmean, ctImg);
ssim_mri_en = ssim(fused_energy, mriImg);
ssim_ct_en  = ssim(fused_energy, ctImg);

fprintf('SSIM (vs MRI / vs CT):\n');
fprintf('  Max-Mean:     %.4f / %.4f\n', ssim_mri_mm, ssim_ct_mm);
fprintf('  Energy-Based: %.4f / %.4f\n', ssim_mri_en, ssim_ct_en);

%% Step 7: Visualize results
figure('Name', 'Wavelet Image Fusion', 'Position', [50 50 1400 600]);

subplot(2, 3, 1); imshow(mriImg, []); title('Source: MRI');
subplot(2, 3, 2); imshow(ctImg, []);  title('Source: CT');
subplot(2, 3, 3); imshow(fused_maxmean, []); title('Fused: Max-Mean');
subplot(2, 3, 4); imshow(fused_energy, []);  title('Fused: Energy-Based');

% Difference maps
subplot(2, 3, 5);
diffMap = abs(fused_maxmean - fused_energy);
imshow(diffMap, []); colormap(gca, 'hot'); colorbar;
title('Difference: Max-Mean vs Energy');

% Quality comparison bar chart
subplot(2, 3, 6);
bar([mi_mm, mi_en; sf_mm, sf_en]);
set(gca, 'XTickLabel', {'Total MI', 'Spatial Freq'});
legend('Max-Mean', 'Energy-Based');
ylabel('Metric Value');
title('Quality Comparison');
grid on;

sgtitle(sprintf('MRI+CT Wavelet Fusion | %s | Level %d', waveletName, decompLevel));

%% Step 8: Save results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(mat2gray(fused_maxmean), fullfile(outputDir, 'fused_maxmean.png'));
    imwrite(mat2gray(fused_energy),  fullfile(outputDir, 'fused_energy.png'));
    saveas(gcf, fullfile(outputDir, 'fusion_comparison.png'));
    fprintf('\nResults saved to: %s\n', outputDir);
end

fprintf('\n=== Wavelet Image Fusion Complete ===\n');

%% ==================== Local Functions ====================

function mi = mutualInfo(A, B)
    % Compute mutual information between two grayscale images
    A = im2uint8(mat2gray(A));
    B = im2uint8(mat2gray(B));
    jh = accumarray([A(:)+1, B(:)+1], 1, [256, 256]);
    jp = jh / sum(jh(:));
    mA = sum(jp, 2);
    mB = sum(jp, 1);
    ip = mA * mB;
    mask = jp > 0 & ip > 0;
    mi = sum(jp(mask) .* log2(jp(mask) ./ ip(mask)));
end

function sf = spatialFrequency(img)
    % Compute spatial frequency (edge/detail measure)
    rf = diff(img, 1, 2);
    cf = diff(img, 1, 1);
    sf = sqrt(mean(rf(:).^2) + mean(cf(:).^2));
end

function C = setDetailCoeffs(C, S, lev, cH, cV, cD)
    % Write detail coefficients back into wavedec2 coefficient vector C
    N = size(S, 1) - 2;  % Number of decomposition levels
    first = prod(S(1,:));
    for k = N:-1:(lev+1)
        first = first + 3 * prod(S(N+2-k,:));
    end
    first = first + 1;
    len = prod(S(N+2-lev,:));
    C(first : first+len-1)       = cH(:);
    C(first+len : first+2*len-1) = cV(:);
    C(first+2*len : first+3*len-1) = cD(:);
end
