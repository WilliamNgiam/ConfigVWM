% Configural Influences on Visual Working Memory

% This study examines whether repeated presentations of spatial
% configurations influences working memory for spatial location within
% those configurations. With repeated presentations, observers may learn to
% chunk separate locations together and form a memory file for the
% configuration. Chunking into a configuration is more efficient for
% encoding into visual working memory and may allow an increase in the
% amount of locations stored.

% Experiment 1 - This experiment is designed to establish whether repeated
% configurations improves visual working memory performance. Selected
% configurations are presented twice in each block, once on each side. An
% equal number of trials in each block will contain random configurations,
% only presented once in the experiment.

% ============================== CHANGELOG ============================== %

% WXQN started writing this on 10/17/16.
% WXQN started piloting on 11/6/16.
% WXQN added confidence ratings to recognition judgments 12/9/16.
% WXQN added eyetracking on 6/30/17.

% ======================================================================= %
                                                                 
% This code is available on github.com/WilliamNgiam
% Corresponding author: wngiam@uchicago.edu

% ----------------------------------------------------------------------- %

clear all;

% Preferences
skipSyncTests = 0;      % Set to 0 before running any experimental session!
fixation = 1;           % Toggles whether fixation dot required
instruction = 1;        % Toggles whether instructions are shown at beginning of experiment
practice = 1;           % Toggles whether practice trials are included
dyadCheck = 0;          % Prevents configurations for sharing dyads - Change this to 0 if stimulus.nItems > 3
eyetracking = 1;        % Toggles whether using eyetracking or not

% Set up save directories

rootDir = '/Users/wngi5916/Documents/MATLAB/ConfigVWM/Exp1/';
userDir = [rootDir, 'UserData/'];
dataDir = [rootDir, 'Data/'];
pracDir = [rootDir, 'PracEyeData/'];
testDir = [rootDir, 'TestEyeData/'];

stimulus.nItems = 4;    % Number of locations to be remembered
stimulus.nRows = 4;     % Number of rows in grid
stimulus.nCols = 4;     % Number of columns in grid;

stimulus.gridEcc = 6;       % Eccentricity of fixation to center of grid in degrees of visual angle
stimulus.dotSize = .5;      % Size of dot stimulus inside grid in degress of visual angle
stimulus.gridSize = 4;      % Length and width of grid in degrees of visual angle
stimulus.fixSize = .3;      % Size of fixation dot in degrees of visual angle
   
colour.white = 1;
colour.grey = .5;
colour.black = 0;
colour.text = colour.black;
colour.dot = .2;                % Changed from black to reduce contrast afterimages
colour.green = [0, 255, 0];     % Indicates correct response
colour.red = [255, 0 ,0];       % Indicates incorrect response

colour.fixVal = 1;              % Colour of fixation
colour.textVal = 0;             % Colour of text

experiment.numSelectedCombos = 16;      % Number of combos selected for learning - Made this equal to the number of locations for simplicity
experiment.numSelectedRepeats = 20;     % Number of times the selected combos are repeated - Equals the number of blocks in the experiment
experiment.numPracticeTrials = 10;      % Number of single-item practice trials
experiment.breakSecs = 20;              % Seconds of break between blocks

timing.retention = .25;         % Retention interval in seconds
timing.stimDelay = .25;         % Delay between participant initiating trial and stimulus onset
timing.mask = .25;              % Mask interval in seconds
timing.blank = 1;               % Delay interval in seconds
timing.ITI = 1;                 % Inter-trial interval

% Set up equipment parameters
equipment.viewDist = 700;           % Viewing distance in mm 
equipment.ppm = 3.6;                % Pixels per mm - Measured at UChicago on 22/6/16
equipment.refreshRate = 120;        % Record refresh rate

equipment.greyVal = .5;
equipment.blackVal = 0;
equipment.whiteVal = 1;

% Set up stimulus parameters
stimulus.nLocations = stimulus.nRows*stimulus.nCols;
vector = 1:stimulus.nLocations;                         % Creates a vector from one to the number of locations
allCombos = nchoosek(vector,stimulus.nItems);           % Creates the matrix indexing all possible Combos of locations
experiment.numPossibleCombos = length(allCombos);

% Set up experiment parameters
experiment.numBlocks = experiment.numSelectedRepeats/2;                             % Each block will show a repeated configuration twice in each block, once on each side
experiment.numTrialsPerBlock = 2*experiment.numSelectedCombos;                      % Each block will have equal number of repeated + random trials
experiment.numRandomCombos = experiment.numBlocks*experiment.numTrialsPerBlock;     % Number of random combinations required for the experiment - Two for each random+random trial

% Shuffle and record participant rng
rng('Shuffle');
participant.rng = rng;

% Set-up participant parameters

% Build GUI to record participant information

while true
    prompt = {'Participant Initials','Participant Age','Participant Gender','Participant Number','Random Seed'};
    rngSeed = participant.rng.Seed;
    defAns = {'XX','99','X','99',num2str(rngSeed)};
    box = inputdlg(prompt, 'Enter Subject Information', 1,defAns);
    participant.initials = char(box(1));
    participant.age = char(box(2));
    participant.gender = char(box(3));
    participant.ID = char(box(4));
    participant.rngSeed = char(box(5));
    fileName = [userDir,participant.ID '_ConfigVWM_Exp1.mat'];
    if ~exist(fileName) % Check for duplicate participant ID number
        if length(participant.initials) == 2 && length(participant.age) == 2 && length(participant.gender) == 1 && length(participant.ID) == 2
            break
        end
    elseif exist(fileName)==2
        disp('Duplicate participant number!');
    end        
end

% Set up Psychtoolbox Pipeline

AssertOpenGL;

    % Imaging set-up
screenID = max(Screen('Screens'));
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange');
Screen('Preference','SkipSyncTests',skipSyncTests);

    % Window set-up  
[ptbWindow, winRect] = PsychImaging('OpenWindow', screenID, colour.grey,[],[],[],[],6);
% PsychColorCorrection('SetEncodingGamma', ptbWindow, equipment.gammaVals);
[screenWidth, screenHeight] = RectSize(winRect);
screenCentreX = round(screenWidth/2);
screenCentreY = round(screenHeight/2);
flipInterval = Screen('GetFlipInterval', ptbWindow);

    % Text set-up   
