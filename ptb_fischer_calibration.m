% Performs some basic calibration tests:
%
% Determines the pixel height and pixel width of a 1cm x 1cm object
% Determines the pixel height and pixel width of various font sizes
%
% Finally visual angle is calculated for a given viewing distance
%
% These values are written to Params.mat to be used by the experiment
% code. Calibration is only required one
%
% written by Lincoln Colling <lincoln@colling.net.nz>
function ifi = Calibrate

% --- DO NOT CHANGE -- %
devMode = 0;
if devMode == 1
    Screen('Preference', 'SkipSyncTests', 1);
end
% --- END --- %


thePath = [cd filesep];
[keyboardIndices, productNames, allInfos] = GetKeyboardIndices;
disp(['Found the following keyboards: ' productNames])

for i = 1 : length(productNames)
    useKeyboard = input(['Would you like to use ' productNames{i} ' (y/n)? '],'s');
    if strcmpi(useKeyboard(1),'y')
        keyboardToUse = keyboardIndices(i);
        break
    end
end


device = keyboardToUse;



params = struct;

screenNumber = 0;
KbName('UnifyKeyNames')
if exist([thePath 'Params.Mat'],'file') == 2
    warning('This system already appears to be calibrated')
    s = input('Are you sure you want to continue? (Y/N): ','s');
    if strcmpi(s(1),'n')
        error('aborted')
    elseif strcmpi(s(1),'y')
        warning('over writing parameters file...')
        delete([thePath 'Params.mat'])
    else
        warning('not a valid input')
    end
end


sca;

escapeKey = KbName('ESCAPE');
upKey = KbName('UpArrow');
downKey = KbName('DownArrow');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');

viewingDistance = input('What is the viewing distance in cm? ');
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
ifi = Screen('GetFlipInterval', window);
if ifi > 0.017
  error('The monitor refresh rate is to slow')
end
try
    for t = 1 : 2
        
        
        
        
        % Display the instructions and wait for key press to continue
        Screen('TextSize',window,24);
        DrawFormattedText(window, 'Use the arrow keys to resize the box so that it measures 3 cm x 3 cm. Press Esc once complete. Press any key to continue', 'center', 'center', [1 1 1], 80);
        Screen('Flip', window);
        KbWait(device);
        
        
        % Draw the box
        [xCenter, yCenter] = RectCenter(windowRect);
        rectWidth = 100;
        rectHeight = 100;
        baseRect = [0 0 rectWidth rectHeight];
        rect = CenterRectOnPointd(baseRect, xCenter, yCenter);
        Screen('FillRect', window, [1 1 1], OffsetRect(baseRect,xCenter,yCenter));
        Screen('Flip', window);
        
        % resize the box
        
        resizing = 1;
        while resizing == 1
            
            [keyIsDown,~, keyCode] = KbCheck(device);
            
            if keyCode(escapeKey)
                resizing = 0;
                params.rectWidth = rectWidth;
                params.rectHeight = rectHeight;
            elseif keyCode(leftKey)
                rectWidth = rectWidth - 1;
            elseif keyCode(rightKey)
                rectWidth = rectWidth + 1;
            elseif keyCode(upKey)
                rectHeight = rectHeight - 1;
            elseif keyCode(downKey)
                rectHeight = rectHeight + 1;
            end
            
            
            baseRect = [0 0 rectWidth rectHeight];
           
            rect = CenterRectOnPointd(baseRect, xCenter, yCenter);
            
            Screen('FillRect', window, [1 1 1],  OffsetRect(baseRect,xCenter,yCenter));
            Screen('Flip', window);
            
            
        end
        try
            for i = 1 :  100
                Screen('TextSize',window,i);
                [nx,ny,bbox] = DrawFormattedText(window, '0', 'center', 'center', [1 1 1]);
                pixelWidth  =  bbox(3) - bbox(1); %x
                pixelHeight = bbox(4) - bbox(2); %y
                params.fontSize(i,1) = pixelWidth;
                params.fontSize(i,2) = pixelHeight;
                
            end
        catch
            warning('error on font sizing')
        end
        
        
        
        % Clear the screen
        Screen('FillRect', window, [1 1 1], rect);
        Screen('Flip', window);
        
        [pixPerDegHeight,degPerPixHeight] = VisAng(rectHeight,3,viewingDistance);
        [pixPerDegWidth,degPerPixWidth] = VisAng(rectWidth,3,viewingDistance);
        
        params.viewingDistance(t) = viewingDistance;
        params.pixPerDegHeight(t) = pixPerDegHeight;
        params.degPerPixHeight(t) = degPerPixHeight;
        params.pixPerDegWidth(t) = pixPerDegWidth;
        params.degPerPixWidth(t) = degPerPixWidth;
        
    end
    
    
    params.viewingDistance = mean(params.viewingDistance);
    params.pixPerDegHeight = mean(params.pixPerDegHeight);
    params.degPerPixHeight = mean(params.degPerPixHeight);
    params.pixPerDegWidth = mean(params.pixPerDegWidth);
    params.degPerPixWidth = mean(params.degPerPixWidth);
    params.ifi = ifi;
    params.keyboardDevice = device;
    save([thePath 'Params.mat'],'params','-mat')
    sca
    
catch ME
    warning(ME.message)
    sca;
end

function [pixPerDeg,degPerPix] = VisAng(pixels,size,viewingDistance)
% function [pixPerDeg,degPerPix] = VisAng(pixels,size,viewingDistance)
%
% Determines pixels per degree and degrees per pixel for a given object size
% in pixels and cm and for a given viewing distance
%
%       Takes the following input
%   pixels - size in pixels of the measured object
%   size - size in cm of the measured object
%   viewingDistance - distance in cm between the monitor and the subject
%
%
% output is in degrees (not radians)
% written by Lincoln Colling <lincoln@colling.net.nz>

degPerPix = 2 * ((atan(size ./ (2*viewingDistance))) .* (180/pi)) ./ pixels;
pixPerDeg = 1 ./ degPerPix;


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