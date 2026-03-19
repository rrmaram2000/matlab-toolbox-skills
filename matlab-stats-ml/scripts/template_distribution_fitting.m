%% Template: Distribution Fitting for Clinical Measurement Data
% Fit parametric distributions to clinical measurements (lab values, vital
% signs, biomarker levels). Compare fits using negloglik(pd), AIC/BIC,
% KS tests, and QQ plots. Uses fitdist and makedist (R2025b compliant).
% MATLAB R2025b | Statistics and Machine Learning Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Statistics and Machine Learning Toolbox

%% TODO: Configure your data and parameters
dataPath = '';          % TODO: Path to your dataset (CSV, MAT, etc.)
measureVar = '';        % TODO: Name of the measurement variable to fit
alpha = 0.05;          % TODO: Significance level for KS test
distNames = {'Normal', 'Lognormal', 'Gamma', 'Weibull'}; % TODO: Distributions to fit

%% Step 1: Load and prepare data
data = readtable(dataPath);
x = data.(measureVar);

% Remove NaN and non-positive values (needed for Lognormal, Gamma, Weibull)
x = x(~isnan(x));
xPos = x(x > 0);

fprintf('Variable: %s\n', measureVar);
fprintf('Samples: %d (positive: %d)\n', numel(x), numel(xPos));
fprintf('Range: [%.3f, %.3f]\n', min(x), max(x));
fprintf('Mean: %.3f | Median: %.3f | Std: %.3f\n', mean(x), median(x), std(x));
fprintf('Skewness: %.3f | Kurtosis: %.3f\n', skewness(x), kurtosis(x));

%% Step 2: Fit distributions
nDist = numel(distNames);
pdFits = cell(1, nDist);
nll = zeros(1, nDist);
nParams = zeros(1, nDist);
fitSuccess = true(1, nDist);

for d = 1:nDist
    try
        if any(x <= 0) && ~strcmp(distNames{d}, 'Normal')
            pdFits{d} = fitdist(xPos, distNames{d});
        else
            pdFits{d} = fitdist(x, distNames{d});
        end
        % Use negloglik(pd) — NOT .NegLogLikelihood property
        nll(d) = negloglik(pdFits{d});
        nParams(d) = numel(pdFits{d}.ParameterValues);
    catch ME
        fprintf('Warning: %s fit failed — %s\n', distNames{d}, ME.message);
        fitSuccess(d) = false;
    end
end

%% Step 3: Compute AIC and BIC
n = numel(x);
AIC = zeros(1, nDist);
BIC = zeros(1, nDist);

for d = 1:nDist
    if fitSuccess(d)
        k = nParams(d);
        AIC(d) = 2 * nll(d) + 2 * k;
        BIC(d) = 2 * nll(d) + k * log(n);
    else
        AIC(d) = Inf;
        BIC(d) = Inf;
    end
end

%% Step 4: Display comparison table
fprintf('\n--- Distribution Comparison ---\n');
fprintf('%-12s  NLL        AIC        BIC        Parameters\n', 'Distribution');
fprintf('%s\n', repmat('-', 1, 65));

for d = 1:nDist
    if fitSuccess(d)
        paramStr = sprintf('%.4f ', pdFits{d}.ParameterValues);
        fprintf('%-12s  %-10.2f %-10.2f %-10.2f %s\n', ...
            distNames{d}, nll(d), AIC(d), BIC(d), strtrim(paramStr));
    end
end

[~, bestAIC] = min(AIC);
[~, bestBIC] = min(BIC);
fprintf('\nBest by AIC: %s\n', distNames{bestAIC});
fprintf('Best by BIC: %s\n', distNames{bestBIC});

%% Step 5: Kolmogorov-Smirnov goodness-of-fit tests
fprintf('\n--- Kolmogorov-Smirnov Tests (alpha = %.2f) ---\n', alpha);

for d = 1:nDist
    if ~fitSuccess(d), continue; end

    testData = x;
    if any(x <= 0) && ~strcmp(distNames{d}, 'Normal')
        testData = xPos;
    end

    % Rebuild distribution from fitted parameters for KS test
    paramCell = [pdFits{d}.ParameterNames; num2cell(pdFits{d}.ParameterValues)];
    pdRef = makedist(distNames{d}, paramCell{:});

    [h, p, ksstat] = kstest(testData, 'CDF', pdRef, 'Alpha', alpha);

    if h == 0
        verdict = 'PASS (cannot reject)';
    else
        verdict = 'FAIL (rejected)';
    end
    fprintf('%-12s  KS=%.4f  p=%.4f  %s\n', distNames{d}, ksstat, p, verdict);
end

%% Step 6: Histogram with fitted PDFs
figure('Name', 'Distribution Fits', 'Position', [100 100 650 450]);
histogram(x, 30, 'Normalization', 'pdf', ...
    'FaceColor', [0.7 0.8 0.9], 'EdgeColor', 'w');
hold on;

xRange = linspace(min(x), max(x), 300);
colors = lines(nDist);

for d = 1:nDist
    if ~fitSuccess(d), continue; end
    yFit = pdf(pdFits{d}, xRange);
    plot(xRange, yFit, 'Color', colors(d, :), 'LineWidth', 2);
end

hold off;
xlabel(measureVar);
ylabel('Probability Density');
title(sprintf('Distribution Fitting — %s', measureVar));
legend(['Data', distNames(fitSuccess)], 'Location', 'best');
grid on;

%% Step 7: QQ plots for each distribution
figure('Name', 'QQ Plots', 'Position', [100 550 900 400]);
nPlots = sum(fitSuccess);
plotIdx = 0;

for d = 1:nDist
    if ~fitSuccess(d), continue; end
    plotIdx = plotIdx + 1;
    subplot(1, nPlots, plotIdx);

    testData = x;
    if any(x <= 0) && ~strcmp(distNames{d}, 'Normal')
        testData = xPos;
    end

    qqplot(testData, pdFits{d});
    title(distNames{d});
    grid on;
end
sgtitle('QQ Plots — Distribution Fit Quality');

%% Step 8: CDF comparison
figure('Name', 'CDF Comparison', 'Position', [650 100 550 400]);
[fEmp, xEmp] = ecdf(x);
plot(xEmp, fEmp, 'k-', 'LineWidth', 2);
hold on;

for d = 1:nDist
    if ~fitSuccess(d), continue; end
    yCDF = cdf(pdFits{d}, xRange);
    plot(xRange, yCDF, '--', 'Color', colors(d, :), 'LineWidth', 1.5);
end

hold off;
xlabel(measureVar);
ylabel('Cumulative Probability');
title('Empirical vs Fitted CDFs');
legend(['Empirical', distNames(fitSuccess)], 'Location', 'southeast');
grid on;

%% Step 9: Summary — best fit recommendation
fprintf('\n--- Recommendation ---\n');
fprintf('Best fitting distribution (by BIC): %s\n', distNames{bestBIC});
fprintf('Parameters: ');
for p = 1:nParams(bestBIC)
    fprintf('%s = %.4f  ', pdFits{bestBIC}.ParameterNames{p}, ...
        pdFits{bestBIC}.ParameterValues(p));
end
fprintf('\n');