Screen('TextFont',ptbWindow,'Arial');
Screen('TextSize',ptbWindow,20);
Screen('TextStyle',ptbWindow,1);        % Bold text

global ptb_drawformattedtext_disableClipping;       % Disable clipping of text 
ptb_drawformattedtext_disableClipping = 1;

% Enable alpha blending for typical drawing of masked textures
Screen('BlendFunction', ptbWindow, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Restrict enabled keys for KbWait and KbCheck function to only space and
% shift keys
RestrictKeysForKbCheck([225,229,44,43,30:32,97:99]);        % Remember to reset by calling RestrictKeysForKbCheck([]);

DrawFormattedText(ptbWindow, 'Loading...', 'center', 'center', colour.white);
Screen('Flip', ptbWindow);

% Set up eyetracking parameters (Eyelink)

if eyetracking    
    eyetrack.stimtrak = 0;      % Stimulus tracking
    eyetrack.eyeMode = 0;    % 0 = chin rest, 1 = remote
    
    % For chin rest monocular, camera -> eye distance = 40 - 70 cm (ideal
    % 50 - 55cm). 
    if EyelinkInit() ~= 1
        return
    end
    
    % Update defaults
    EyeLinkDefaults = EyelinkInitDefaults(ptbWindow);           % Need the Eyelink Toolbox
    EyeLinkDefaults.backgroundcolour = equipment.greyVal;       % Update background colour
    EyelinkDefaults.calibrationtargetcolour = colour.fixVal;    % Update calibration target colour
    EyeLinkDefaults.msgfontcolor = colour.textVal;              % Update font colour
    EyeLinkDefaults.imgtitlecolor = colour.textVal;             % Update image title colour (Actually not sure what this does again)
    EyelinkUpdateDefaults(EyeLinkDefaults);                     % Update settings
    
    % Set eye mode
    if eyetrack.eyeMode
        % Using remote mode
        Eyelink('command', 'elcl_select_configuration = RTABLER');      % Remote mode
        Eyelink('command', 'calibration_type = HV5');                   % 5-pt calibration
    else
        % Chin rest mode
        Eyelink('command', 'elcl_select_configuration = MTABLER');      % Chin rest
        Eyelink('command', 'calibration_type = HV9');                   % 9-pt calibration
    end
    
    Eyelink('command', 'sample_rate = %d', 1000)                % Set sampling rate
    Eyelink('command', 'add_file_preamble_text', 'CONF_E1')     % Header in EDF file
    Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, screenWidth-1, screenHeight-1);
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, screenWidth-1, screenHeight-1);
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');       % EDF file contents
    Eyelink('command', 'file_sample_data = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT');        
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');       % Set link data
    Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
    Eyelink('command', 'calibration_area_proportion 0.5 0.5');                                              % Adjust size of calibrated area
    Eyelink('command', 'validation_area_proportion 0.5 0.5');
    [eyetrack.version, eyetrack.versionString] = Eyelink('GetTrackerVersion');          % Get eye tracker version

    % Set up file to record data to
    edfFileName = [participant.ID, 'CONF.edf'];     % Cannot be more than 8 characters
    edfPracFile = [participant.ID, 'PRAC.edf'];     % Just saving a practice eyetracking file
    Eyelink('OpenFile', edfPracFile);   
    
end
    
