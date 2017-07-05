% Configural Influences on Visual Working Memory
% Analyse Aggregate Data for ConfigVWM

% This code is written to analyse all data in this experiment. It will
% return aggregate data for performance and plot aggregated data.

% ============================== CHANGELOG ============================== %

% WXQN started writing this on 10/17/16.
% WXQN started piloting on 11/6/16.

% ======================================================================= %
                                                                 
% This code is available on github.com/WilliamNgiam
% Corresponding author: wngiam@uchicago.edu

% ----------------------------------------------------------------------- %


clear all;

rootDir = 'C:\Users\Dirk VU\Documents\MATLAB\Will\ConfigVWM\Exp1\';
userDir = [rootDir, 'UserData\'];
dataDir = [rootDir, 'Data\'];
analysisDir = [rootDir, 'Analysis'];

subIDs = {'01','02','03', '04'};
numSubs = numel(subIDs);

cd(analysisDir);
theseFiles = what;
theseFiles = theseFiles.mat;
numFiles = numel(theseFiles);
load(theseFiles{1})

allData.blockMeanCorr = NaN(numSubs,experiment.numBlocks);
allData.blockMeanCorr_repeat = NaN(numSubs,experiment.numBlocks);
allData.blockMeanCorr_random = NaN(numSubs,experiment.numBlocks);
allData.allMeanCorr = NaN(1,numSubs);
allData.allMeanCorr_repeat = NaN(1,numSubs);
allData.allMeanCorr_random = NaN(1,numSubs);

meanData.blockMeanCorr = NaN(1,experiment.numBlocks);
meanData.blockMeanCorr_repeat = NaN(1,experiment.numBlocks);
meanData.blockMeanCorr_random = NaN(1,experiment.numBlocks);

for thisFile = 1:numFiles
    
    load(theseFiles{thisFile});
    allData.blockMeanCorr(thisFile,:) = data.meanCorr;
    allData.blockMeanCorr_repeat(thisFile,:) = data.meanCorr_repeat;
    allData.blockMeanCorr_random(thisFile,:) = data.meanCorr_random;
    allData.allMeanCorr(thisFile) = mean(data.meanCorr);
    allData.allMeanCorr_repeat(thisFile) = mean(data.meanCorr_repeat);
    allData.allMeanCorr_random(thisFile) = mean(data.meanCorr_random);
    
end
    
meanData.blockMeanCorr = mean(allData.blockMeanCorr);
meanData.blockMeanCorr_repeat = mean(allData.blockMeanCorr_repeat);
meanData.blockMeanCorr_random = mean(allData.blockMeanCorr_random);

figure('Name','Mean Performance Across Blocks');
plot(meanData.blockMeanCorr/3,'LineWidth',2);
axis([0 11 0 1]);
xlabel('Block Number');
ylabel('Mean Correct Responses');
set(gca,'Box','on','FontSize',20,'LineWidth',2,'TickDir','out', ...
    'YMinorTick','on','XTick',1:10);
figure('Name','Mean Performance Across Blocks Split By Condition');
plot(meanData.blockMeanCorr_repeat/3,'r-','LineWidth',2);
axis([0 11 0 1]);
xlabel('Block Number');
ylabel('Mean Correct Responses');
set(gca,'Box','on','FontSize',20,'LineWidth',2,'TickDir','out', ...
    'YMinorTick','on','XTick',1:10);
hold on;
plot(meanData.blockMeanCorr_random/3,'b-','LineWidth',2);
xlabel('Block Number');
ylabel('Mean Correct Responses');
set(gca,'Box','on','FontSize',20,'LineWidth',2,'TickDir','out', ...
    'YMinorTick','on','XTick',1:10);
legend('Repeated','Random','Location','NorthOutside');
