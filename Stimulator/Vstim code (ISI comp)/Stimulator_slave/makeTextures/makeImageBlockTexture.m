function makeImageBlockTexture
    % Make an image presentation block
    global Mstate screenPTR screenNum
    global Gtxtr TDim  %'playimageblock' will use these

    Gtxtr = []; TDim = [];
    P = getParamStruct;
    
    % Settings
    imPath = 'H:\Freiwald\Stimuli\FullFOB3';
    imExt = 'bmp';
    
    % Get screen resolution
    screenRes = Screen('Resolution', screenNum);
    % Get the size of the on screen window
    [screenXpx, screenYpx] = Screen('WindowSize', window);
    % Define black and white
    white = WhiteIndex(screenPTR);
    black = BlackIndex(screenPTR);
    grey = white / 2;
    inc = white - grey;
    % Set up alpha-blending for smooth (anti-aliased) lines
    %Screen('BlendFunction', window, 'GL_SRC_ALPHA', ...
    %    'GL_ONE_MINUS_SRC_ALPHA');

    % Get information about images.
    imList = dir(strcat(imPath, filesep, '*.', imExt));
    imNum = length(imList);
    imInfo = imfinfo(strcat(imPath, filesep, imList(1).name));
    imHpx = imInfo.Height;
    imWpx = imInfo.Width;
    for imfn = 1:imNum
        imfile = strcat(imPath, filesep, imList(imfn).name);
        imInfoTmp = imfinfo(imfile);
        if imInfoTmp.Height ~= imHpx
            disp('makeImageBlockTexture ERROR: Stimulus images do not all share the same dimensions.');
            return;
        end
        if imInfoTmp.Width ~= imWpx
            disp('makeImageBlockTexture ERROR: Stimulus images do not all share the same dimensions.');
            return;
        end
    end
    clear imfn imfile imInfoTmp
    if imHpx ~= imWpx
	disp('makeImageBlockTexture WARNING: Stimulus image is not square.');
        disp('makeImageBlockTexture WARNING:   All calculations will be made based on larger dimension.');
    end
    
    % Preload all images into a buffer.
    if imHpx > screenYpx || imWpx > screenXpx
        disp('makeImageBlockTexture WARNING: Stimulus image is too big to fit on the screen.');
        %return;
        disp('makeImageBlockTexture WARNING:   Resizing image, which is slow and undesireable!');
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
        for imfn = 1:imNum
            imfile = strcat(imPath, filesep, imList(imfn).name);
            imBuff(:,:,imfn) = imresize(imread(imfile), [imHpx imWpx]);
        end
        clear imfn imfile
    else
        imBuff = zeros(imHpx, imWpx, imNum);
        for imfn = 1:imNum
            imfile = strcat(imPath, filesep, imList(imfn).name);
            imBuff(:,:,imfn) = imread(imfile);
        end
        clear imfn imfile
    end
    
    % Calculate width and height in centimeters from degrees
    %TODO check to make sure specified width/height matches image dimensions
    if imHpx == imWpx
        Hdeg = P.height;
        wdeg = P.width;
    elseif imHpx > imWpx
        Hdeg = P.height;
        wdeg = round(P.width * (imWpx / imHpx));
    elseif imWpx > imHpx
        Hdeg = round(P.height * (imHpx / imWpx));
        wdeg = P.width;
    end
    imHcm = 2 * Mstate.screenDist * tan(((Hdeg / 2) * pi) / 180);
    imWcm = 2 * Mstate.screenDist * tan(((Wdeg / 2) * pi) / 180);
    clear Hdeg Wdeg

    imBuff = imBuff * (P.contrast / 100);
    TDim = [(imHcm * P.y_zoom) (imWcm * P.x_zoom)];
    
    % Convert the images into textures that are ready to be played
    for in = 1:imNum
        Gtxtr(in) = Screen('MakeTexture', window, imBuff(:,:,in));
    end