% Select to-be-learned configurations (this takes a minute or so)
select = 1;
while select
    
    matched = zeros(1,stimulus.nLocations);
    participant.selectedCombos = sort(randperm(experiment.numPossibleCombos,experiment.numSelectedCombos))';
    participant.selectedComboLocs = allCombos(participant.selectedCombos,:);
    
    % Check selected combos do not have any diagnostic locations (a
    % location is in multiple selected combos)  
    for thisLocation = 1:stimulus.nLocations
        
        if sum(sum(allCombos(participant.selectedCombos,:)==thisLocation)) > 1
           
            matched(thisLocation) = 1;
            
        end
        
    end
    
    if dyadCheck
    
        % Check selected combos do not share dyads (to prevent learning dyad
        % chunks)
        for thisCombo = 1:experiment.numSelectedCombos

            counter = zeros(size(participant.selectedComboLocs));

            thisComboSet = allCombos(participant.selectedCombos(thisCombo),:);

            for thisSetLoc = 1:stimulus.nItems

                counter = counter + (participant.selectedComboLocs == thisComboSet(thisSetLoc));

            end

            numSharedLocs = sum(counter');

            if isempty(find(numSharedLocs == 2))

                dyadCheck(thisCombo) = 0;

            else

                dyadCheck(thisCombo) = 1;

            end

        end
        
        if sum(matched) == stimulus.nLocations && sum(dyadCheck) == 0

            select = 0;

        end
        
    else
        
        if sum(matched) == stimulus.nLocations
            
            select = 0;
            
        end
        
    end
    
end       
        
% Select random configurations so that each location is covered
leftoverCombos = Shuffle(setdiff(1:experiment.numPossibleCombos,participant.selectedCombos));
randomCombos = leftoverCombos(1:experiment.numRandomCombos);
participant.randomCombos = reshape(randomCombos,experiment.numBlocks,2,experiment.numTrialsPerBlock/2);

% Save configurations that won't be shown for recognition/familiarity test
participant.unseenCombos = Shuffle(setdiff(leftoverCombos,participant.randomCombos));       % This leaves unseen configurations for the recognition/familiarity test

% Calculate equipment parameters
equipment.mpd = (equipment.viewDist/2)*tan(deg2rad(2*stimulus.gridEcc))/stimulus.gridEcc; % Calculate mm per degree of visual angle to the ecccentricity of the stimuli
equipment.ppd = equipment.ppm*equipment.mpd;        % Pixels per degree
equipment.secsPerRefresh = 1/equipment.refreshRate;

% Calculate spatial parameters
stimulus.gridEcc_pix = round(stimulus.gridEcc*equipment.ppd);           % Grid eccentricity in pixels
stimulus.dotSize_pix = round(stimulus.dotSize*equipment.ppd);           % Dot size in pixels
stimulus.gridSize_pix = round(stimulus.gridSize*equipment.ppd);         % Grid size in pixels
stimulus.fixSize_pix = round(stimulus.fixSize*equipment.ppd);           % Fixation dot size in pixels
stimulus.boxWidth_pix = round(stimulus.gridEcc_pix/stimulus.nCols);     % Grid box width in pixels
stimulus.boxHeight_pix = round(stimulus.gridEcc_pix/stimulus.nRows);    % Grid box height in pixels

% Set up location rects
fixRect = [0 0 stimulus.fixSize_pix stimulus.fixSize_pix];              % Fixation rect
fixRect = CenterRectOnPoint(fixRect, screenCentreX, screenCentreY);     % Centred in the middle of the screen

dotRect = [0 0 stimulus.dotSize_pix stimulus.dotSize_pix];              % Colour stimulus rect
boxRect = [0 0 stimulus.boxWidth_pix stimulus.boxHeight_pix];

leftDotRects = NaN(4,stimulus.nLocations);
rightDotRects = NaN(4,stimulus.nLocations);
leftGridRects = NaN(4,stimulus.nLocations);
rightGridRects = NaN(4,stimulus.nLocations);
recogRects = NaN(4,stimulus.nLocations);

for thisBox = 1:stimulus.nLocations
    
    thisCol = mod(thisBox,stimulus.nRows);
    thisRow = ceil(thisBox/stimulus.nCols);
    leftDotRects(:,thisBox) = CenterRectOnPoint(dotRect, screenCentreX-((5-thisRow)*stimulus.boxWidth_pix), screenCentreY-((thisCol-1.5)*stimulus.boxWidth_pix));
    rightDotRects(:,thisBox) = CenterRectOnPoint(dotRect, screenCentreX+(thisRow*stimulus.boxWidth_pix), screenCentreY-((thisCol-1.5)*stimulus.boxWidth_pix));
    leftGridRects(:,thisBox) = CenterRectOnPoint(boxRect, screenCentreX-((5-thisRow)*stimulus.boxWidth_pix), screenCentreY-((thisCol-1.5)*stimulus.boxWidth_pix));
    rightGridRects(:,thisBox) = CenterRectOnPoint(boxRect, screenCentreX+(thisRow*stimulus.boxWidth_pix), screenCentreY-((thisCol-1.5)*stimulus.boxWidth_pix));
    recogDotRects(:,thisBox) = CenterRectOnPoint(dotRect, screenCentreX+((thisRow-2.5)*stimulus.boxWidth_pix), screenCentreY-((thisCol-1.5)*stimulus.boxWidth_pix));
    recogGridRects(:,thisBox) = CenterRectOnPoint(boxRect, screenCentreX+((thisRow-2.5)*stimulus.boxWidth_pix), screenCentreY-((thisCol-1.5)*stimulus.boxWidth_pix));
    
end

% That should be all...save user file
cd(userDir);
participant.userFile = [participant.ID '_ConfigVWM_Exp1.mat'];
save(participant.userFile, 'participant', 'stimulus', 'experiment', 'equipment', 'colour', 'timing');

% Create a participant folder in the data directory
cd(dataDir);
subjDir = [dataDir, participant.ID];
mkdir(subjDir);

% Write instruction text
if instruction

    instructionText = ['Welcome to this experiment!\n\n' ...
        'In this experiment, you will be shown two grids, one on the left and one on the right.\n\n' ...
        'In each grid, there will be ' num2str(stimulus.nItems) ' dots.\n\n' ...
        'Your task is to remember the location of all the dots.\n\n\n\n' ...
        'Press SPACE to continue.'];

    DrawFormattedText(ptbWindow, instructionText, 'center', 'center', colour.text);
    Screen('Flip', ptbWindow);

    while 1

        [startTrialTime, keyCode] = KbWait(-1,2);    

        if find(keyCode) == 44      %'Space' to start trial

            break

        end

    end

    if fixation

        fixationText = ['You will also see a small white dot in the middle of the screen.\n\n' ...
            'Try and keep your eyes still, fixed on the white dot.\n\n\n\n' ...
            'Press SPACE to continue.'];

        DrawFormattedText(ptbWindow, fixationText, 'center', 'center', colour.text);
        Screen('Flip', ptbWindow);    

            while 1

            [startTrialTime, keyCode] = KbWait(-1,2);    

            if find(keyCode) == 44      %'Space' to start trial

                break

            end

        end

    end

    responseInstructionText = ['At the end of a trial, you will be shown one of the two grids.\n\n' ...
        'Click on the locations where you think the dots were.\n\n' ...
        'You can undo a misclick by clicking again in the same location.\n\n\n\n' ...
        'Once you click on ' num2str(stimulus.nItems) ' locations, press SPACE to submit your answer.\n\n' ...
        'Otherwise, press SHIFT to change your answer.\n\n\n\n' ...
        'After you submit your answer, the dots will turn green to indicate you were right\n\n' ...
        'or turn red to indicate you were wrong\n\n\n\n' ...
        'Press SPACE to continue.'];

    DrawFormattedText(ptbWindow, responseInstructionText, 'center', 'center', colour.text);
    Screen('Flip', ptbWindow);
    
    while 1

        [startTrialTime, keyCode] = KbWait(-1,2);    

        if find(keyCode) == 44      %'Space' to start trial

            break

        end

    end
    
end

if eyetracking

    % Start eyetracker

    EyelinkDoTrackerSetup(EyeLinkDefaults);

end

if practice

    practiceText = ['You will now try some practice trials.\n\n' ...
        'You will only see one dot in each grid, instead of ' num2str(stimulus.nItems) '.\n\n' ...
        'Press SPACE to start the practice trials.'];

    DrawFormattedText(ptbWindow, practiceText, 'center', 'center', colour.text);
    Screen('Flip', ptbWindow);

    while 1

        [startTrialTime, keyCode] = KbWait(-1,2);    

        if find(keyCode) == 44      %'Space' to start trial

            break

        end

    end

    % Practice Trials

    for thisPracticeTrial = 1:experiment.numPracticeTrials
        
        if eyetracking
            
            % Idle eye-tracker
            
            Eyelink('command', 'set_idle_mode');    % Idle eyetracker
            
        end

            if fixation

                Screen('FillOval', ptbWindow, colour.white, fixRect);

            end
            
            Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
            Screen('FrameRect', ptbWindow, colour.white, rightGridRects);
            
            Screen('Flip',ptbWindow);
            
            while 1

                [startTrialTime, keyCode] = KbWait(-1,2);    

                if find(keyCode) == 44      %'Space' to start trial

                    break

                end

            end
            
            if eyetracking
                
                % Start eyetracker
                
                Eyelink('command', 'record_status_message ''TRIAL %d''', thisPracticeTrial);
                Eyelink('StartRecording');
                Eyelink('message', 'TRIAL %d ', thisPracticeTrial);
                Eyelink('message', 'TrialStart');       % Zero-point time in EDF file
                
            end

            % Build the stimulus display    
            
            if fixation

                Screen('FillOval', ptbWindow, colour.white, fixRect);

            end

            Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
            Screen('FrameRect', ptbWindow, colour.white, rightGridRects);

            leftDot = randi(stimulus.nLocations);
            rightDot = randi(stimulus.nLocations);
            
            Screen('FillOval', ptbWindow, colour.dot, leftDotRects(:,leftDot));
            Screen('FillOval', ptbWindow, colour.dot, rightDotRects(:,rightDot));
            
            % Flip the stimulus display
            [stimTime,~,~,~] = Screen('Flip', ptbWindow, startTrialTime+timing.stimDelay);
            
            if eyetracking
                
                Eyelink('message','SampleOnset');
                
            end
            
            % Build the mask display
            if fixation

                Screen('FillOval', ptbWindow, colour.white, fixRect);

            end

            Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
            Screen('FrameRect', ptbWindow, colour.white, rightGridRects);

            Screen('FillOval', ptbWindow, colour.dot, leftDotRects);
            Screen('FillOval', ptbWindow, colour.dot, rightDotRects);

            % Flip the mask display
            [maskTime,~,~,block.maskFlips(thisPracticeTrial)] = Screen('Flip', ptbWindow, stimTime+timing.retention);
            
            if eyetracking
                
                Eyelink('message','MaskOnset');
                
            end
            
            % Flip to blank

            if fixation

                Screen('FillOval', ptbWindow, colour.white, fixRect);

            end
            
            [blankTime,~,~,~] = Screen('Flip', ptbWindow, maskTime+timing.mask);
            
            if eyetracking
                
                Eyelink('message','BlankOnset');
                
            end
            
            % Record click responses

            if fixation

                Screen('FillOval', ptbWindow, colour.white, fixRect);

            end
            
            [responseTime,~,~,~] = Screen('Flip', ptbWindow, blankTime+timing.blank);
            
            if eyetracking
                
                %Stop eyetracker
                Eyelink('message','Response');
                Eyelink('StopRecording');
            
            end
            
            response = 1;

            % Set all locations to off
            clickedLocs = zeros(1,stimulus.nLocations);
            % For mouse click responses 
            ShowCursor(0) ;
            SetMouse(screenCentreX,screenCentreY,ptbWindow);

            responseText = ['Click on the ' num2str(stimulus.nItems) ' locations you saw in the grid.\n\n' ...
                'Click again to undo any misclick.'];
            submitText = ['Press SPACE to submit your answer. Press SHIFT to change your answer.'];

            sideTested = randi(2);            
            while response

                % Draw instruction text

                DrawFormattedText(ptbWindow, responseText, 'center', 200, colour.text);

                % Draw grid to be tested 

                if fixation

                    Screen('FillOval', ptbWindow, colour.white, fixRect);

                end
             
                if sideTested == 1

                    Screen('FrameRect', ptbWindow, colour.white, leftGridRects);

                    for thisLoc = 1:stimulus.nLocations

                        if clickedLocs(thisLoc) == 1

                            Screen('FillOval', ptbWindow, colour.dot, leftDotRects(:,thisLoc));

                        end

                    end

                elseif sideTested == 2

                    Screen('FrameRect', ptbWindow, colour.white, rightGridRects);

                    for thisLoc = 1:stimulus.nLocations

                        if clickedLocs(thisLoc) == 1

                            Screen('FillOval', ptbWindow, colour.dot, rightDotRects(:,thisLoc));

                        end

                    end

                end

                if sum(clickedLocs) == 1

                    canSubmit = 1;
                    DrawFormattedText(ptbWindow, submitText, 'center', 1000, colour.text);
                    Screen('Flip', ptbWindow);

                    while canSubmit

                        [keyIsDown, secs, keyCode] = KbCheck(-1,2);

                        if find(keyCode) == 44          % 'Space'

                            % Save response
                            thisResponse = find(clickedLocs);
                            HideCursor;
                            canSubmit = 0;
                            response = 0;

                        elseif find(keyCode) == 160 | find(keyCode) == 161

                            canSubmit = 0;
                            clickedLocs(lastClickedLoc) = 0;

                         end        

                    end

                else

                    Screen('Flip', ptbWindow);
                    CheckResponse = zeros(1,stimulus.nLocations);

                    while ~any(CheckResponse)

                        [~,xClickResponse,yClickResponse] = GetClicks(ptbWindow,0);     % Retrieves x- and y-coordinates of mouse click
                        clickSecs = GetSecs;

                        if sideTested == 1

                            for thisLoc = 1:stimulus.nLocations

                                CheckResponse(thisLoc) = IsInRect(xClickResponse,yClickResponse,leftGridRects(:,thisLoc));     % Tests if mouse click is inside aperture of each successive item

                            end

                        elseif sideTested == 2

                             for thisLoc = 1:stimulus.nLocations

                                CheckResponse(thisLoc) = IsInRect(xClickResponse,yClickResponse,rightGridRects(:,thisLoc));     % Tests if mouse click is inside aperture of each successive item

                             end

                        end

                        responseLoc = find(CheckResponse);
                        lastClickedLoc = responseLoc;
                        clickedLocs(responseLoc) = 1 - clickedLocs(responseLoc);    % Switch off to on or on to off

                    end

                end 

            end

            % Show them what they get right and wrong

            if sideTested == 1

                Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
                testedLocs = leftDot;

            elseif sideTested == 2

                Screen('FrameRect', ptbWindow, colour.white, rightGridRects);
                testedLocs = rightDot;

            end

            correctLocs = ismember(testedLocs,thisResponse);

            if correctLocs == 1  % Correct

                if sideTested == 1

                    Screen('FillOval', ptbWindow, colour.green, leftDotRects(:,thisResponse));

                elseif sideTested == 2

                    Screen('FillOval', ptbWindow, colour.green, rightDotRects(:,thisResponse));

                end

            elseif correctLocs == 0  % Incorrect

                if sideTested == 1

                    Screen('FillOval', ptbWindow, colour.red, leftDotRects(:,thisResponse));

                elseif sideTested == 2

                    Screen('FillOval', ptbWindow, colour.red, rightDotRects(:,thisResponse));

                end
                
            end

            if fixation

                Screen('FillOval', ptbWindow, colour.white, fixRect);

            end

            endTrialTime = Screen('Flip', ptbWindow);
            WaitSecs(timing.ITI);

    end

    % Practice completed
    
    if eyetracking
        
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.5);
        Eyelink('CloseFile');
        grabEDF(edfPracFile, pracDir);
        
    end
    
    practiceFinishText = ['You have finished the practice trials.\n\n' ...
        'Now you will start the experiment. The experiment has ' num2str(experiment.numBlocks) ' blocks.\n\n' ...
        'Each block has ' num2str(experiment.numTrialsPerBlock) ' trials.\n\n' ...
        'If you have any questions, please ask the experimenter now.\n\n' ...
        'Press SPACE to begin the experiment.'];
    
    DrawFormattedText(ptbWindow, practiceFinishText, 'center', 'center', colour.text);
    Screen('Flip', ptbWindow);
    
    while 1

        [startTrialTime, keyCode] = KbWait(-1,2);    

        if find(keyCode) == 44      %'Space' to start trial

            break

        end

    end
    
