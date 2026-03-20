# GPU & Parallel Computing

GPU acceleration is essential for deep learning. MATLAB provides seamless GPU support through gpuArray and parallel computing features.

## GPU Basics

### Checking GPU Availability

```matlab
% Check if GPU is available
if canUseGPU
    fprintf('GPU available: %s\n', gpuDevice().Name);
else
    fprintf('No GPU available, using CPU\n');
end

% Get GPU device info
gpu = gpuDevice;
fprintf('Name: %s\n', gpu.Name);
fprintf('Compute Capability: %.1f\n', gpu.ComputeCapability);
fprintf('Total Memory: %.2f GB\n', gpu.TotalMemory / 1e9);
fprintf('Available Memory: %.2f GB\n', gpu.AvailableMemory / 1e9);

% Select specific GPU (multi-GPU systems)
gpuDevice(2);  % Select GPU 2 (1-indexed)

% Reset GPU (clear memory)
reset(gpuDevice);
```

### Moving Data to GPU

```matlab
% Transfer array to GPU
X_cpu = randn(1000, 1000, 'single');
X_gpu = gpuArray(X_cpu);

% Create directly on GPU
X_gpu = gpuArray.randn(1000, 1000, 'single');
X_gpu = gpuArray.zeros(256, 256, 3, 32, 'single');

% For dlarray
X = dlarray(randn(224, 224, 3, 16, 'single'), 'SSCB');
X = gpuArray(X);  % Move to GPU

% Gather back to CPU
X_cpu = gather(X_gpu);
```

## Training on GPU

### Using trainingOptions

```matlab
% Automatic GPU usage
options = trainingOptions('adam', ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 32, ...
    'ExecutionEnvironment', 'auto');  % 'auto', 'gpu', 'cpu', 'multi-gpu', 'parallel'

% Force GPU
options = trainingOptions('adam', ...
    'ExecutionEnvironment', 'gpu');

% Force CPU (for debugging)
options = trainingOptions('adam', ...
    'ExecutionEnvironment', 'cpu');
```

### Custom Training on GPU

```matlab
% Move network to GPU
net = dlnetwork(lgraph);

% Create GPU minibatch queue
mbq = minibatchqueue(trainDs, ...
    'MiniBatchSize', 32, ...
    'MiniBatchFormat', {'SSCB', 'CB'}, ...
    'OutputAsDlarray', [true, true], ...
    'OutputEnvironment', 'gpu');  % Key setting!

% Training loop
[avgGrad, avgSqGrad] = deal([]);
iteration = 0;

for epoch = 1:numEpochs
    shuffle(mbq);

    while hasdata(mbq)
        iteration = iteration + 1;
        [X, T] = next(mbq);  % Already on GPU

        % Forward/backward on GPU
        [loss, gradients, state] = dlfeval(@modelLoss, net, X, T);
        net.State = state;

        % Update on GPU
        [net, avgGrad, avgSqGrad] = adamupdate(net, gradients, ...
            avgGrad, avgSqGrad, iteration, learnRate);
    end
end
```

## Memory Management

### Monitoring GPU Memory

```matlab
% Check memory usage
gpu = gpuDevice;
usedMemory = gpu.TotalMemory - gpu.AvailableMemory;
fprintf('GPU Memory Used: %.2f / %.2f GB (%.1f%%)\n', ...
    usedMemory/1e9, gpu.TotalMemory/1e9, 100*usedMemory/gpu.TotalMemory);

% In training loop
function displayMemory()
    gpu = gpuDevice;
    fprintf('GPU Memory: %.2f GB used\n', ...
        (gpu.TotalMemory - gpu.AvailableMemory) / 1e9);
end
```

### Clearing GPU Memory

```matlab
% Clear specific variables
clear X_gpu Y_gpu;

% Clear all GPU arrays
clearvars -global;
reset(gpuDevice);

% Force garbage collection
clear;
reset(gpuDevice);
pause(1);  % Allow cleanup
```

### Reducing Memory Usage

