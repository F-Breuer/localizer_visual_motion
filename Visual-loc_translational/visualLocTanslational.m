%% Visual hMT localizer using translational motion in four directions
%  (up- down- left and right-ward)

% by Mohamed Rezk 2018
% adapted by MarcoB and RemiG 2020


% % % Different duratons for different number of repetitions (may add a few TRs to this number just for safety)
% % % Cfg.numRepetitions=7, Duration: 345.77 secs (5.76 mins), collect 139 + 4 Triggers = 143 TRs at least per run
% % % Cfg.numRepetitions=6, Duration: 297.86 secs (4.96 mins), collect 120 + 4 Triggers = 124 TRs at least per run
% % % Cfg.numRepetitions=5, Duration: 249.91 secs (4.17 mins), collect 100 + 4 Triggers = 104 TRs at least per run
% % % Cfg.numRepetitions=4, Duration: 201.91 secs (3.37 mins), collect 81 + 4 Triggers  = 85  TRs at least per run

%%

% Clear all the previous stuff
% clc; clear;
if ~ismac
    close all;
    clear Screen;
end

% make sure we got access to all the required functions and inputs
addpath(genpath(fullfile(pwd, 'subfun')))

[ExpParameters, Cfg] = setParameters;

% set and load all the parameters to run the experiment
[subjectName, runNumber, sessionNumber] = userInputs(Cfg);


%%  Experiment

% Safety loop: close the screen if code crashes
try
    %% Init the experiment
    [Cfg] = initPTB(Cfg);
    
    % Convert some values from degrees to pixels
    Cfg = deg2Pix('diameterAperture', Cfg, Cfg);
    ExpParameters = deg2Pix('dotSize', ExpParameters, Cfg);
    
    if Cfg.eyeTracker
        [el] = eyeTracker(Cfg, ExpParameters, subjectName, sessionNumber, runNumber, 'Calibration');
    end
    
    % % % REFACTOR THIS FUNCTION
    [ExpParameters] = expDesign(ExpParameters);
    % % %

    % Empty vectors and matrices for speed
    
    % % %     blockNames     = cell(ExpParameters.numBlocks,1);
    logFile.blockOnsets    = zeros(ExpParameters.numBlocks, 1);
    logFile.blockEnds      = zeros(ExpParameters.numBlocks, 1);
    logFile.blockDurations = zeros(ExpParameters.numBlocks, 1);
    
    logFile.eventOnsets    = zeros(ExpParameters.numBlocks, ExpParameters.numEventsPerBlock);
    logFile.eventEnds      = zeros(ExpParameters.numBlocks, ExpParameters.numEventsPerBlock);
    logFile.eventDurations = zeros(ExpParameters.numBlocks, ExpParameters.numEventsPerBlock);
    
    logFile.allResponses = [] ;
    
    % Prepare for the output logfiles
    logFile = saveOutput(subjectName, logFile, ExpParameters, 'open');
    
    
    
    
    % % % PUT IT RIGHT BEFORE STARTING THE EXPERIMENT
    % Show instructions
    if ExpParameters.Task1
        DrawFormattedText(Cfg.win,ExpParameters.TaskInstruction,...
            'center', 'center', Cfg.textColor);
        Screen('Flip', Cfg.win);
    end
    % % %
    
    
    
    
    % Prepare for fixation Cross
    if ExpParameters.Task1
        Cfg.xCoords = [-ExpParameters.fixCrossDimPix ExpParameters.fixCrossDimPix 0 0] + ExpParameters.xDisplacementFixCross;
        Cfg.yCoords = [0 0 -ExpParameters.fixCrossDimPix ExpParameters.fixCrossDimPix] + ExpParameters.yDisplacementFixCross;
        Cfg.allCoords = [Cfg.xCoords; Cfg.yCoords];
    end
    
    % Wait for space key to be pressed
    pressSpace4me
    
    getResponse('init', Cfg, ExpParameters, 1);

    getResponse('start', Cfg, ExpParameters, 1);
    
    
    % Wait for Trigger from Scanner
    wait4Trigger(Cfg)
    
    % Show the fixation cross
    if ExpParameters.Task1
        drawFixationCross(Cfg, ExpParameters, ExpParameters.fixationCrossColor)
        Screen('Flip',Cfg.win);
    end
    
    %% Experiment Start
    Cfg.experimentStart = GetSecs;
    
    WaitSecs(ExpParameters.onsetDelay);
    
    %% For Each Block
    for iBlock = 1:ExpParameters.numBlocks
        
        fprintf('\n - Running Block %.0f \n',iBlock)
        
        logFile.blockOnsets(iBlock,1)= GetSecs-Cfg.experimentStart;
        
        if Cfg.eyeTracker
            [el] = eyeTracker(Cfg, ExpParameters, subjectName, sessionNumber, runNumber, 'StartRecording');
        end
        
        % For each event in the block
        for iEventsPerBlock = 1:ExpParameters.numEventsPerBlock
              
            
            % Check for experiment abortion from operator
            [keyIsDown, ~, keyCode] = KbCheck(Cfg.keyboard);
            if (keyIsDown==1 && keyCode(Cfg.escapeKey))
                break;
            end
            
            
            
            
            % Direction of that event
            logFile.iEventDirection = ExpParameters.designDirections(iBlock,iEventsPerBlock); 
            % Speed of that event
            logFile.iEventSpeed = ExpParameters.designSpeeds(iBlock,iEventsPerBlock);               
            
            
            % % % initially an input for DoDotMo func, now from
            % ExpParameters.eventDuration, to be tested
            % DODOTMO
            iEventDuration = ExpParameters.eventDuration ;                        % Duration of normal events
            % % %
            logFile.iEventIsFixationTarget = ExpParameters.designFixationTargets(iBlock,iEventsPerBlock);
            
            % Event Onset
            logFile.eventOnsets(iBlock,iEventsPerBlock) = GetSecs-Cfg.experimentStart;

            
            % % % REFACTORE
            % play the dots
            doDotMo(Cfg, ExpParameters, logFile);
            

            %% logfile for responses
            
            responseEvents = getResponse('check', Cfg, ExpParameters);

            % concatenate the new event responses with the old responses vector
