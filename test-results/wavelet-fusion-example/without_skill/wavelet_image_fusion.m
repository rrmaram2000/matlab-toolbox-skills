%% MRI + CT Image Fusion Using Wavelet Transform
% Fuse MRI and CT images using wavelet decomposition and fusion.
%
% MATLAB R2025b | Wavelet Toolbox | Image Processing Toolbox

%% Step 1: Load images
mriPath = '';  % Path to MRI image
ctPath  = '';  % Path to CT image
outputDir = '';

mriImg = imread(mriPath);
ctImg  = imread(ctPath);

if ndims(mriImg) == 3, mriImg = rgb2gray(mriImg); end
if ndims(ctImg) == 3,  ctImg  = rgb2gray(ctImg);  end

mriImg = double(mriImg);  % NOTE: double() gives [0,255], not [0,1]
ctImg  = double(ctImg);

if ~isequal(size(mriImg), size(ctImg))
    ctImg = imresize(ctImg, size(mriImg));
end

%% Step 2: Simple wavelet decomposition
% Use single-level dwt2 for basic fusion
[cA_mri, cH_mri, cV_mri, cD_mri] = dwt2(mriImg, 'db4');
[cA_ct,  cH_ct,  cV_ct,  cD_ct]  = dwt2(ctImg,  'db4');

%% Step 3: Fuse — simple averaging of all coefficients
% Average everything (approximation AND details)
cA_fused = (cA_mri + cA_ct) / 2;
cH_fused = (cH_mri + cH_ct) / 2;
cV_fused = (cV_mri + cV_ct) / 2;
cD_fused = (cD_mri + cD_ct) / 2;

% Reconstruct
fused = idwt2(cA_fused, cH_fused, cV_fused, cD_fused, 'db4');

%% Step 4: Try MODWT for shift-invariant fusion
% Use 2D MODWT for better fusion quality
decompLevel = 4;
[wt_mri] = modwt2(mriImg, 'sym4', decompLevel);
[wt_ct]  = modwt2(ctImg,  'sym4', decompLevel);

% Average all MODWT coefficients
wt_fused = (wt_mri + wt_ct) / 2;

% Inverse MODWT2
fused_modwt = imodwt2(wt_fused, 'sym4');

%% Step 5: Quality assessment
% Simple PSNR and SSIM
fprintf("SSIM (vs MRI): %.4f\n", ssim(fused / 255, mriImg / 255));
fprintf("SSIM (vs CT):  %.4f\n", ssim(fused / 255, ctImg / 255));

%% Step 6: Visualize
figure;
subplot(2, 2, 1); imshow(mriImg, []);    title("MRI");
subplot(2, 2, 2); imshow(ctImg, []);     title("CT");
subplot(2, 2, 3); imshow(fused, []);     title("Fused (DWT avg)");
subplot(2, 2, 4); imshow(fused_modwt, []); title("Fused (MODWT2)");
sgtitle("MRI + CT Fusion");

%% Step 7: Save
if ~isfolder(outputDir), mkdir(outputDir); end
imwrite(mat2gray(fused), fullfile(outputDir, 'fused_dwt.png'));
imwrite(mat2gray(fused_modwt), fullfile(outputDir, 'fused_modwt2.png'));
fprintf("Results saved to: %s\n", outputDir);