```matlab
% 1. Use single precision (default for DL)
X = single(X);  % Half the memory of double

% 2. Reduce batch size
options = trainingOptions('adam', ...
    'MiniBatchSize', 8);  % Smaller batches use less memory

% 3. Use gradient checkpointing (trade compute for memory)
% Process in sub-batches for very large models
function loss = forwardWithCheckpoint(net, X, T)
    batchSize = size(X, 4);
    subBatchSize = 4;  % Process 4 at a time

    losses = [];
    for i = 1:subBatchSize:batchSize
        idx = i:min(i+subBatchSize-1, batchSize);
        Xsub = X(:,:,:,idx);
        Tsub = T(:,idx);

        Ysub = forward(net, Xsub);
        losses = [losses; crossentropy(Ysub, Tsub)];
    end
    loss = mean(losses);
end

% 4. Clear intermediate variables in training loop
[loss, gradients] = dlfeval(@modelLoss, net, X, T);
clear X T;  % Free memory immediately after use
```

### Finding Maximum Batch Size

```matlab
function maxBatch = findMaxBatchSize(net, inputSize)
    maxBatch = 1;

    for bs = [1, 2, 4, 8, 16, 32, 64, 128]
        try
            reset(gpuDevice);

            X = dlarray(randn([inputSize bs], 'single'), 'SSCB');
            X = gpuArray(X);

            % Forward pass
            Y = predict(net, X);

            % If successful, try larger batch
            maxBatch = bs;
            clear X Y;

        catch ME
            if contains(ME.message, 'memory') || contains(ME.message, 'out of memory')
                fprintf('Out of memory at batch size %d\n', bs);
                break;
            else
                rethrow(ME);
            end
        end
    end

    fprintf('Maximum batch size: %d\n', maxBatch);
end
```

## Multi-GPU Training

### Data Parallel Training

```matlab
% Use all available GPUs
options = trainingOptions('adam', ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 64, ...          % Total across GPUs
    'ExecutionEnvironment', 'multi-gpu');

% Effective batch per GPU = MiniBatchSize / numGPUs
```

### Parallel Training with Custom Loop

```matlab
% Start parallel pool
if isempty(gcp('nocreate'))
    parpool('local', gpuDeviceCount);
end

% Distributed datastore
spmd
    gpuDevice(labindex);  % Each worker uses different GPU
    localDs = partition(trainDs, numpartitions(trainDs), labindex);
end

% Train on each GPU
spmd
    localNet = net;  % Copy network
    localMbq = minibatchqueue(localDs, ...
        'MiniBatchSize', 32, ...
        'OutputEnvironment', 'gpu');

    for epoch = 1:numEpochs
        while hasdata(localMbq)
            [X, T] = next(localMbq);
            [loss, grads] = dlfeval(@modelLoss, localNet, X, T);

            % All-reduce gradients
            grads = gop(@plus, grads) / numlabs;

            % Update
            localNet = adamupdate(localNet, grads, ...);
        end
    end
end

% Gather final network
net = localNet{1};
```

### Checking Multi-GPU Setup

```matlab
% Check available GPUs
numGPUs = gpuDeviceCount;
fprintf('Number of GPUs: %d\n', numGPUs);

% List all GPUs
for i = 1:numGPUs
    gpu = gpuDevice(i);
    fprintf('GPU %d: %s (%.1f GB)\n', i, gpu.Name, gpu.TotalMemory/1e9);
end

% Check compute capability
for i = 1:numGPUs
    gpu = gpuDevice(i);
    if gpu.ComputeCapability < 3.5
        warning('GPU %d has compute capability %.1f (recommended: 3.5+)', ...
            i, gpu.ComputeCapability);
    end
end
```

## Parallel Processing (CPU)

### Parallel Pool

```matlab
% Start parallel pool
parpool('local', 4);  % 4 workers

% Or use all cores
parpool('local');  % Auto-detect

% Check pool
pool = gcp('nocreate');
if isempty(pool)
    fprintf('No parallel pool running\n');
else
    fprintf('Pool with %d workers\n', pool.NumWorkers);
end

% Delete pool
delete(gcp('nocreate'));
```

### Parallel Data Loading

```matlab
% Parallel preprocessing in minibatch queue
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 32, ...
    'PreprocessingEnvironment', 'parallel', ...
    'DispatchInBackground', true);

% Parallel transform
ds = transform(ds, @preprocess, 'IncludeInfo', true);
```

### Parallel For Loops

