%testing

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
inc = white - grey;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Get the size of the on screen window
[screenXpx, screenYpx] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Set up images
imPath = 'G:\X-RAY_DATA_FROM_JANELIA\David_Hildebrand_PPC\141220_LDMS2_20\141220_LDMS2_20_AllTiffs_Cropped_8bit';
imList = dir(strcat(imPath, filesep, '*.tif'));
imNum = length(imList);
imInfo = imfinfo(strcat(imPath, filesep, imList(1).name));
imHpx = imInfo.Height;
imWpx = imInfo.Width;

if imHpx > screenYpx || imWpx > screenXpx
    disp('ERROR! Image is too big to fit on the screen.');
    disp('resizing image, which is slow and undesireable!');
    if imHpx > imWpx
        imHpx = screenYpx;
        imWpx = round(imWpx * (imHpx / screenYpx));
    elseif imWpx > imHpx
        imWpx = screenXpx;
        imYpx = round(imWpx * (imWpx / screenXpx));
    else
        imHpx = screenYpx;
        imWpx = screenXpx;
    end
    imBuff = zeros(imHpx, imWpx, imNum);
    for imfn=1:imNum
        imfile = strcat(imPath, filesep ,imList(imfn).name);
        imBuff(:,:,imfn) = imresize(imread(imfile), [imHpx imWpx]);
    end
    clear imfn imfile
else
    imBuff = zeros(imHpx, imWpx, imNum);
    for imfn=1:imNum
        imfile = strcat(imPath, filesep ,imList(imfn).name);
        imBuff(:,:,imfn) = imread(imfile);
    end
    clear imfn imfile
end

% Convert the images into textures
imTexture = NaN(imNum,1);
for in=1:imNum
    imTexture(in) = Screen('MakeTexture', window, imBuff(:,:,in));
end;
clear in

% Make a list of all frames and another with random ordering.
frames = (1:imNum)';
framesRandom = frames(randperm(size(frames,1)))';

% Draw the textures to the screen
for fn=framesRandom
    % Draw the image to the screen, unless otherwise specified PTB will 
    % draw the texture full size in the center of the screen.
    Screen('DrawTexture', window, imTexture(fn), [], [], 0);
    % Flip to the window
    Screen('Flip',window);
    % Wait
    WaitSecs(0.5);
    % Now blank the screen
    Screen('FillRect', window, [0 0 0]);
    % Flip to the window
    Screen('Flip',window);
    % Wait
    WaitSecs(0.25);
end;
clear fn

% Clear and close the screen
sca;
Screen('CloseAll');