end

if eyetracking
    
    Eyelink('OpenFile', edfFileName);

end

% ======================================================================= %

% Experiment Loop Starts Here

% ======================================================================= %

for thisBlock = 1:experiment.numBlocks
   
    % Build block parameters
    block.thisBlock = thisBlock;        % Just saving this so data analysis will be easier later
    
    % Build structure to save which trials have missed flips
    block.stimFlips = NaN(1,experiment.numTrialsPerBlock);
    block.blankFlips = NaN(1,experiment.numTrialsPerBlock);
    block.responseFlips = NaN(1,experiment.numTrialsPerBlock);
    
    % Create an array to save responses
    block.allResponses = NaN(experiment.numTrialsPerBlock,stimulus.nItems);
    
    % Create an array to save correct
    block.allCorrectLocs = NaN(experiment.numTrialsPerBlock,stimulus.nItems);
    
    % Randomise which side is tested on each trial
    block.sideTested = mod(randperm(experiment.numTrialsPerBlock),2)+1;     % 1 = test left side, 2 = test right side
    
    % Randomise which items are tested on each trial
    sample = 1;
    while sample

        block.allLeftRepeatedItems = Shuffle(participant.selectedCombos);
        block.allRightRepeatedItems = Shuffle(participant.selectedCombos);

        if sum(sum(block.allLeftRepeatedItems == block.allRightRepeatedItems)) == 0     % Make sure the same item is not shown on both sides

            sample = 0;

        end

    end
            
    sample = 1;
    while sample

        block.allLeftRandomItems = Shuffle(squeeze(participant.randomCombos(thisBlock,1,:)));
        block.allRightRandomItems = Shuffle(squeeze(participant.randomCombos(thisBlock,2,:)));

        if isempty(find(sum((allCombos(block.allLeftRandomItems,:) == allCombos(block.allRightRandomItems,:)),2)>1))     % Make sure the random items on each trial don't share two locations     

            sample = 0;

        end

    end
    
    % Shuffle/Interleave the type of trial that is tested
    block.trialType = mod(randperm(experiment.numTrialsPerBlock),2)+1;       % 1 = repeat, 2 = random
    
    % Build block combination structure
    block.allCombos = NaN(experiment.numTrialsPerBlock,2);
    counter = ones(1,2);
    for thisTrial = 1:experiment.numTrialsPerBlock
        
        if block.trialType(thisTrial) == 1
            
            block.allCombos(thisTrial,:) = [block.allLeftRepeatedItems(counter(1)) block.allRightRepeatedItems(counter(1))];
            counter(1) = counter(1)+1;
            
        elseif block.trialType(thisTrial) == 2
            
            block.allCombos(thisTrial,:) = [block.allLeftRandomItems(counter(2)) block.allRightRandomItems(counter(2))];
            counter(2) = counter(2)+1;
            
        end
        
    end

