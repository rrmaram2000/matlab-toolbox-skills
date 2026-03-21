%% Template: Export Trained dlnetwork to ONNX Format
% Export a trained MATLAB deep learning model to ONNX for cross-platform
% deployment (e.g., ONNX Runtime, TensorRT, clinical software integration).
% MATLAB R2025b | Deep Learning Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Deep Learning Toolbox
%   - Deep Learning Toolbox Converter for ONNX Model Format

%% TODO: Configure your paths and parameters
modelPath  = '';   % TODO: Path to your trained .mat file containing dlnetwork
outputDir  = '';   % TODO: Directory to save ONNX file
modelName  = 'medical_classifier';  % TODO: Base name for exported file
inputSize  = [224 224 3];           % TODO: Must match your network input size
opsetVersion = 13;                  % TODO: ONNX opset version (9-17 supported)

%% Step 1: Load trained model
% The model must be a dlnetwork (R2025b standard)
data = load(modelPath);
fieldNames = fieldnames(data);
net = data.(fieldNames{1});

assert(isa(net, 'dlnetwork'), ...
    'Model must be a dlnetwork. Convert legacy networks with dag2dlnetwork().');
fprintf('Loaded dlnetwork with %d layers.\n', numel(net.Layers));

%% Step 2: Verify model with a test forward pass
testInput = dlarray(randn(inputSize, 'single'), 'SSCB');
try
    testOutput = predict(net, testInput);
    outputSize = size(testOutput);
    fprintf('Forward pass OK — Input: [%s] -> Output: [%s]\n', ...
        num2str(inputSize), num2str(outputSize));
catch ME
    error('Forward pass failed: %s\nFix model before export.', ME.message);
end

%% Step 3: Export to ONNX
if ~isfolder(outputDir), mkdir(outputDir); end
onnxFile = fullfile(outputDir, [modelName '.onnx']);

exportONNXNetwork(net, onnxFile, OpsetVersion=opsetVersion);
fprintf('Exported to: %s\n', onnxFile);

% Check file size
fileInfo = dir(onnxFile);
fprintf('ONNX file size: %.2f MB\n', fileInfo.bytes / 1e6);

%% Step 4: Verify by reimporting the ONNX model
reimportedNet = importONNXNetwork(onnxFile, InputDataFormats="BCSS", ...
    TargetNetwork="dlnetwork");
fprintf('Reimported ONNX model: %d layers.\n', numel(reimportedNet.Layers));

%% Step 5: Compare outputs between original and reimported
testInput2 = dlarray(randn(inputSize, 'single'), 'SSCB');

origOutput   = predict(net, testInput2);
reimpOutput  = predict(reimportedNet, testInput2);

maxDiff = max(abs(extractdata(origOutput) - extractdata(reimpOutput)), [], 'all');
fprintf('Max output difference (original vs reimported): %.2e\n', maxDiff);

if maxDiff < 1e-4
    fprintf('PASS: Outputs match within tolerance.\n');
else
    warning('Outputs differ significantly. Inspect layer-by-layer.');
end

%% Step 6: Export metadata summary
metadataFile = fullfile(outputDir, [modelName '_metadata.txt']);
fid = fopen(metadataFile, 'w');
fprintf(fid, 'Model Export Summary\n');
fprintf(fid, '====================\n');
fprintf(fid, 'Model Name:     %s\n', modelName);
fprintf(fid, 'Export Date:     %s\n', datetime("now"));
fprintf(fid, 'MATLAB Version:  %s\n', version);
fprintf(fid, 'ONNX Opset:      %d\n', opsetVersion);
fprintf(fid, 'Input Size:      [%s]\n', num2str(inputSize));
fprintf(fid, 'Output Size:     [%s]\n', num2str(outputSize));
fprintf(fid, 'Num Layers:      %d\n', numel(net.Layers));
fprintf(fid, 'File Size (MB):  %.2f\n', fileInfo.bytes / 1e6);
fprintf(fid, 'Max Diff Check:  %.2e\n', maxDiff);
fprintf(fid, '\nLayer Summary:\n');
for i = 1:numel(net.Layers)
    fprintf(fid, '  %3d. %-40s  %s\n', i, net.Layers(i).Name, class(net.Layers(i)));
end
fclose(fid);
fprintf('Metadata written to: %s\n', metadataFile);

%% Step 7: Deployment notes
fprintf('\n=== Deployment Checklist ===\n');
fprintf('1. Validate ONNX with: python -m onnx.checker %s\n', onnxFile);
fprintf('2. Test with ONNX Runtime: onnxruntime.InferenceSession(''%s'')\n', ...
    [modelName '.onnx']);
fprintf('3. Input preprocessing must match MATLAB training pipeline:\n');
fprintf('   - Normalization range, channel order (RGB vs BGR)\n');
fprintf('   - Resize to [%s]\n', num2str(inputSize(1:2)));
fprintf('4. Output postprocessing: softmax, argmax, thresholding as needed\n');
fprintf('============================\n');
