%% Template: Hypothesis Testing for Treatment and Group Comparison
% Comprehensive statistical testing for clinical group comparisons.
% Includes parametric tests (t-test, ANOVA), non-parametric alternatives
% (Wilcoxon, Kruskal-Wallis), multiple comparison correction, and effect
% size computation (Cohen's d).
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
measureVar = '';        % TODO: Name of measurement/outcome variable
groupVar = '';          % TODO: Name of group/treatment variable
pairedVar = '';         % TODO: Name of paired/repeated measure variable (or '' if unpaired)
alpha = 0.05;          % TODO: Significance level

%% Step 1: Load and prepare data
data = readtable(dataPath);

Y = data.(measureVar);
G = data.(groupVar);
groups = unique(G);
nGroups = numel(groups);

fprintf('Variable: %s | Groups: %d | Total N: %d\n', ...
    measureVar, nGroups, numel(Y));

%% Step 2: Descriptive statistics by group
fprintf('\n--- Descriptive Statistics ---\n');
fprintf('%-15s  N     Mean      SD       Median    IQR\n', 'Group');
fprintf('%s\n', repmat('-', 1, 65));

for g = 1:nGroups
    mask = (G == groups(g)) | strcmp(string(G), string(groups(g)));
    yg = Y(mask);
    fprintf('%-15s  %-5d %-9.3f %-8.3f %-9.3f %.3f\n', ...
        string(groups(g)), sum(mask), mean(yg), std(yg), median(yg), iqr(yg));
end

%% Step 3: Normality assessment
fprintf('\n--- Normality Tests (Lilliefors) ---\n');
normalFlags = true(1, nGroups);

for g = 1:nGroups
    mask = (G == groups(g)) | strcmp(string(G), string(groups(g)));
    yg = Y(mask);
    [h, p] = lillietest(yg);
    normalFlags(g) = ~h;
    fprintf('%-15s  p = %.4f  %s\n', string(groups(g)), p, ...
        ternary(h, 'NON-NORMAL', 'Normal'));
end

allNormal = all(normalFlags);
fprintf('Overall: %s\n', ternary(allNormal, ...
    'All groups approximately normal — parametric tests appropriate', ...
    'Some groups non-normal — consider non-parametric tests'));

%% Step 4: Two-group comparison (if applicable)
if nGroups == 2
    mask1 = (G == groups(1)) | strcmp(string(G), string(groups(1)));
    mask2 = (G == groups(2)) | strcmp(string(G), string(groups(2)));
    y1 = Y(mask1);
    y2 = Y(mask2);

    % Independent two-sample t-test
    [~, pTtest, ciTtest, statsTtest] = ttest2(y1, y2, 'Alpha', alpha);
    fprintf('\n--- Two-Sample t-test (Independent) ---\n');
    fprintf('t(%d) = %.3f, p = %.4f\n', statsTtest.df, statsTtest.tstat, pTtest);
    fprintf('Mean difference 95%% CI: [%.3f, %.3f]\n', ciTtest(1), ciTtest(2));
    fprintf('Result: %s\n', ternary(pTtest < alpha, 'SIGNIFICANT', 'Not significant'));

    % Wilcoxon rank-sum (Mann-Whitney U)
    [pRanksum, ~, statsRanksum] = ranksum(y1, y2, 'Alpha', alpha);
    fprintf('\n--- Wilcoxon Rank-Sum (Mann-Whitney U) ---\n');
    fprintf('z = %.3f, p = %.4f\n', statsRanksum.zval, pRanksum);
    fprintf('Result: %s\n', ternary(pRanksum < alpha, 'SIGNIFICANT', 'Not significant'));

    % Cohen's d effect size
    pooledSD = sqrt(((numel(y1)-1)*var(y1) + (numel(y2)-1)*var(y2)) / ...
        (numel(y1) + numel(y2) - 2));
    cohensD = (mean(y1) - mean(y2)) / pooledSD;

    fprintf('\n--- Effect Size ---\n');
    fprintf('Cohen''s d = %.3f  ', cohensD);
    absD = abs(cohensD);
    if absD < 0.2
        fprintf('(negligible)\n');
    elseif absD < 0.5
        fprintf('(small)\n');
    elseif absD < 0.8
        fprintf('(medium)\n');
    else
        fprintf('(large)\n');
    end
end

%% Step 5: Paired comparison (if applicable)
if ~isempty(pairedVar) && nGroups == 2
    mask1 = (G == groups(1)) | strcmp(string(G), string(groups(1)));
    mask2 = (G == groups(2)) | strcmp(string(G), string(groups(2)));
    y1 = Y(mask1);
    y2 = Y(mask2);

    if numel(y1) == numel(y2)
        % Paired t-test
        [~, pPaired, ciPaired, statsPaired] = ttest(y1, y2, 'Alpha', alpha);
        fprintf('\n--- Paired t-test ---\n');
        fprintf('t(%d) = %.3f, p = %.4f\n', statsPaired.df, statsPaired.tstat, pPaired);

        % Wilcoxon signed-rank
        [pSignrank, ~, statsSignrank] = signrank(y1, y2, 'Alpha', alpha);
        fprintf('\n--- Wilcoxon Signed-Rank ---\n');
        fprintf('p = %.4f\n', pSignrank);
    end
end

%% Step 6: Multi-group comparison (ANOVA / Kruskal-Wallis)
if nGroups >= 3
    % One-way ANOVA
    [pAnova, tbl, statsAnova] = anova1(Y, G, 'off');
    fprintf('\n--- One-Way ANOVA ---\n');
    fprintf('F(%d,%d) = %.3f, p = %.4f\n', ...
        tbl{2,3}, tbl{3,3}, tbl{2,5}, pAnova);
    fprintf('Result: %s\n', ternary(pAnova < alpha, 'SIGNIFICANT', 'Not significant'));

    % Kruskal-Wallis (non-parametric)
    [pKW, tblKW, statsKW] = kruskalwallis(Y, G, 'off');
    fprintf('\n--- Kruskal-Wallis ---\n');
    fprintf('Chi-sq = %.3f, p = %.4f\n', tblKW{2,5}, pKW);

    % Post-hoc multiple comparisons (Tukey-Kramer)
    if pAnova < alpha
        fprintf('\n--- Post-hoc Multiple Comparisons (Tukey-Kramer) ---\n');
        figure('Name', 'Multiple Comparisons', 'Position', [100 100 500 400]);
        [compResults, ~, ~, groupNames] = multcompare(statsAnova, ...
            'Alpha', alpha, 'CType', 'tukey-kramer');

        fprintf('%-20s  Diff      CI Low    CI High   p-value\n', 'Comparison');
        for r = 1:size(compResults, 1)
            fprintf('%s vs %s  %7.3f  [%7.3f, %7.3f]  %.4f  %s\n', ...
                groupNames{compResults(r,1)}, groupNames{compResults(r,2)}, ...
                compResults(r,4), compResults(r,3), compResults(r,5), ...
                compResults(r,6), ternary(compResults(r,6) < alpha, '*', ''));
        end
    end
end

%% Step 7: Multiple comparison correction (Bonferroni & FDR)
% Collect all p-values from pairwise comparisons
if nGroups >= 3 && pAnova < alpha
    pValues = compResults(:, 6);
    nTests = numel(pValues);

    % Bonferroni correction
    pBonferroni = min(pValues * nTests, 1);

    % Benjamini-Hochberg FDR
    [sortedP, sortIdx] = sort(pValues);
    pFDR = zeros(size(pValues));
    for i = nTests:-1:1
        if i == nTests
            pFDR(sortIdx(i)) = sortedP(i);
        else
            pFDR(sortIdx(i)) = min(sortedP(i) * nTests / i, pFDR(sortIdx(i+1)));
        end
    end

    fprintf('\n--- Multiple Comparison Correction ---\n');
    fprintf('%-5s  Raw       Bonferroni  BH-FDR\n', 'Test');
    for i = 1:nTests
        fprintf('%-5d  %.4f    %.4f      %.4f\n', i, pValues(i), pBonferroni(i), pFDR(i));
    end
end

%% Step 8: Visualization — box plots by group
figure('Name', 'Group Comparison', 'Position', [650 100 500 400]);
boxplot(Y, G);
xlabel(groupVar);
ylabel(measureVar);
title(sprintf('Group Comparison — %s', measureVar));
grid on;

%% Step 9: Violin-style distribution comparison
figure('Name', 'Distribution Comparison', 'Position', [100 550 600 400]);
hold on;
colors = lines(nGroups);
for g = 1:nGroups
    mask = (G == groups(g)) | strcmp(string(G), string(groups(g)));
    yg = Y(mask);
    [f, xi] = ksdensity(yg);
    fill(f + g, xi, colors(g, :), 'FaceAlpha', 0.3, 'EdgeColor', colors(g, :));
    plot(f + g, xi, 'Color', colors(g, :), 'LineWidth', 1.5);
end
hold off;
xticks(1:nGroups);
xticklabels(string(groups));
ylabel(measureVar);
title('Distribution Comparison by Group');
grid on;

%% Helper function
function result = ternary(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
