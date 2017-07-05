% Configural Influences on Visual Working Memory
% Process Individual Data for ConfigVWM

% This code is written to process each individual subjects' data. It writes
% a .mat file that will be used for overall analysis. This code can also be
% used to plot indivudal subjects' performance by setting the
% 'wantSubPerfPlot' variable to 1.

% ============================== CHANGELOG ============================== %

% WXQN started writing this on 10/17/16.
% WXQN started piloting on 11/6/16.

% ======================================================================= %
                                                                 
% This code is available on github.com/WilliamNgiam
% Corresponding author: wngiam@uchicago.edu

% ----------------------------------------------------------------------- %

clear all;
close all;

rootDir = '/Users/wngi5916/Documents/MATLAB/ConfigVWM/Exp1/';
userDir = [rootDir, 'UserData/'];
dataDir = [rootDir, 'Data/'];
analysisDir = [rootDir, 'Analysis'];

subIDs = {'02'};
numSubs = numel(subIDs);

wantSubPerfPlot = 1;

for thisSub = 1:numSubs
    
    subDataDir = [dataDir, char(subIDs(thisSub))];
    cd(subDataDir);
    theseFiles = what;
    theseFiles = theseFiles.mat;
    numFiles = numel(theseFiles);
    load(theseFiles{1});
    
    data.numCorrPerTrial = NaN(experiment.numBlocks, experiment.numTrialsPerBlock);
    data.numCorr_repeat = NaN(experiment.numBlocks, experiment.numTrialsPerBlock/2);
    data.numCorr_random = NaN(experiment.numBlocks, experiment.numTrialsPerBlock/2);
        
    for thisFile = 1:numFiles
        
        load(theseFiles{thisFile});
        numCorr = sum(block.allCorrectLocs');
        data.numCorrPerTrial(block.thisBlock,:) = numCorr;
        data.numCorr_repeat(block.thisBlock,:) = numCorr(find(block.trialType == 1));
        data.numCorr_random(block.thisBlock,:) = numCorr(find(block.trialType == 2));
        
    end
    
    data.meanCorr = mean(data.numCorrPerTrial');
    data.meanCorr_repeat = mean(data.numCorr_repeat');
    data.meanCorr_random = mean(data.numCorr_random');
    
    if wantSubPerfPlot
        
        figure('Name',[subIDs{thisSub} ': Mean Performance Across Blocks']);
        plot(data.meanCorr,'LineWidth',2);
        axis([0 11 0 4]);
        xlabel('Block Number');
        ylabel('Mean Correct Responses');
        set(gca,'Box','on','FontSize',20,'LineWidth',2,'TickDir','out', ...
            'YMinorTick','on','XTick',1:10);
        figure('Name', [subIDs{thisSub} ': Mean Performance Across Blocks Split by Condition']);
        plot(data.meanCorr_repeat,'r-','LineWidth',2);
        axis([0 11 0 4]);
        xlabel('Block Number');
        ylabel('Mean Correct Responses');
        set(gca,'Box','on','FontSize',20,'LineWidth',2,'TickDir','out', ...
            'YMinorTick','on','XTick',1:10);
        hold on;
        plot(data.meanCorr_random,'b-','LineWidth',2);
        xlabel('Block Number');
        ylabel('Mean Correct Responses');
        set(gca,'Box','on','FontSize',20,'LineWidth',2,'TickDir','out', ...
            'YMinorTick','on','XTick',1:10);
        legend('Repeated','Random','Location','NorthOutside');
        
    end
    
    cd(userDir);
    userFileName = [char(subIDs(thisSub)) '_ConfigVWM_Exp1.mat'];
    load(userFileName);
    data.recogCorr = recognition.allCorrect;
    data.recogCorr_repeat = recognition.allCorrect(find(recognition.whichType == 1));
    data.recogCorr_random = recognition.allCorrect(find(recognition.whichType == 2));
    data.recogCorr_novel = recognition.allCorrect(find(recognition.whichType == 3));
    
    subFileName = [char(subIDs(thisSub)) '_ConfigVWM_Exp1_Processed.mat'];
    cd(analysisDir);
    save(subFileName,'block','colour','equipment','experiment','participant','stimulus','timing','data');
    
end
        
        
        
        
    