% ======================================================================= %

% Experiment Trial Loop Starts Here

% ======================================================================= %
    
    % Start block screen
    
    startBlockText = ['Press SPACE to start this block.'];
    DrawFormattedText(ptbWindow, startBlockText, 'center', 'center', colour.text);
    block.startTime = Screen('Flip', ptbWindow);

    while 1

        [startTrialTime, keyCode] = KbWait(-1,2);    

        if find(keyCode) == 44      %'Space' to start trial

            break

        end

    end
    
    for thisTrial = 1:experiment.numTrialsPerBlock
          
        if eyetracking
            
            % Idle eye-tracker
            
            Eyelink('command', 'set_idle_mode');        % Set idle more
            
        end
        
        HideCursor;
        
        % Wait for space to initiate trial

        if fixation

            Screen('FillOval', ptbWindow, colour.white, fixRect);

        end
        
        Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
        Screen('FrameRect', ptbWindow, colour.white, rightGridRects);
        
        Screen('Flip',ptbWindow);

        while 1

            [startTrialTime, keyCode] = KbWait(-1,2);    

            if find(keyCode) == 44      %'Space' to start trial

                break

            end

        end

        if eyetracking
            
            % Start eyetracker
            
            Eyelink('command', 'record_status_message ''BLOCK %d TRIAL %d''', thisBlock, thisTrial);
            Eyelink('StartRecording');
            Eyelink('message', 'Block %d', thisBlock);
            Eyelink('message', 'Trial %d', thisTrial);
            Eyelink('message', 'TrialStart');       % Zero-point time in EDF file
            
        end
        
        % Build the stimulus display    
        if fixation

            Screen('FillOval', ptbWindow, colour.white, fixRect);

        end

        Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
        Screen('FrameRect', ptbWindow, colour.white, rightGridRects);

        theseLeftLocs = allCombos(block.allCombos(thisTrial,1),:);
        theseRightLocs = allCombos(block.allCombos(thisTrial,2),:);

        for thisLoc = 1:stimulus.nItems

            Screen('FillOval', ptbWindow, colour.dot, leftDotRects(:,theseLeftLocs(thisLoc)));
            Screen('FillOval', ptbWindow, colour.dot, rightDotRects(:,theseRightLocs(thisLoc)));

        end

        % Flip the stimulus display
        [stimTime,~,~,block.stimFlips(thisTrial)] = Screen('Flip', ptbWindow, startTrialTime+timing.stimDelay);
        
        if eyetracking
            
            Eyelink('message','SampleOnset');
            
        end
        
        % Build the mask display
        if fixation

            Screen('FillOval', ptbWindow, colour.white, fixRect);

        end
        
        Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
        Screen('FrameRect', ptbWindow, colour.white, rightGridRects);
        
        Screen('FillOval', ptbWindow, colour.dot, leftDotRects);
        Screen('FillOval', ptbWindow, colour.dot, rightDotRects);

        % Flip the mask display
        [maskTime,~,~,block.maskFlips(thisTrial)] = Screen('Flip', ptbWindow, stimTime+timing.retention);
        
        if eyetracking
            
            Eyelink('message','MaskOnset');
            
        end
        
        % Flip to blank

        Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
        Screen('FrameRect', ptbWindow, colour.white, rightGridRects);
        
        if fixation

            Screen('FillOval', ptbWindow, colour.white, fixRect);

        end

        [blankTime,~,~,block.blankFlips(thisTrial)] = Screen('Flip', ptbWindow, maskTime+timing.mask);
        
        if eyetracking
            
            Eyelink('message','BlankOnset');
            
        end
        
        % Record click responses

        if fixation

            Screen('FillOval', ptbWindow, colour.white, fixRect);

        end
        
        [responseTime,~,~,block.responseFlips(thisTrial)] = Screen('Flip', ptbWindow, blankTime+timing.blank);
        
        if eyetracking
            
            % Stop eyetracker
            Eyelink('message', 'Response');
            Eyelink('StopRecording');
            
        end
        
        response = 1;

        % Set all locations to off
        clickedLocs = zeros(1,stimulus.nLocations);
        
        responseText = ['Click on the ' num2str(stimulus.nItems) ' locations you saw in the grid.\n\n' ...
            'Click again to undo any misclick.'];
        submitText = ['Press SPACE to submit your answer. Press SHIFT to change your answer'];

        % For mouse click responses 
        ShowCursor(0);
        SetMouse(screenCentreX,screenCentreY,ptbWindow);
        
        while response

            % Draw instruction text

            DrawFormattedText(ptbWindow, responseText, 'center', 200, colour.text);
            
            % Draw grid to be tested 

            if fixation

                Screen('FillOval', ptbWindow, colour.white, fixRect);

            end

            if block.sideTested(thisTrial) == 1

                Screen('FrameRect', ptbWindow, colour.white, leftGridRects);

                for thisLoc = 1:stimulus.nLocations

                    if clickedLocs(thisLoc) == 1

                        Screen('FillOval', ptbWindow, colour.dot, leftDotRects(:,thisLoc));

                    end

                end

            elseif block.sideTested(thisTrial) == 2

                Screen('FrameRect', ptbWindow, colour.white, rightGridRects);

                for thisLoc = 1:stimulus.nLocations

                    if clickedLocs(thisLoc) == 1

                        Screen('FillOval', ptbWindow, colour.dot, rightDotRects(:,thisLoc));

                    end

                end

            end

            if sum(clickedLocs) == stimulus.nItems

                canSubmit = 1;
                DrawFormattedText(ptbWindow, submitText, 'center', 800, colour.text);
                Screen('Flip', ptbWindow);

                while canSubmit

                    [keyIsDown, secs, keyCode] = KbCheck(-1,2);

                    if find(keyCode) == 44          % 'Space'

                        % Save response
                        block.allResponses(thisTrial,:) = find(clickedLocs);
                        HideCursor;
                        canSubmit = 0;
                        response = 0;

                    elseif find(keyCode) == 225 | find(keyCode) == 229

                        canSubmit = 0;
                        clickedLocs(lastClickedLoc) = 0;

                     end        

                end

            else

                Screen('Flip', ptbWindow);
                CheckResponse = zeros(1,stimulus.nLocations);
                ShowCursor(0);

                while ~any(CheckResponse)

                    [~,xClickResponse,yClickResponse] = GetClicks(ptbWindow,0);     % Retrieves x- and y-coordinates of mouse click
                    clickSecs = GetSecs;

                    if block.sideTested(thisTrial) == 1

                        for thisLoc = 1:stimulus.nLocations

                            CheckResponse(thisLoc) = IsInRect(xClickResponse,yClickResponse,leftGridRects(:,thisLoc));     % Tests if mouse click is inside aperture of each successive item

                        end

                    elseif block.sideTested(thisTrial) == 2

                         for thisLoc = 1:stimulus.nLocations

                            CheckResponse(thisLoc) = IsInRect(xClickResponse,yClickResponse,rightGridRects(:,thisLoc));     % Tests if mouse click is inside aperture of each successive item

                         end

                    end

                    responseLoc = find(CheckResponse);
                    lastClickedLoc = responseLoc;
                    clickedLocs(responseLoc) = 1 - clickedLocs(responseLoc);    % Switch off to on or on to off

                end

            end 

        end
        
        % Show them what they get right and wrong
        
        if block.sideTested(thisTrial) == 1
            
            Screen('FrameRect', ptbWindow, colour.white, leftGridRects);
            testedLocs = theseLeftLocs;
            
        elseif block.sideTested(thisTrial) == 2
            
            Screen('FrameRect', ptbWindow, colour.white, rightGridRects);
            testedLocs = theseRightLocs;
            
        end
        
        block.allCorrectLocs(thisTrial,:) = ismember(testedLocs,block.allResponses(thisTrial,:));
        
        for thisItem = 1:stimulus.nItems
            
            if block.allCorrectLocs(thisTrial,thisItem) == 1  % Correct
                
                if block.sideTested(thisTrial) == 1

                    Screen('FillOval', ptbWindow, colour.green, leftDotRects(:,block.allResponses(thisTrial,thisItem)));
                    
                elseif block.sideTested(thisTrial) == 2
                    
                    Screen('FillOval', ptbWindow, colour.green, rightDotRects(:,block.allResponses(thisTrial,thisItem)));
                    
                end
                
            elseif block.allCorrectLocs(thisTrial,thisItem) == 0  % Incorrect
                
                if block.sideTested(thisTrial) == 1
                    
                    Screen('FillOval', ptbWindow, colour.red, leftDotRects(:,block.allResponses(thisTrial,thisItem)));
                    
                elseif block.sideTested(thisTrial) == 2
                    
                    Screen('FillOval', ptbWindow, colour.red, rightDotRects(:,block.allResponses(thisTrial,thisItem)));
                    
                end
                
            end
            
        end
        
        if fixation

            Screen('FillOval', ptbWindow, colour.white, fixRect);

        end

        Screen('DrawingFinished', ptbWindow);
        endTrialTime = Screen('Flip', ptbWindow);
        WaitSecs(timing.ITI);           

    end

    % Block finished, save block file
    cd(subjDir);
    blockFileName = [participant.ID '_ConfigVWM_Exp1_' num2str(block.thisBlock) '.mat'];
    save(blockFileName, 'block', 'experiment', 'equipment', 'colour', 'stimulus', 'timing', 'participant');
    
    % Tell them how many blocks they've completed
    for thisSec = 1:experiment.breakSecs
    
        endBlockText = ['You have completed ' num2str(block.thisBlock) ' out of ' num2str(experiment.numBlocks) ' blocks.\n\n' ...
            'Time Left: ' num2str(experiment.breakSecs-thisSec)];
        DrawFormattedText(ptbWindow, endBlockText, 'center', 'center', colour.text);
        Screen('Flip', ptbWindow);
        WaitSecs(1);
        
    end
    