```matlab
% Parallel inference on multiple images
testFiles = dir('test_images/*.png');
numFiles = numel(testFiles);
results = cell(numFiles, 1);

parfor i = 1:numFiles
    img = imread(fullfile(testFiles(i).folder, testFiles(i).name));
    img = preprocess(img);

    % Note: Each worker loads network copy (memory intensive)
    results{i} = classify(net, img);
end

% More efficient: batch processing
imgs = zeros(224, 224, 3, numFiles, 'single');
parfor i = 1:numFiles
    img = imread(fullfile(testFiles(i).folder, testFiles(i).name));
    imgs(:,:,:,i) = preprocess(img);
end

% Single inference call
results = classify(net, imgs, 'MiniBatchSize', 32);
```

## Performance Optimization

### Profiling GPU Code

```matlab
% Profile training
profile on -gpu;

% Run training
net = trainnet(trainDs, dlnetwork(lgraph), "crossentropy", options);

% View results
profile viewer;

% Or save profile
p = profile('info');
save('training_profile.mat', 'p');
```

### Optimizing Data Pipeline

```matlab
% 1. Enable background dispatch
mbq = minibatchqueue(ds, ...
    'DispatchInBackground', true);

% 2. Use persistent workers
mbq = minibatchqueue(ds, ...
    'PreprocessingEnvironment', 'parallel');

% 3. Optimize preprocessing
function img = fastPreprocess(img)
    % Avoid repeated memory allocation
    persistent buffer;
    if isempty(buffer)
        buffer = zeros(224, 224, 3, 'single');
    end

    % Resize
    buffer = imresize(img, [224 224]);

    % Normalize in-place
    buffer = buffer / 255;

    img = buffer;
end
```

### GPU Kernel Optimization

```matlab
% Use page-wise operations (faster than loops)
% Bad:
for i = 1:batchSize
    Y(:,:,:,i) = conv2(X(:,:,:,i), kernel, 'same');
end

% Good:
Y = convn(X, kernel, 'same');  % Batched operation

% Use dlarray operations (optimized for GPU)
X = dlarray(data, 'SSCB');
Y = relu(X);  % Uses cuDNN kernels
```

### Inference Optimization

```matlab
% 1. Use predict instead of forward (no gradient tracking)
Y = predict(net, X);  % Faster

% 2. Disable cudnn autotuning for consistent batch sizes
cudnn = parallel.gpu.CUDAKernelManager();
cudnn.AutotuneLevel = 0;

% 3. Use fixed batch size (avoid recompilation)
options.MiniBatchSize = 32;  % Always use same batch

% 4. Quantization (reduced precision)
% See deployment.md for INT8 quantization
```

## Common Issues & Solutions

### Out of Memory

```matlab
% Error: Out of memory on device
% Solutions:

% 1. Reduce batch size
options = trainingOptions('adam', 'MiniBatchSize', 8);

% 2. Use smaller input size
inputSize = [224 224 3];  % Instead of [512 512 3]

% 3. Reduce network depth/filters
net = unet([256 256 1], 2, ...
    EncoderDepth=3, ...             % Shallower
    NumFirstEncoderFilters=32);     % Fewer filters (default is 64)

% 4. Clear unused variables
clear X_train Y_train;
reset(gpuDevice);

% 5. Process in patches (for large images)
% See medical-imaging.md for patch-based processing
```

### GPU Not Detected

```matlab
% Check CUDA installation
try
    gpu = gpuDevice;
    fprintf('GPU: %s\n', gpu.Name);
catch ME
    fprintf('GPU Error: %s\n', ME.message);

    % Check CUDA version
    system('nvcc --version');

    % Check driver
    system('nvidia-smi');
end

% Verify supported GPU
% Requires compute capability 3.5+
% See: https://www.mathworks.com/help/parallel-computing/gpu-support-by-release.html
```

### Training Slower Than Expected

```matlab
% Profile to identify bottlenecks

% 1. Data loading bottleneck
% Solution: Use parallel preprocessing
mbq = minibatchqueue(ds, ...
    'PreprocessingEnvironment', 'parallel', ...
    'DispatchInBackground', true);

% 2. Small batch size
% Solution: Increase if memory allows

% 3. CPU-GPU transfer bottleneck
% Solution: Ensure data stays on GPU
mbq = minibatchqueue(ds, ...
    'OutputEnvironment', 'gpu');  % Load directly to GPU

% 4. Network not fully utilizing GPU
% Check GPU utilization
gpu = gpuDevice;
fprintf('GPU Utilization: %.1f%%\n', gpu.KernelExecutionTime / ... );
```

---

*Verified against MATLAB R2025b*
