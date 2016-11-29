function PTB_Fischer()
codeVersion = '0.9.9';

% --- DO NOT CHANGE -- %
skipVercheck = 0; % 1 = check matlab and octave versions
skipSyncTests = 0; % 1 = skip video sync tests. ALWAYS set to 0
devMode = 0; % set development flag
% --- END --- %


global ME

% make sure the keyboard is setup correctly.
[keyboardIndices, productNames, ~] = GetKeyboardIndices;
for ki = 1 : length(productNames)
    useKeyboard = input(['Would you like to use ' productNames{ki} ' (y/n)? '],'s');
    if strcmpi(useKeyboard(1),'y')
        keyboardToUse = keyboardIndices(ki);
        break
    end
end

if ~exist('keyboardToUse','var')
    error('please select a keyboard to use')
end

rand('seed',now); %#ok<RAND> for compatiblity with OCTAVE

thePath = [cd filesep];


% check if matlab or octave

verStruct = ver;
isMatlab = sum(ismember(vertcat({verStruct.Name})','MATLAB'));
isOctave = sum(ismember(vertcat({verStruct.Name})','Octave'));
% collect some system variables
systemParams.matlabVersion = verStruct;
[~, ptbVersion] = PsychtoolboxVersion;
systemParams.ptbVersion =  ptbVersion;
systemParams.systemType = computer;
if ismac
    [~, OSversion] = system('sw_vers');
end

try
    if ispc
        [~, OSversion] = system('ver');
    end
catch
end


systemParams.OSversion = OSversion;

if isMatlab == 1 && isOctave == 1 || isMatlab == 0 && isOctave == 0
    error('Can not determine whether you are using matlab or octave')
end





if devMode == 1
    warning('Development mode is ON! Turn it off unless you know what you are doing')
    warning('press q to end the experiment early')
end

% check the matlab version and PTB version
if skipVercheck == 0
    % Matlab / Octave version
    if isMatlab == 1
        [~, matlabdate] = version;
        if str2double(datestr(matlabdate,'YYYY')) < 2013
            error('Currently only tested with Matlab 2013 or later')
        end
    elseif isOctave == 1
        if strcmp(version,'4.0.3') ~= 1
            error('Currently only tested with Octave versionb 4.0.3')
        end
    end
    
    [~, versionStructure] = PsychtoolboxVersion;
    
    % PTB version
    if versionStructure.major == 3 && versionStructure.point < 12
        errror('Current only tested with PTB version 3.0.12 or later')
    end
end

if exist([thePath  'ptb_fischer_rep.m'],'file') == 0
    error('Please make sure you are in the same folder as ptb_fischer_rep.m')
end

try
    
    Screen('Preference', 'SkipSyncTests', skipSyncTests);
    ListenChar(0)
    startTimeMarker = now;
    
    paramsfile = [thePath 'Params.mat'];
    
    if exist(paramsfile,'file') == 2
        A = load(paramsfile);
        params = A.params;
        disp('loading the parameters file...');
    else
        error('Params.mat not found. Please run the calibration script (Calibrate.m)')
    end
    
    %----------------------------------------------------------------------
    %       Pre-experiment setup
    %----------------------------------------------------------------------
    tooQuickText = 'Too quick!\n\nPlease wait until the target appears in a box before pressing SPACE.';
    tooSlowText = 'Too slow!\n\nPlease press SPACE as soon as the target appears.';
    
    clc
    disp(['Please ensure that the participant is placed EXACTLY ' ...
        num2str(params.viewingDistance) 'cm away from the monitor']);
    disp('Proceed once checking is complete...');
    cont = input(['Type YES to confirm that the participant is ' ...
        num2str(params.viewingDistance) 'cm away from the monitor... '],'s');
    if ~strcmpi(cont,'yes')
        error('Please restart the program!')
    end
    
    subCode = input('What is the subject code? ','s');
    
    KbName('UnifyKeyNames')
    
    
    KbName('UnifyKeyNames'); %used for cross-platform compatibility of keynaming
    keys = KbName('space');
    keyList = zeros(1,256);
    keyList(keys) = 1;
    keys = KbName('q');
    keyList(keys) = 1;
    
    
    
    
    device = keyboardToUse;
    
    
    KbQueueCreate(device,keyList);
    
    % set parameters for the experiment
    % --
    % n trials, delays, etc
    nTrialsPerBlock = 160;
    nBlocks = 5;
    delays = [250 500 750 1000];
    percentCatch = 20;
    nTargetLocations = 2;
    digits = [1 2 8 9];
    targetSize = .7;
    digitSizeDeg = .75;
    % -- %
    
    
    % calcualte the correct fontsize
    digitSizeFontHeight = find(arrayfun(@(x) (x/params.pixPerDegHeight), params.fontSize(:,2)) <= digitSizeDeg, 1, 'last' );
    digitSizeFont  = digitSizeFontHeight;
    
    
    boxOffsetDeg = 5;
    boxHeight = 1;
    boxWidth = 1;
    fixationDiameterDeg = 0.2;
    initDisplay = 500; %ms
    
    digitDisplay = 300; %ms
    
    timeOut = 1000; %ms
    
    iti = 1000; % ms
    
    nDelays = length(delays);
    percentEachSide = (100 - percentCatch) / nTargetLocations;
    
    percentLeft = percentEachSide;
    percentRight =  percentLeft;
    
    leftTargetAtEachDelay = ((nTrialsPerBlock / 100) * percentLeft) / nDelays;
    rigthtTargetAtEachDelay = ((nTrialsPerBlock / 100) * percentRight) / nDelays;
    
    targetDigits = arrayfun(@(x) repmat(x,1,leftTargetAtEachDelay/length(digits)),digits,'UniformOutput',false);
    targetDigits = horzcat(targetDigits{:});
    targetDigits = repmat(targetDigits,1,length(delays));
    
    catchAtEachDelay = ((nTrialsPerBlock / 100) * percentCatch) / nDelays;
    
    catchDigits = arrayfun(@(x) repmat(x,1,catchAtEachDelay/length(digits)),digits,'UniformOutput',false);
    catchDigits = horzcat(catchDigits{:});
    catchDigits = repmat(catchDigits,1,length(delays));
    
    % generate Target Trials
    leftTrials = arrayfun(@(d,y) [num2str(d) '.l.' num2str(y)],repmat(delays,1,leftTargetAtEachDelay), targetDigits,'UniformOutput',false);
    
    rightTrials = arrayfun(@(d,y) [num2str(d) '.r.' num2str(y)],repmat(delays,1,rigthtTargetAtEachDelay), targetDigits,'UniformOutput',false);
    
    % generate Catch Trial
    catchTrials = arrayfun(@(d,y) [num2str(d) '.c.' num2str(y)],repmat(delays,1,catchAtEachDelay), catchDigits, 'UniformOutput',false);
    
    % combine Catch & Target Trials
    allTrials = [catchTrials rightTrials leftTrials];
    % shuffle Trials
    shuffledTrials = allTrials(randperm(nTrialsPerBlock,nTrialsPerBlock));
    targetType = cellfun(@(x) x(end-2:end-2),shuffledTrials,'UniformOutput',false);
    delayDur = cellfun(@(x) str2double(x(1:end-4)),shuffledTrials,'UniformOutput',false);
    cueDigit =  cellfun(@(x) str2double(x(end)),shuffledTrials,'UniformOutput',false);
    trialNum = arrayfun(@(x) {x},1:nTrialsPerBlock);
    trialStructPerBlock = cell2struct([trialNum; targetType; delayDur; cueDigit],{'trialNum'; 'targetType'; 'delayDur'; 'cue'});
    
    trialStruct = cell(1,nBlocks);
    
    
    
    
    
    
    
    
    
    for b = 1 : nBlocks
        trialStruct{b} = trialStructPerBlock(randperm(nTrialsPerBlock,nTrialsPerBlock));
    end
    %clear b;
    trialStruct = vertcat(trialStruct{:});
    
    HideCursor
    waitframes = 1;
    
    % Here we call some default settings for setting up Psychtoolbox
    PsychDefaultSetup(2);
    
    % Get the screen numbers
    screens = Screen('Screens');
    
    % Draw to the external screen if avaliable
    screenNumber = min(screens);
    
    % Define black and white
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    
    % Open an on screen window
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
    
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    
    if screenXpixels < 1024 && screenYpixels < 768
        error('Your screen is very small. The text may not display correctly. Either make the adjustments yourself, or email lincoln@colling.net.nz for help')
    end
    
    ifi = Screen('GetFlipInterval', window);
    
    topPriorityLevel = MaxPriority(window);
    
    ListenChar(2); %makes it so characters typed don?t show up in the command window
    
    
    instructions;
    
    Screen('FillRect', window, [0 0 0]); % this blanks the screen
    Screen('Flip', window);
    
    %-----------------------------------------------------------------------
    
    % Measure the vertical refresh rate of the monitor
    
    [~,initDisplayFrames] = Time2Frames(initDisplay,ifi);
    [~,digitDisplayFrames] = Time2Frames(digitDisplay,ifi);
    baseOval = [0 0  round(params.pixPerDegWidth * targetSize)  round(params.pixPerDegWidth * targetSize)];
    maxDiameter = max(baseOval) * 1.01;
    
    
    %----------------------------------------------------------------------
    %                       Experimental loop
    %----------------------------------------------------------------------
    
    responseStruct = struct;
    trialsStart = now;
    
    t = 1;
    
    % for testing
    % trialTable = struct2table(trialStruct);
    % trialStruct = trialStruct(ismember(trialTable.targetType,'c'));
    
    Priority(topPriorityLevel);
    while t < length(trialStruct) + 1
        
        
        if devMode == 1
            t = length(trialStruct);
        end
        
        thekey = '';
        
        breaks = (nTrialsPerBlock:nTrialsPerBlock:length(trialStruct) + 1);
        breaks = breaks + 1;
        
        if sum(t == breaks) == 1
            KbQueueCreate(device,keyList);
            % ---- %
            disp('reached the end of the block')
            % pause at the end of a block!
            Screen('TextSize',window,24);
            DrawFormattedText(window, 'You have reached the end of the block. You can take a break if you want.  Press SPACE to continue', 'center', 'center', [1 1 1], 40, [], [], 2);
            Screen('Flip', window);
            KbQueueStart(device);
            startCount = GetSecs;
            
            pressed = 0;
            while pressed == 0
                [ pressed, firstPress] = KbQueueCheck(device);
                if devMode == 1
                    if (GetSecs - startCount > 0) == 1
                        pressed = 1;
                    end
                end
            end
            
            clear pressed
            clear firstPress
            KbQueueStop(device)
            KbQueueFlush(device);
            
            
            % ---- %
        end
        
        
        
        
        
        
        KbQueueCreate(device,keyList);
        
        
        
        
        if devMode == 1
            iti = 1;
        end
        WaitSecs(iti/1000);
        KbQueueFlush(device);
        KbQueueStart(device);
        
        
        early = 0;
        
        
        delay = trialStruct(t).delayDur;
        if devMode == 1
            delay = 50;
        end
        [~,delayFrames] = Time2Frames(delay,ifi);
        currentDigit = num2str(trialStruct(t).cue);
        
        targetLocation =  trialStruct(t).targetType;
        
        
        if strcmp(targetLocation,'l')
            sideIndex = 1;
        elseif strcmp(targetLocation,'r')
            sideIndex = 2;
        else
            sideIndex = 0;
        end
        
        
        
        [xCenter, yCenter] = RectCenter(windowRect);
        
        fixationColor = white;
        fixationDiameterPix = params.pixPerDegWidth * fixationDiameterDeg;
        
        
        % Get the centre coordinate of the window
        [xCenter, yCenter] = RectCenter(windowRect);
        
        % Make a base Rect of 1 by 1 deg
        baseRectHeight = ceil(boxHeight * params.pixPerDegHeight);
        baseRectWidth = ceil(boxWidth * params.pixPerDegWidth);
        baseRect = [0 0 baseRectHeight baseRectWidth];
        
        % Screen X positions of the two boxes
        centreXPos = screenXpixels * 0.5;
        
        centreBoxLeft = centreXPos - (params.pixPerDegWidth * boxOffsetDeg) ;
        centreBoxRight = centreXPos + (params.pixPerDegWidth * boxOffsetDeg);
        
        squareXpos = [centreBoxLeft centreBoxRight];
        numSqaures = length(squareXpos);
        
        % Set the colors to Red during development
        allColors = [1 1; 1 1; 1 1  ];
        
        % Make our rectangle coordinates
        allRects = nan(4, numSqaures);
        
        for ns = 1:numSqaures
            allRects(:, ns) = CenterRectOnPointd(baseRect, squareXpos(ns), yCenter);
        end
        
        penWidthPixels = 2;
        fixationDiameterPix = round(params.pixPerDegWidth * fixationDiameterDeg);
        % % show the fixation for set period
        % Draw the rect to the screen
        Screen('FrameRect', window, allColors, allRects,penWidthPixels);
        
        %% draw the fixation
        Screen('DrawDots', window, [xCenter; yCenter], fixationDiameterPix, white, [], 2);
        
        Priority(topPriorityLevel);
        vbl = Screen('Flip', window);
        % now keep the fixation on for 'initDisplay' ms
        
        KbQueueStart(device);
        if early == 0
            for frame = 1 : (initDisplayFrames - 1)
                
                [early,firstPress] = KbQueueCheck(device);
                Screen('DrawDots', window, [xCenter; yCenter], fixationDiameterPix, fixationColor, [], 2);
                Screen('FrameRect', window, allColors, allRects,penWidthPixels);
                if early == 1
                    break
                end
                
                vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            end
        end
        %% display the digit
        
        Screen('FrameRect', window, allColors, allRects,penWidthPixels);
        Screen('TextSize',window,digitSizeFont);
        DrawFormattedText(window, currentDigit, 'center', 'center', [1 1 1]);
        vbl = Screen('Flip',window);
        digitOnTime = GetSecs;
        if early == 0
            for frame = 1 : digitDisplayFrames - 1
                [early, firstPress] = KbQueueCheck(device);
                if early == 1
                    break;
                end
                Screen('FrameRect', window, allColors, allRects,penWidthPixels);
                DrawFormattedText(window, currentDigit, 'center', 'center', [1 1 1] );
                vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            end
        end
        
        %% draw the fixation again with variable delay
        Screen('DrawDots', window, [xCenter; yCenter], fixationDiameterPix, white, [], 2);
        Screen('FrameRect', window, allColors, allRects,penWidthPixels);
        
        
        vbl = Screen('Flip', window);
        
        
        if early == 0
            for frame = 1 : delayFrames - 1
                [early, firstPress] = KbQueueCheck(device);
                Screen('DrawDots', window, [xCenter; yCenter], fixationDiameterPix, fixationColor, [], 2);
                Screen('FrameRect', window, allColors, allRects,penWidthPixels);
                if early == 1
                    break;
                end
                vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            end
            
        end
        
        
        
        if early == 0
            %% display the target in the target location
            % creates queue using defaults
            
            
            
            KbQueueStart(device);
            KbQueueFlush(device);
            
            Screen('DrawDots', window, [xCenter; yCenter], fixationDiameterPix, white, [], 2);
            Screen('FrameRect', window, allColors, allRects,penWidthPixels);
            
            if sideIndex ~= 0
                
                
                centreOval = CenterRectOnPointd(baseOval, squareXpos(sideIndex), yCenter);
                Screen('FillOval', window, white, centreOval, maxDiameter);
                targetOnTime = GetSecs;
                
            end
            
            
            clear startTime;
            startTime = Screen('Flip', window);
            clear pressed
            clear firstPress
            
            if sideIndex == 0
                pressed = 0;
                
                while pressed == 0
                    [ pressed, firstPress] = KbQueueCheck(device); %  check if any key was pressed
                    
                    if devMode == 1
                        timeOut = 0;
                    end
                    if (GetSecs - digitOnTime) > (timeOut / 1000)
                        pressed = 2;
                    end
                    
                end
            else
                pressed = 0;
                
                while pressed == 0
                    [ pressed, firstPress] = KbQueueCheck(device); %  check if any key was pressed.
                    
                    if (GetSecs - targetOnTime) > (timeOut / 1000)
                        pressed = 3;
                        firstPress = zeros(1,256);
                        firstPress(KbName('space')) = GetSecs;
                    end
                end
            end
            
            
            
            if pressed  == 1  % if key was pressed do the following
                firstPress(firstPress==0)=NaN; %little trick to get rid of 0s
                [endtime, Index]=min(firstPress); % gets the RT of the first key-press and its ID
                thekey=KbName(Index); %converts KeyID to keyname
                
                if strcmp(thekey,'q') == 1
                    error('quit early')
                end
                RT = endtime-startTime; %makes feedback string
                correct = 1;
                
            elseif pressed == 2 % if timed out on catch trial do the following
                RT = 0;
                thekey = 'nr';
                correct = 1;
            elseif pressed == 3 % if timed out on target trial do the following
                RT = 0;
                thekey = 'nr';
                correct = 0;
                slow = 1;
            end
            
            
            clear pressed
            clear firstPress
            KbQueueStop(device);
            KbQueueFlush(device);
            responseStruct(t).RT = RT;
            responseStruct(t).thekey = thekey;
            responseStruct(t).correct = correct;
            responseStruct(t).targetLocation = trialStruct(t).targetType;
            responseStruct(t).cue = trialStruct(t).cue;
            responseStruct(t).delayDur =  trialStruct(t).delayDur;
            Screen(window, 'FillRect', [0 0 0]); % this blanks the screen
            if correct == 0 && slow ~= 1
                DrawFormattedText(window, tooQuickText, 'center', 'center', [1 1 1], 80);
                pauseTime = .5;
                if devMode == 1
                    pauseTime = .1;
                end
                WaitSecs(pauseTime);
            elseif correct == 0 && slow == 1
                DrawFormattedText(window, tooSlowText, 'center', 'center', [1 1 1], 80);
                pauseTime = .5;
                if devMode == 1
                    pauseTime = .1;
                end
                WaitSecs(pauseTime);
            end
            Screen('Flip', window);
            
            clear slow
            t = t + 1;
        elseif early == 1
            
            Screen(window, 'FillRect', [0 0 0]); % this blanks the screen
            DrawFormattedText(window, tooQuickText, 'center', 'center', [1 1 1], 80);
            Screen('Flip', window);
            WaitSecs(1);
            Screen(window, 'FillRect', [0 0 0]); % this blanks the screen
            responseStruct(t).RT = 0;
            responseStruct(t).thekey = thekey;
            responseStruct(t).correct = 0;
            responseStruct(t).targetLocation = trialStruct(t).targetType;
            responseStruct(t).cue = trialStruct(t).cue;
            responseStruct(t).delayDur =  trialStruct(t).delayDur;
            t = t + 1;
        end
        clear pressed;
        clear firstPress
        clear early
        KbQueueStop(device);
        KbQueueFlush(device);
        
    end
    
    trialsEnd = now;
    % present a blank screen
    
    subjectDataFile = [thePath subCode '_data.mat'];
    params.subCode = subCode;
    
    
    endTimeMarker = now;
    timings = struct;
    timings.startTime = startTimeMarker;
    timings.endTime = endTimeMarker;
    timings.trialsStart = trialsStart;
    timings.trialsEnd = trialsEnd; %#ok<STRNU>
    systemParams.codeVersion = codeVersion;
    
    
    Screen('TextSize',window,24);
    DrawFormattedText(window, 'The experiment is finished.\nPlease alert the experimenter before proceeding\nPress SPACE to continue', 'center', 'center', [1 1 1], 90,[],[],2);
    Screen('Flip', window);
    presstogo
    ShowCursor;
    
    
    
    [mathTestScore, mathTestReponse] = math_test;
    
    handed = getHandedness();
    ListenChar(0); %makes it so characters typed do show up in the command window
    
    sca;
    clc;
    WaitSecs(.1);
    clc;
    WaitSecs(.2);
    clc;
    ok = 0;
    while ok == 0
        lang = getLanguageDetails;
        if lang >= 1 && lang <= 3;
            ok = 1;
        end
    end
    
    age = input('What is your age? ');
    
    
    save(subjectDataFile,'responseStruct','trialStruct','timings','params','handed','lang','age','systemParams',...
        'mathTestScore','mathTestReponse','-mat');
catch ME
    sca;
    ListenChar(0); %makes it so characters typed do show up in the command window
    warning(ME.message)
    if strcmp(ME.message,'quit early') == 0
        
        % now package the current state of the workspace
        
        workspaceVars = whos;
        workspaceVars = horzcat({workspaceVars(:).name});
        workspaceVars = workspaceVars(~ismember(workspaceVars,'workspaceVars'));
        workspaceVars = workspaceVars(~ismember(workspaceVars,'ans'));
        workspaceData = struct;
        for cc = 1:length(workspaceVars)
            currentVar = workspaceVars{cc};
            try
                workspaceData.(currentVar) = eval( currentVar );
            catch
            end
        end
        
        ProduceErrorLog(workspaceData);
    end
end


% The following are a series of helper functions

    function screenparams
        [xCenter, yCenter] = RectCenter(windowRect);
        % paramater
        fixationColor = white;  % parameter
        fixationDiameterPix = params.pixPerDegWidth * fixationDiameterDeg;
        
        
        
        [screenXpixels, ~] = Screen('WindowSize', window);
        
        % Get the centre coordinate of the window
        [xCenter, yCenter] = RectCenter(windowRect);
        
        % Make a base Rect of 1 by 1 deg
        baseRectHeight = ceil(boxHeight * params.pixPerDegHeight);
        baseRectWidth = ceil(boxWidth * params.pixPerDegWidth);
        baseRect = [0 0 baseRectHeight baseRectWidth];
        
        % Screen X positions of the two boxes
        centreXPos = screenXpixels * 0.5;
        
        centreBoxLeft = centreXPos - (params.pixPerDegWidth * boxOffsetDeg) ;
        centreBoxRight = centreXPos + (params.pixPerDegWidth * boxOffsetDeg);
        
        squareXpos = [centreBoxLeft centreBoxRight];
        numSqaures = length(squareXpos);
        
        % Set the colors to Red during development
        allColors = [1 1; 1 1; 1 1  ];
        
        % Make our rectangle coordinates
        allRects = nan(4, numSqaures);
        for i = 1:numSqaures
            allRects(:, i) = CenterRectOnPointd(baseRect, squareXpos(i), yCenter);
        end
        
        penWidthPixels = 2;
        fixationDiameterPix = round(params.pixPerDegWidth * fixationDiameterDeg);
    end


    function instructions
        %setupkeyboard
        %
        Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        screenparams
        
        Screen('TextSize',window,24);
        DrawFormattedText(window, ['\nYour task is to press [space] as soon as you see a white circle appear in either the left or the right box on the screen.'...
            '\n\nPlease try to keep your eyes fixed on the white spot in the middle of the screen and try not to move your eyes around.'...
            '\nAn example of the fixation point and the boxes is shown on screen'...
            '\nPress [SPACE] one you understand the instructions.'], 'center', 0, [1 1 1], 80,[],[],2);
        
        
        Screen('DrawDots', window, [xCenter; yCenter], fixationDiameterPix, white, [], 2);
        Screen('FrameRect', window, allColors, allRects,penWidthPixels);
        
        Screen('Flip', window);
        presstogo
        
        DrawFormattedText(window,['Before the target appears you will see a number that appears in the same place as the fixation point. This number is not relavent to your task and it won''t help you predict when and where the target will appear.'...
            '\n\nFeel free to take breaks when prompted. \n\n\nWhen you are done with the experiment please inform the experimenter.\n Press [SPACE] to start'], 'center','center',[1 1 1],80,[],[],2);
        
        Screen('Flip', window);
        presstogo
    end


    function presstogo
        KbQueueCreate(device,keyList);
        KbQueueStart(device)
        pressed = 0;
        while pressed == 0
            [ pressed, firstPress] = KbQueueCheck(device); %
        end
        KbQueueFlush(device);
        KbQueueRelease(device);
        KbQueueStop(device);
        clear pressed
        clear firstPress
    end


    function ProduceErrorLog(workspaceData)
        % collect some system variables
        workspaceData.matlabVersion = ver;
        [~, ptbVersion] = PsychtoolboxVersion;
        
        workspaceData.systemType = computer;
        if ismac
            [~, OSversion] = system('sw_vers');
        end
        
        try
            if ispc
                [~, OSversion] = system('ver');
            end
        catch
        end
        
        workspaceData.OSversion = OSversion;
        workspaceData.ptbVersion = ptbVersion;
        
        save([workspaceData.thePath 'errorlog.dat'],'workspaceData','-mat');
        
        
        disp('There was an error! Check above for any warnings messages');
        disp('If you do not know what went wrong then try running the code again');
        disp('If the problem persists please email the file: errorlog.dat to: lincoln@colling.net.nz');
        
    end

    function handed = getHandedness
        
       
        questions ={'With which hand do you write?';...
            'In which hand do you prefer to use a spoon when eating?';...
            'In which hand do you prefer to hold a toothbrush when cleaning your teeth?';...
            'In which hand do you hold a match when you strike it?';...
            'In which hand do you prefer to hold the rubber when erasing a pencil mark?';...
            'In which hand do you hold the needle when you are sewing?';...
            'When buttering bread, which hand holds the knife?';...
            'In which hand do you hold a hammer?';...
            'In which hand do you hold the peeler when peeling an apple?';...
            'Which hand do you use to draw?'};
        
        
        
        
        
        Screen('TextSize',window,24);
        DrawFormattedText(window, ['The ten questions that follow ask which hand you prefer to use in a number of different situations. Please click one box for each question, indicating whether you prefer to use the left-hand, either-hand, or the right-hand for that task. Only tick the EITHER box if one hand is truly no better than the other. Please answer all questions, and even if you have had little experience in a particular task, try imagining doing that task and select a response. Press [SPACE] to start.'], 'center', 'center', [1 1 1], 65,[],[],2);
        Screen('Flip', window);
        presstogo
        
        
        
        
        % Make a base Rect of 200 by 200 pixels
        baseRect = [0 0 200 200];
        
        % Screen X positions of our three rectangles
        squareXpos = [screenXpixels * 0.25 screenXpixels * 0.5 screenXpixels * 0.75];
        numSqaures = length(squareXpos);
        
        % Set the colors to Red, Green and Blue
        
        % Make our rectangle coordinates
        allRects = nan(4, 3);
        for i = 1:numSqaures
            allRects(:, i) = CenterRectOnPointd(baseRect, squareXpos(i), yCenter);
        end
        
        allColors = [1 0 0; 0 1 0; 0 0 1];
        
        % Define red and blue
        offSquare = [1 1 1]/10;
        onSquare = [1 1 1]/2;
        
        % Here we set the initial position of the mouse to be in the centre of the
        % screen
        SetMouse(xCenter, yCenter, window);
        
        % Sync us and get a time stamp
        vbl = Screen('Flip', window);
        waitframes = 1;
        
        % Maximum priority level
        topPriorityLevel = MaxPriority(window);
        Priority(topPriorityLevel);
        
        % Loop the animation until a key is pressed
        buttons = 0;
        Screen('TextFont', window, 'Ariel');
        Screen('TextSize', window, 30);
        [~, ~, textboundsleft] = DrawFormattedText(window, 'LEFT', sum(allRects([1 3],1))/2, sum(allRects([2 4],1))/2 , white);
        [~, ~, textboundscentre] = DrawFormattedText(window, 'EITHER', sum(allRects([1 3],2))/2, sum(allRects([2 4],2))/2 , white);
        [~, ~, textboundsright] = DrawFormattedText(window, 'RIGHT', sum(allRects([1 3],3))/2, sum(allRects([2 4],3))/2 , white);
        
        
        
        q = 1;
        buttons = 0;
        left = 0;
        centre = 0;
        right = 0;
        selected = 0;
        while q<=length(questions)
            
            clear buttons
            % Get the current position of the mouse
            [x, y, buttons] = GetMouse(window);
            
            % Center the rectangle on the centre of the screen
            
            % See if the mouse cursor is inside the square
            left = IsInRect(x, y, allRects(:,1));
            centre = IsInRect(x, y, allRects(:,2));
            right = IsInRect(x, y, allRects(:,3));
            
            if left == 1
                allColors(:,1) = onSquare;
            else
                allColors(:,1) = offSquare;
            end
            
            if centre == 1
                allColors(:,2) = onSquare;
            else
                allColors(:,2) = offSquare;
            end
            
            if right == 1
                allColors(:,3) = onSquare;
            else
                allColors(:,3) = offSquare;
            end
            
            
            
            Screen('FillRect', window, allColors, allRects)
            
            
            DrawFormattedText(window, questions{q}, 'center', yCenter-300, [1 1 1], 70, [], [], 2);
            
            
            DrawFormattedText(window, 'LEFT', (sum(allRects([1 3],1))/2) - diff(textboundsleft([1,3]))/2, (sum(allRects([2 4],1))/2) + (diff(textboundsleft([2,4]))/4) , white);
            DrawFormattedText(window, 'EITHER', (sum(allRects([1 3],2))/2) - diff(textboundscentre([1,3]))/2, (sum(allRects([2 4],2))/2) + (diff(textboundscentre([2,4]))/4) , white);
            DrawFormattedText(window, 'RIGHT', (sum(allRects([1 3],3))/2) - diff(textboundsright([1,3]))/2, (sum(allRects([2 4],3))/2) + (diff(textboundsright([2,4]))/4) , white);
            % Draw a white dot where the mouse is
            Screen('DrawDots', window, [x y], 10, white, [], 2);
            
            % Flip to the screen
            vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            
            if any(buttons) == 1 && (left ==1||right==1||centre==1)
                handed(q,:) = [left * -1 centre * 0 right];
                q = q + 1;
                left = 0;
                right = 0;
                centre= 0;
                clear buttons
                WaitSecs(.2);
            end
            
            
        end
        
        
    end
%%% change language details.
    function lang = getLanguageDetails
        clc
        disp('We would like to know a few details about the languages you read and write.')
        disp('Do you read or write any languages where the LETTERS and NUMBERS are written:')
        disp(' ')
        disp('1. EXCLUSIVELY from left to right (e.g., English, Dutch, German)')
        disp(' ')
        disp('2. NOT EXCLUSIVELY left to right (e.g., Arabic, Hebrew, Urdu)')
        disp(' ')
        disp('3. Any combination of the above')
        disp(' ')
        disp(' ')
        lang = input('Select 1 to 3: ');
        
        
        
    end

    function [score, responseStruct] = math_test
        
        
        %try
        questions =...
            {'6 + 1';...
            '2 + 4';...
            '3 - 2';...
            '5 - 2';...
            '3 - 1';...
            '5 - 1';...
            '9 + 7';...
            '17 - 9';...
            '89 - 18';...
            '5 x 3';...
            '8 ÷ 2';...
            '8 x 5';...
            '13 x 7';...
            '48 - 19';...
            '14 x 6';...
            '2/3 - 1/3';...
            '126 ÷ 42';...
            '288 ÷ 48';...
            '7/8 - 2/8';...
            '3250 / 25';...
            '2 3/4 + 4 1/8';...
            '1.05 x 0.2';...
            '-18 + 12';...
            '-6 x 7';...
            '4/7 ÷ 1/2'};
        
        level = reshape(ones(5,5) .* repmat([1 2 3 4 5],5,1),1,25);
        incorrectByLevel = zeros(5,1);
        orders = cell2mat(arrayfun(@(x) randperm(4,4),1:length(questions),'UniformOutput',false)');
        correct = zeros(length(questions),1);
        responses = zeros(length(questions),4);
        
        answers = {...
            '7','1','5','2';...
            '6','2','7','8';...
            '1','3','2','4';...
            '3','1','4','8';...
            '2','0','3','6';...
            '4','2','5','7';...
            '16','12','15','23';...
            '8','26','5','11';...
            '71','56','107','75';...
            '15','45','18','25';...
            '4','6','16','2';...
            '40','45','85','30';...
            '91','37','81','107';...
            '29','23','30','22';...
            '84','64','72','52';...
            '1/3','1/6','1/2','2/9';...
            '3','4','4 1/2','5';...
            '6','7','7 1/2','9';...
            '5/8','3/5','1 3/5','1/8';...
            '130','50','80','110';...
            '6 7/8','6 1/2','8 1/2','7 1/4';...
            '0.21','2.1','0.3','2.2';...
            '-6','6','-30','30';...
            '-42','45','-67','1';...
            '8/7','1 1/4','2/7','1/7'};
        
        
        
        
        
        %     Get the size of the on screen window
        [screenXpixels, screenYpixels] = Screen('WindowSize', window);
        
        [maxValue, ~, ~] = Screen('ColorRange', window);
        
        %    Query the frame duration
        ifi = Screen('GetFlipInterval', window);
        
        
        Screen('TextSize',window,24);
        DrawFormattedText(window, ['You will be presented with a few maths problems. Use the mouse to click on the correct answer. You have 30 seconds to answer each problem, so keep an eye on the timer in the corner. Only give your answer when you are sure.\nPress [SPACE] to start.'], 'center', 'center', white, 70,[],[],2);
        Screen('Flip', window);
        presstogo
        
        % Make a base Rect of 200 by 200 pixels
        baseRect = [0 0 200 200];
        
        % Screen X positions of our three rectangles
        squareXpos = [screenXpixels * 0.20 screenXpixels * 0.40  screenXpixels * 0.60 screenXpixels * 0.80];
        numSqaures = length(squareXpos);
        
        % Set the colors to Red, Green and Blue
        
        % Make our rectangle coordinates
        allRects = nan(4, 4);
        for i = 1:numSqaures
            allRects(:, i) = CenterRectOnPointd(baseRect, squareXpos(i), yCenter);
        end
        
        allColors = [0 0 0 0; 0 0 0 0; 0 0 0 0];
        
        
        % Define red and blue
        offSquare = white;%[1 0 0];
        onSquare = [0 maxValue 0];
        
        % Here we set the initial position of the mouse to be in the centre of the
        % screen
        SetMouse(xCenter, yCenter, window);
        
        
        % Loop the animation until a key is pressed
        buttons = 0;
        Screen('TextFont', window, 'Ariel');
        Screen('TextSize', window, 50);
        %[~, ~, textboundsleft] = DrawFormattedText(window, 'LEFT', sum(allRects([1 3],1))/2, sum(allRects([2 4],1))/2 , white);
        %[~, ~, textboundscentre] = DrawFormattedText(window, 'EITHER', sum(allRects([1 3],2))/2, sum(allRects([2 4],2))/2 , white);
        %[~, ~, textboundsright] = DrawFormattedText(window, 'RIGHT', sum(allRects([1 3],3))/2, sum(allRects([2 4],3))/2 , white);
        
        q = 1;
        buttons = 0;
        opts1 = 0;
        opts2 = 0;
        opts3 = 0;
        opts4 = 0;
        selected = 0;
        
        questionStart = GetSecs;
        timeLimit = 30;
        
        if devMode == 1
            timeLimit = 5;
        end
        
        doQuestions = 1;
        
        
        while q <= length(questions)
            
            responded = 0;
            thisQuestion = questions{q};
            thisOrder = orders(q,:);
            thisAnswers = answers(q,:);
            thisCorrect = find(thisOrder==1);
            
            while responded == 0
                timeRemaining = timeLimit - round(GetSecs  - questionStart);
                
                clear buttons
                % Get the current position of the mouse
                [x, y, buttons] = GetMouse(window);
                
                % Center the rectangle on the centre of the screen
                
                % See if the mouse cursor is inside the square
                opts1 = IsInRect(x, y, allRects(:,1));
                opts2 = IsInRect(x, y, allRects(:,2));
                opts3 = IsInRect(x, y, allRects(:,3));
                opts4 = IsInRect(x, y, allRects(:,4));
                
                if opts1 == 1
                    
                    opts1_colour = onSquare;
                else
                    
                    opts1_colour = offSquare;
                end
                
                if opts2 == 1
                    
                    opts2_colour = onSquare;
                else
                    
                    opts2_colour = offSquare;
                end
                
                if opts3 == 1
                    
                    opts3_colour = onSquare;
                else
                    
                    opts3_colour = offSquare;
                end
                
                if opts4 == 1
                    
                    opts4_colour = onSquare;
                else
                    
                    opts4_colour = offSquare;
                end
                
                
                
                Screen('FillRect', window, allColors, allRects)
                
                
                DrawFormattedText(window, questions{q}, 'center', yCenter-200, white, 80, [], [], 2);
                DrawFormattedText(window, num2str(timeRemaining),screenXpixels - 100, 100,white,80,[],[],2);
                
                
                
                if devMode == 1
                    if thisCorrect == 1
                        opts1_colour = [0 maxValue 0];
                    elseif thisCorrect == 2
                        opts2_colour = [0 maxValue 0];
                    elseif thisCorrect == 3
                        opts3_colour = [0 maxValue 0];
                    elseif thisCorrect == 4
                        opts4_colour = [0 maxValue 0];
                    end
                end
             
                DrawFormattedText(window, thisAnswers{thisOrder(1)}, screenXpixels * 0.20, yCenter , opts1_colour);
                DrawFormattedText(window, thisAnswers{thisOrder(2)}, screenXpixels * 0.40, yCenter , opts2_colour);
                DrawFormattedText(window, thisAnswers{thisOrder(3)}, screenXpixels * 0.60, yCenter , opts3_colour);
                DrawFormattedText(window, thisAnswers{thisOrder(4)}, screenXpixels * 0.80, yCenter , opts4_colour);
                % Draw a white dot where the mouse is
                Screen('DrawDots', window, [x y], 10, white, [], 2);
                
                % Flip to the screen
                vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
                
                
                if timeRemaining == 0
                    correct(q,1) = 0;
                    incorrectByLevel(level(q),1) = incorrectByLevel(level(q),1) + 1;
                    thisResponse = [opts1 opts2 opts3 opts4];
                    responded = 1;
                    opts1 = 0;
                    opts3 = 0;
                    opts2= 0;
                    opts4 = 0;
                    clear buttons
                    
                    
                end
                
                
                if any(buttons) == 1 && (opts1 ==1||opts3==1||opts2==1||opts4==1)
                    
                    thisResponse = [opts1 opts2 opts3 opts4];
                    responses(q,:) = thisResponse;
                    
                    if find(responses(q,:))== thisCorrect
                        correct(q,1) = 1;
                    else
                        correct(q,1) = 0;
                        incorrectByLevel(level(q),1) = incorrectByLevel(level(q),1) + 1;
                    end
                    responded = 1;
                    opts1 = 0;
                    opts3 = 0;
                    opts2= 0;
                    opts4 = 0;
                    clear buttons
                    
                end
                
                
                if incorrectByLevel(level(q),1) >=2
                    q = length(questions); %q = length(questions) + 1;
                end
                
                if q >= 2
                    if level(q) >= 2
                        if (incorrectByLevel(level(q),:) + incorrectByLevel(level(q)-1,:)) >= 2
                            
                            q = length(questions);
                            
                        end
                        
                    end
                end
                
            end
            
            responseStruct(q).question = thisQuestion;
            responseStruct(q).response = thisResponse;
            responseStruct(q).correctResponse = thisCorrect;
            responseStruct(q).answers = thisAnswers;
            responseStruct(q).order = thisOrder;
            responseStruct(q).correct = correct(q);
            
            responded = 0;
            WaitSecs(.5)
            questionStart = GetSecs;
            q = q + 1;
        end

        
        score = sum(correct);
        
        
        
        
    end
end





% general helper functions

function [outputTime, outputFrame] = Time2Frames(time,ifi)

q = floor(time/(ifi*1000));
m = mod(time,ifi*1000);


if m ~= 0
    lowTime = q * (ifi*1000);
    lowFrame = q;
    highTime = (q + 1) * (ifi*1000);
    highFrame = q + 1;
    
    if abs(lowTime-time) <= abs(highTime-time)
        outputFrame = lowFrame;
        outputTime = lowTime;
    else
        outputFrame = highFrame;
        outputTime = highTime;
    end
    
elseif m == 0
    outputTime = q * (ifi * 1000);
    outputFrame = q;
end
end