end

% Familiarity Test is completed
% Close and save eyetracking file

if eyetracking
    
    Eyelink('command', 'set_idle_mode');
    WaitSecs(0.5);
    Eyelink('CloseFile');
    grabEDF(edfFileName,testDir);
    
end

% ======================================================================= %

% Recognition Test Starts Here

% ======================================================================= %

% First, survey the participant about explicitly noticing repeats

recognitionTest = ['Now you will complete a short recognition task.\n\n' ...
    'You will be shown a configuration in the middle of the screen.\n\n' ...
    'If you think you have seen the configuration before, press SPACE.\n\n' ...
    'If you do not think you have seen the configuration before, press SHIFT.\n\n\n\n'];

tabTest = [recognitionTest 'Press TAB to start the recognition test.'];
    
DrawFormattedText(ptbWindow, recognitionTest, 'center', 'center', colour.text);
Screen('Flip', ptbWindow);
WaitSecs(5);

DrawFormattedText(ptbWindow, tabTest, 'center', 'center', colour.text);
Screen('Flip', ptbWindow);

while 1
    
[~, keyCode] = KbWait(-1,2);  

    if find(keyCode) == 43          % 'Tab'

        break
        
    end

end

% Build recognition test block
recognition.numTrials = experiment.numSelectedCombos*3;

