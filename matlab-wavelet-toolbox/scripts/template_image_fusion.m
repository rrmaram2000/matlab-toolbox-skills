%% Template: Multi-Modal Medical Image Fusion Using Wavelets
% Fuse two medical images (e.g., PET/CT or multi-sequence MRI) using wavelet
% decomposition with coefficient fusion rules and quality assessment.
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
inputPath1  = '';  % TODO: Path to first image (e.g., CT or T1-MRI)
inputPath2  = '';  % TODO: Path to second image (e.g., PET or T2-MRI)
outputDir   = '';  % TODO: Path to save fused results
waveletName = 'sym8';
decompLevel = 4;   % TODO: Decomposition depth

%% Step 1: Load and align images
img1 = imread(inputPath1); img2 = imread(inputPath2);
if ndims(img1) == 3, img1 = rgb2gray(img1); end
if ndims(img2) == 3, img2 = rgb2gray(img2); end
img1 = im2double(img1); img2 = im2double(img2);
if ~isequal(size(img1), size(img2))
    img2 = imresize(img2, size(img1));
end

%% Step 2: Wavelet decomposition
maxLev = wmaxlev(size(img1), waveletName);
decompLevel = min(decompLevel, maxLev);
[C1, S1] = wavedec2(img1, decompLevel, waveletName);
[C2, S2] = wavedec2(img2, decompLevel, waveletName);
approxLen = prod(S1(1,:));

%% Step 3: Fusion Rule 1 — Max-Abs detail + Mean approximation
Cf1 = C1;
Cf1(1:approxLen) = 0.5 * C1(1:approxLen) + 0.5 * C2(1:approxLen);
for idx = (approxLen+1):length(C1)
    if abs(C2(idx)) > abs(C1(idx)), Cf1(idx) = C2(idx); end
end
fused_maxmean = waverec2(Cf1, S1, waveletName);

%% Step 4: Fusion Rule 2 — Regional energy-based selection
Cf2 = C1;
Cf2(1:approxLen) = 0.5 * C1(1:approxLen) + 0.5 * C2(1:approxLen);
kernel = ones(3) / 9;
for lev = 1:decompLevel
    [cH1, cV1, cD1] = detcoef2('all', C1, S1, lev);
    [cH2, cV2, cD2] = detcoef2('all', C2, S2, lev);
    sb1 = {cH1, cV1, cD1}; sb2 = {cH2, cV2, cD2}; fused = cell(1,3);
    for s = 1:3
        e1 = conv2(sb1{s}.^2, kernel, 'same');
        e2 = conv2(sb2{s}.^2, kernel, 'same');
        mask = e1 >= e2;
        fused{s} = sb1{s} .* mask + sb2{s} .* (~mask);
    end
    Cf2 = detcoef2('compact', Cf2, S1, lev, fused{1}, fused{2}, fused{3});
end
fused_energy = waverec2(Cf2, S1, waveletName);

%% Step 5: Fusion Rule 3 — Salience-weighted pixel fusion
[Gx1, Gy1] = imgradientxy(img1); sal1 = sqrt(Gx1.^2 + Gy1.^2);
[Gx2, Gy2] = imgradientxy(img2); sal2 = sqrt(Gx2.^2 + Gy2.^2);
w1 = sal1 ./ (sal1 + sal2 + eps);
fused_salience = w1 .* img1 + (1 - w1) .* img2;

%% Step 6: Quality metrics (mutual information + spatial frequency)
mi = @(A,B) mutualInfo(A,B);  % Local function defined below
miTotal = [mi(img1,fused_maxmean)+mi(img2,fused_maxmean), ...
           mi(img1,fused_energy)+mi(img2,fused_energy), ...
           mi(img1,fused_salience)+mi(img2,fused_salience)];
fprintf('\n--- Total Mutual Information ---\n');
fprintf('Max-Mean: %.4f | Energy: %.4f | Salience: %.4f\n', miTotal);
sfVals = [spatialFrequency(fused_maxmean), spatialFrequency(fused_energy), ...
           spatialFrequency(fused_salience)];
fprintf('Spatial Frequency: %.4f | %.4f | %.4f\n', sfVals);

%% Step 7: Visualize
figure('Name', 'Image Fusion', 'Position', [50 50 1200 600]);
subplot(2,3,1); imshow(img1, []);          title('Source 1');
subplot(2,3,2); imshow(img2, []);          title('Source 2');
subplot(2,3,3); imshow(fused_maxmean, []); title('Max-Mean');
subplot(2,3,4); imshow(fused_energy, []);  title('Energy-Based');
subplot(2,3,5); imshow(fused_salience, []); title('Salience');
subplot(2,3,6); bar(miTotal);
set(gca, 'XTickLabel', {'MaxMean','Energy','Salience'});
ylabel('Total MI'); title('Quality'); grid on;

%% Step 8: Save results
if ~isfolder(outputDir), mkdir(outputDir); end
imwrite(mat2gray(fused_maxmean), fullfile(outputDir, 'fused_maxmean.png'));
imwrite(mat2gray(fused_energy), fullfile(outputDir, 'fused_energy.png'));
imwrite(mat2gray(fused_salience), fullfile(outputDir, 'fused_salience.png'));
saveas(gcf, fullfile(outputDir, 'fusion_comparison.png'));
fprintf('Results saved to: %s\n', outputDir);

%% Local Functions
function mi = mutualInfo(A, B)
    A = im2uint8(mat2gray(A)); B = im2uint8(mat2gray(B));
    jh = accumarray([A(:)+1, B(:)+1], 1, [256,256]);
    jp = jh / sum(jh(:)); mA = sum(jp,2); mB = sum(jp,1);
    ip = mA * mB; mask = jp > 0 & ip > 0;
    mi = sum(jp(mask) .* log2(jp(mask) ./ ip(mask)));
end

function sf = spatialFrequency(img)
    rf = diff(img,1,2); cf = diff(img,1,1);
    sf = sqrt(mean(rf(:).^2) + mean(cf(:).^2));
end
