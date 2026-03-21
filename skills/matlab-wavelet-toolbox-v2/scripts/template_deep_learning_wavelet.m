%% Template: Differentiable DWT in Deep Learning Networks
% Use dldwt (returns [A, D] only — 2 outputs, NOT 4!) and dlidwt for
% wavelet-augmented neural network layers in biomedical image analysis.
% MATLAB R2025b | Wavelet Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Wavelet Toolbox
%   - Deep Learning Toolbox

%% TODO: Configure your data paths and parameters
dataDir     = '';  % TODO: Path to training images (e.g., './train/')
outputDir   = '';  % TODO: Path to save results
waveletName = 'sym4';
inputSize   = [128, 128, 1];  % TODO: [H, W, C]

%% Step 1: Demonstrate dldwt usage (critical API — 2 outputs only!)
% A = approximation, D = detail (H/V/D concatenated along channel dim)
testImg = dlarray(randn(64, 64, 1, 1), 'SSCB');
[A, D] = dldwt(testImg, waveletName);
fprintf('dldwt outputs:\n');
fprintf('  Approximation (A): %s\n', mat2str(size(A)));
fprintf('  Detail (D):        %s\n', mat2str(size(D)));

% Inverse DWT — reconstruct from A and D
reconstructed = dlidwt(A, D, waveletName, 'OutputSize', size(testImg, 1:2));
reconErr = max(abs(extractdata(testImg - reconstructed)), [], 'all');
fprintf('  Reconstruction error: %.2e\n', reconErr);

%% Step 2: Wavelet feature extraction function for networks
function [features, A, D] = waveletFeatureLayer(X, wname)
    % X: dlarray [H,W,C,B] 'SSCB'. Returns concatenated wavelet features.
    [A, D] = dldwt(X, wname);  % 2 outputs only!
    features = cat(3, A, D);   % Merge along channel dimension
end

%% Step 3: Build wavelet-augmented classification network
layers = [
    imageInputLayer(inputSize, 'Name', 'input', 'Normalization', 'none')
    convolution2dLayer(3, 16, 'Padding', 'same', 'Name', 'conv1')
    batchNormalizationLayer('Name', 'bn1')
    reluLayer('Name', 'relu1')
    convolution2dLayer(3, 32, 'Padding', 'same', 'Name', 'conv2')
    batchNormalizationLayer('Name', 'bn2')
    reluLayer('Name', 'relu2')
    maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')
    convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'conv3')
    batchNormalizationLayer('Name', 'bn3')
    reluLayer('Name', 'relu3')
    globalAveragePooling2dLayer('Name', 'gap')
    ];
net = dlnetwork(layers);

%% Step 4: Custom training loop with wavelet augmentation
% TODO: Load dataset, uncomment, and adapt
% ds = imageDatastore(dataDir, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');

function [loss, gradients, state] = modelGradients(net, X, Y, wname)
    [A, D] = dldwt(X, wname);  % 2 outputs only!
    A_resized = dlresize(A, 'OutputSize', size(X, 1:2));
    Xaug = cat(3, X, A_resized);
    [Ypred, state] = forward(net, X, 'Outputs', 'gap');
    loss = crossentropy(softmax(Ypred), Y);
end

%% Step 5: Multi-scale wavelet feature pyramid
function featurePyramid = waveletPyramid(X, wname, numLevels)
    featurePyramid = cell(numLevels, 1);
    currentInput = X;
    for lev = 1:numLevels
        [A, D] = dldwt(currentInput, wname);  % 2 outputs only!
        featurePyramid{lev} = D;
        currentInput = A;
    end
end

%% Step 6: Wavelet perceptual loss function
function wloss = waveletLoss(predicted, target, wname)
    [A_pred, D_pred] = dldwt(predicted, wname);
    [A_tgt, D_tgt]   = dldwt(target, wname);
    lossA = mean(abs(A_pred - A_tgt), 'all');
    lossD = mean(abs(D_pred - D_tgt), 'all');
    wloss = lossA + 2.0 * lossD;  % Weight details for edge preservation
end

%% Step 7: Demonstrate wavelet pyramid
sampleImg = dlarray(randn(inputSize(1), inputSize(2), 1, 4), 'SSCB');
pyramid = waveletPyramid(sampleImg, waveletName, 3);
fprintf('\n--- Wavelet Feature Pyramid ---\n');
for lev = 1:3
    fprintf('Level %d detail size: %s\n', lev, mat2str(size(pyramid{lev})));
end

%% Step 8: Visualize dldwt decomposition
testVis = dlarray(randn(64, 64, 1, 1), 'SSCB');
[Avis, Dvis] = dldwt(testVis, waveletName);
figure('Name', 'Differentiable DWT', 'Position', [100 100 1000 350]);
subplot(1,3,1); imagesc(extractdata(squeeze(testVis))); colorbar; title('Input'); axis image;
subplot(1,3,2); imagesc(extractdata(squeeze(Avis))); colorbar; title('Approx (A)'); axis image;
subplot(1,3,3); imagesc(extractdata(squeeze(Dvis(:,:,1,1)))); colorbar; title('Detail (D ch1)'); axis image;

%% Step 9: Save
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'wavelet_network.mat'), 'net', 'waveletName', 'inputSize');
saveas(gcf, fullfile(outputDir, 'dwt_visualization.png'));
fprintf('Results saved to: %s\n', outputDir);