% Gather equal numbers of selected, random and unseen combos
recognition.selectedCombos = Shuffle(participant.selectedCombos);
recognition.randomCombos = Shuffle(participant.randomCombos(randperm(experiment.numRandomCombos,experiment.numSelectedCombos)));
recognition.unseenCombos = Shuffle(participant.unseenCombos(randperm(numel(participant.unseenCombos),experiment.numSelectedCombos)));

% Build array for which configurations to show in the whole test
recognition.allCombos = NaN(1,recognition.numTrials);
recognition.whichType = mod(randperm(recognition.numTrials),3)+1;
counter = ones(1,3);
for thisTrial = 1:recognition.numTrials

    if recognition.whichType(thisTrial) == 1

        recognition.allCombos(thisTrial) = recognition.selectedCombos(counter(1));
        counter(1) = counter(1)+1;

    elseif recognition.whichType(thisTrial) == 2

        recognition.allCombos(thisTrial) = recognition.randomCombos(counter(2));
        counter(2) = counter(2)+1;
        
    elseif recognition.whichType(thisTrial) == 3
        
        recognition.allCombos(thisTrial) = recognition.unseenCombos(counter(3));
        counter(3) = counter(3)+1;      

    end

end

% Build array to record response
recognition.allResponses = NaN(1,recognition.numTrials);
recognition.allCorrect = NaN(1,recognition.numTrials);
recognition.allRT = NaN(1,recognition.numTrials);
recognition.allConfidence = NaN(1,recognition.numTrials);

recognitionText = ['Press SPACE if you think you have seen this pattern before.\n\n' ...
    'Press SHIFT if you think you have not.'];

confidenceText = ['Press 1, 2 or 3 to indicate how confident your response is.\n\n' ...
    '1 = Not Confident, 2 = Somewhat Confident, 3 = Very Confident'];