%             logFile.allResponses = [logFile.allResponses responseTimeWithinEvent];
                

                
            %% Event End and Duration
            logFile.eventEnds(iBlock,iEventsPerBlock) = GetSecs-Cfg.experimentStart;
            logFile.eventDurations(iBlock,iEventsPerBlock) = logFile.eventEnds(iBlock,iEventsPerBlock) - logFile.eventOnsets(iBlock,iEventsPerBlock);
            


            
            % Save the events txt logfile
            logFile = saveOutput(subjectName, logFile, ExpParameters, 'save Events', iBlock, iEventsPerBlock);
            
            
            % wait for the inter-stimulus interval
            WaitSecs(ExpParameters.ISI);
            
            
            getResponse('flush', Cfg, ExpParameters);
            
            
        end
        
        if Cfg.eyeTracker
            [el] = eyeTracker(Cfg, ExpParameters, subjectName, sessionNumber, runNumber, 'StopRecordings');
        end
        
        logFile.blockEnds(iBlock,1)= GetSecs-Cfg.experimentStart;          % End of the block Time
        logFile.blockDurations(iBlock,1)= logFile.blockEnds(iBlock,1) - logFile.blockOnsets(iBlock,1); % Block Duration
        
        
        WaitSecs(ExpParameters.IBI);
        
        % % % NEED TO ASSIGN THE TXT VARIABLE IN A STRUCTURE
        % Save the block txt Logfile
        logFile = saveOutput(subjectName, logFile, ExpParameters, ...
            'save Blocks', iBlock, iEventsPerBlock);
        % % %
        
    end
    
    % % % HERE needed for saving single vars, is it needed?
    blockNames = ExpParameters.designBlockNames ;
    blockDurations = logFile.blockDurations;
    blockOnsets = logFile.blockOnsets;
    
    % % %
    
    % End of the run for the BOLD to go down
    WaitSecs(ExpParameters.endDelay);
    
    % Close the logfiles
    logFile = saveOutput(subjectName, logFile, ExpParameters, 'close');
    
    
    TotalExperimentTime = GetSecs-Cfg.experimentStart;
    
    %% Save mat log files
    % % % ADD SESSION AND RUN NUMBER
    save(fullfile('logfiles',[subjectName,'_all.mat']))
    
    % % %     % % % CANNOT FIND THE VAR BLOCKDURATION
    % % %     save(fullfile('logfiles',[subjectName,'.mat']),...
    % % %         'Cfg', ...
    % % %         'allResponses', ...
    % % %         'blockDurations', ...
    % % %         'blockNames', ...
    % % %         'blockOnsets')
    % % %     % % %
    
    if Cfg.eyeTracker
        [el] = eyeTracker(Cfg, ExpParameters, subjectName, sessionNumber, runNumber, 'Shutdown');
    end
    
    getResponse('stop', Cfg, ExpParameters, 1);
    
    
    cleanUp()
    
catch
    
    cleanUp()
    psychrethrow(psychlasterror);
    
end

