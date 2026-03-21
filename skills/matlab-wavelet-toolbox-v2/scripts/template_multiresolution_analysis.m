%% Template: Multi-Resolution Wavelet Decomposition and Analysis
% Multi-level decomposition using wavedec2 with wmaxlev validation. Extract
% approximation/detail coefficients, visualize decomposition tree, analyze
% energy distribution across scales for biomedical images.
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
inputPath   = '';  % TODO: Path to medical image (e.g., 'xray_chest.png')
outputDir   = '';  % TODO: Path to save results
waveletName = 'sym8';

%% Step 1: Load image
img = imread(inputPath);
if ndims(img) == 3, img = rgb2gray(img); end
img = im2double(img);
[rows, cols] = size(img);

%% Step 2: Determine maximum decomposition level (ALWAYS check first!)
maxLev = wmaxlev(size(img), waveletName);
decompLevel = min(5, maxLev);  % TODO: Adjust (must not exceed maxLev)
fprintf('Using level %d (max: %d) for %s\n', decompLevel, maxLev, waveletName);

%% Step 3: Multi-level wavelet decomposition
[C, S] = wavedec2(img, decompLevel, waveletName);

%% Step 4: Extract approximation and detail coefficients
approxCoeffs = cell(decompLevel, 1);
detailH = cell(decompLevel, 1);
detailV = cell(decompLevel, 1);
detailD = cell(decompLevel, 1);
for lev = 1:decompLevel
    approxCoeffs{lev} = appcoef2(C, S, waveletName, lev);
    detailH{lev} = detcoef2('h', C, S, lev);
    detailV{lev} = detcoef2('v', C, S, lev);
    detailD{lev} = detcoef2('d', C, S, lev);
end

%% Step 5: Energy distribution across scales
totalEnergy = sum(C.^2);
approxEnergy = zeros(decompLevel, 1);
detailEnergy = zeros(decompLevel, 3);
for lev = 1:decompLevel
    approxEnergy(lev) = sum(approxCoeffs{lev}(:).^2);
    detailEnergy(lev,:) = [sum(detailH{lev}(:).^2), ...
        sum(detailV{lev}(:).^2), sum(detailD{lev}(:).^2)];
end
approxPct = approxEnergy / totalEnergy * 100;
detailPct = detailEnergy / totalEnergy * 100;

fprintf('\n%-6s %8s %8s %8s %8s\n', 'Level', 'Approx%', 'Horiz%', 'Vert%', 'Diag%');
for lev = 1:decompLevel
    fprintf('L%-5d %7.2f%% %7.2f%% %7.2f%% %7.2f%%\n', lev, ...
        approxPct(lev), detailPct(lev,1), detailPct(lev,2), detailPct(lev,3));
end

%% Step 6: Subband statistics
fprintf('\n%-10s %8s %8s %8s %8s\n', 'Subband', 'Mean', 'Std', 'Skew', 'Kurt');
for lev = 1:decompLevel
    sbs = {detailH{lev}, detailV{lev}, detailD{lev}};
    names = {sprintf('L%d_H',lev), sprintf('L%d_V',lev), sprintf('L%d_D',lev)};
    for s = 1:3
        d = sbs{s}(:);
        fprintf('%-10s %8.4f %8.4f %8.4f %8.4f\n', names{s}, ...
            mean(d), std(d), skewness(d), kurtosis(d));
    end
end

%% Step 7: Visualize decomposition tree
figure('Name', 'Decomposition Tree', 'Position', [50 50 1400 800]);
subplot(3, decompLevel+1, 1); imshow(img, []); title('Original');
for lev = 1:decompLevel
    subplot(3, decompLevel+1, lev+1); imshow(approxCoeffs{lev}, []);
    title(sprintf('A L%d', lev));
    subplot(3, decompLevel+1, decompLevel+1+lev); imshow(detailH{lev}, []);
    title(sprintf('H L%d', lev));
    subplot(3, decompLevel+1, 2*(decompLevel+1)+lev); imshow(detailD{lev}, []);
    title(sprintf('D L%d', lev));
end

%% Step 8: Energy distribution plot and wavelet comparison
figure('Name', 'Energy Analysis', 'Position', [100 100 900 400]);
subplot(1,2,1);
bar(1:decompLevel, [detailPct, approxPct], 'stacked');
xlabel('Level'); ylabel('Energy (%)');
legend('H','V','D','Approx', 'Location', 'northwest'); grid on;
title('Energy Distribution');

wavelets = {'haar', 'db4', 'sym8', 'coif3', 'bior3.5'};
wEnergy = zeros(numel(wavelets), 1);
for w = 1:numel(wavelets)
    ml = wmaxlev(size(img), wavelets{w});
    lv = min(decompLevel, ml);
    [Cw, Sw] = wavedec2(img, lv, wavelets{w});
    cA = appcoef2(Cw, Sw, wavelets{w}, lv);
    wEnergy(w) = sum(cA(:).^2) / sum(Cw.^2) * 100;
end
subplot(1,2,2); bar(wEnergy);
set(gca, 'XTickLabel', wavelets); ylabel('Approx Energy (%)');
title('Wavelet Comparison'); grid on;

%% Step 9: Save results
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'multiresolution_data.mat'), 'C', 'S', ...
    'approxCoeffs', 'detailH', 'detailV', 'detailD', 'approxPct', 'detailPct');
saveas(gcf, fullfile(outputDir, 'energy_distribution.png'));
fprintf('Results saved to: %s\n', outputDir);