% Start recognition test
for thisTrial = 1:recognition.numTrials
       
    DrawFormattedText(ptbWindow, recognitionText, 'center', 200, colour.text);
    
    % Draw grid in middle of screen
    Screen('FrameRect', ptbWindow, colour.white, recogGridRects);
    
    % Retrieve the configuration
    configLocs = allCombos(recognition.allCombos(thisTrial),:);
    
    for thisLoc = 1:stimulus.nItems
        
        Screen('FillOval', ptbWindow, colour.dot, recogDotRects(:,configLocs(thisLoc)));
        
    end
    
    displayTime = Screen('Flip', ptbWindow);
    response = 1;
    
    while response
    
        [responseTime, keyCode] = KbWait(-1,2);

        if find(keyCode) == 44      % Responded they have seen before

            recognition.allResponse(thisTrial) = 1;
            
            % Ask for confidence rating
            
            DrawFormattedText(ptbWindow, confidenceText, 'center', 'center', colour.text);
            confResponse = 1;
            
            while confResponse
                
                displayConfTime = Screen('Flip', ptbWindow);

                [confResponseTime, keyCode] = KbWait(-1,2);

                if find(keyCode) == 30 % | find(keyCode) == 97
                    
                    recognition.allConfidence(thisTrial) = 1;
                    confResponse = 0;
                    
                elseif find(keyCode) == 31 % | find(keyCode) == 98
                    
                    recognition.allConfidence(thisTrial) = 2;
                    confResponse = 0;
                    
                elseif find(keyCode) == 32 % | find(keyCode) == 99
                    
                    recognition.allConfidence(thisTrial) = 3;
                    confResponse = 0;
                    
                end
                
            end
            
            % Code correct

            if recognition.whichType(thisTrial) < 3

                recognition.allCorrect(thisTrial) = 1;

            elseif recognition.whichType(thisTrial) == 3

                recognition.allCorrect(thisTrial) = 0; 

            end
            
            response = 0;

        elseif find(keyCode) == 225 | find(keyCode) == 229

            DrawFormattedText(ptbWindow, confidenceText, 'center', 'center', colour.text);
            confResponse = 1;
            
            while confResponse
                
                displayConfTime = Screen('Flip', ptbWindow);

                [confResponseTime, keyCode] = KbWait(-1,2);

                if find(keyCode) == 30 % | find(keyCode) == 97
                    
                    recognition.allConfidence(thisTrial) = 1;
                    confResponse = 0;
                    
                elseif find(keyCode) == 31 % | find(keyCode) == 98
                    
                    recognition.allConfidence(thisTrial) = 2;
                    confResponse = 0;
                    
                elseif find(keyCode) == 32 % | find(keyCode) == 99
                    
                    recognition.allConfidence(thisTrial) = 3;
                    confResponse = 0;
                    
                end
                
            end
            
            recognition.allResponse(thisTrial) = 0;

            if recognition.whichType(thisTrial) < 3

                recognition.allCorrect(thisTrial) = 0;

            elseif recognition.whichType(thisTrial) == 3

                recognition.allCorrect(thisTrial) = 1;

            end
            
            response = 0;

        end
        
    end
    
    recognition.allRT(thisTrial) = responseTime-displayTime;
    Screen('Flip', ptbWindow);
    
end

% Save results of recognition test to user data file
cd(userDir);
save(participant.userFile, 'participant', 'experiment', 'equipment', 'colour', 'stimulus', 'timing', 'recognition');

% ======================================================================= %

% Explicit Knowledge Test Starts Here

% ======================================================================= %

explicitQueryText = ['Did you notice that certain configurations of stimuli were being repeated from block to block?\n\n' ...
    'Press SPACE to indicate YES.\n\n\n' ...
    'Press SHIFT to indicate NO.'];

DrawFormattedText(ptbWindow, explicitQueryText, 'center', 'center', colour.text);
Screen('Flip', ptbWindow);
[~, keyCode] = KbWait(-1,2);  

if find(keyCode) == 44          % 'Space'

    participant.aware = 1;      % Participant was aware

elseif find(keyCode) == 225 | find(keyCode) == 229      % 'Shift'

    participant.aware = 0;      % Participant was unaware
    
end

flag = 0;

if participant.aware == 1
    
    ShowCursor(0);
    explicitTest = 1;
    configCounter = 1;
    
    % Set all locations to off
    clickedLocs = zeros(1,stimulus.nLocations);
    
    while explicitTest
    
        explicitTestText = ['Please click in the configurations you noticed were repeated.\n\n' ...
            'Press SPACE to submit each configuration.\n\n' ...
            'Press SHIFT to change your answer.\n\n' ...
            'Click and press TAB if you do not remember any more repeated configurations.'];
        DrawFormattedText(ptbWindow, explicitTestText, 'center', 200, colour.text);
            
        % Draw grid in middle of screen
        Screen('FrameRect', ptbWindow, colour.white, recogGridRects);

        for thisLoc = 1:stimulus.nLocations

            if clickedLocs(thisLoc) == 1

                Screen('FillOval', ptbWindow, colour.dot, recogDotRects(:,thisLoc));

            end

        end

        if sum(clickedLocs) == stimulus.nItems

                canSubmit = 1;
                DrawFormattedText(ptbWindow, submitText, 'center', 800, colour.text);
                Screen('Flip', ptbWindow);

                while canSubmit

                    [keyIsDown, secs, keyCode] = KbCheck(-1,2);

                    if find(keyCode) == 44          % 'Space'

                        % Configuration submitted. Save response
                        explicit.allResponses(configCounter,:) = find(clickedLocs);
                        configCounter = configCounter+1;
                        canSubmit = 0;
                        clickedLocs = zeros(1,stimulus.nLocations); 

                    elseif find(keyCode) == 160 | find(keyCode) == 161

                        canSubmit = 0;
                        clickedLocs(lastClickedLoc) = 0;

                     end        

                end

        else

            Screen('Flip', ptbWindow);
            CheckResponse = zeros(1,stimulus.nLocations);

            while ~any(CheckResponse)
                
                [~,~,keyCode] = KbCheck(-1);
                if find(keyCode) == 9
                    
                    explicitTest = 0;
                    flag = 1;
                    break

                end
                
                [~,xClickResponse,yClickResponse] = GetClicks(ptbWindow,0);     % Retrieves x- and y-coordinates of mouse click
                clickSecs = GetSecs;

                for thisLoc = 1:stimulus.nLocations;

                    CheckResponse(thisLoc) = IsInRect(xClickResponse,yClickResponse,recogGridRects(:,thisLoc));     % Tests if mouse click is inside aperture of each successive item

                end

            end

            responseLoc = find(CheckResponse);
            lastClickedLoc = responseLoc;
            clickedLocs(responseLoc) = 1 - clickedLocs(responseLoc);    % Switch off to on or on to off

        end   
         
        if flag
            
            break
            
        end
        
    end 
            
end                   
                        
% Save results of recognition test to user data file
cd(userDir);
save(participant.userFile, 'participant', 'experiment', 'equipment', 'colour', 'stimulus', 'timing', 'recognition', 'explicit');
        
% Pack up and go home
completedText = ['You have completed the experiment. Thank you!'];
DrawFormattedText(ptbWindow, completedText, 'center', 'center', colour.text);
Screen('Flip', ptbWindow);
WaitSecs(.5);
KbWait(-1,2);

Screen('CloseAll');
close all;



