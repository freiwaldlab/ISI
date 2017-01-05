function makeImageBlockTexture
    %make an image presentation block
    global Mstate screenPTR screenNum
    global Gtxtr TDim  %'playimageblock' will use these

    Gtxtr = []; TDim = [];
    Pstruct = getParamStruct;
    
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

    % Get information about images. Assume all images have same dimensions.
    imList = dir(strcat(imPath, filesep, '*.', imExt));
    imNum = length(imList);
    imInfo = imfinfo(strcat(imPath, filesep, imList(1).name));
    imHpx = imInfo.Height;
    imWpx = imInfo.Width;
    
    % Preload all images into a buffer.
    if imHpx > screenYpx || imWpx > screenXpx
        disp('ERROR! Image is too big to fit on the screen.');
        return;
        %disp('resizing image, which is slow and undesireable!');
        %if imHpx > imWpx
        %    imHpx = screenYpx;
        %    imWpx = round(imWpx * (imHpx / screenYpx));
        %elseif imWpx > imHpx
        %    imWpx = screenXpx;
        %    imYpx = round(imWpx * (imWpx / screenXpx));
        %else
        %    imHpx = screenYpx;
        %    imWpx = screenXpx;
        %end
        %imBuff = zeros(imHpx, imWpx, imNum);
        %for imfn = 1:imNum
        %    imfile = strcat(imPath, filesep ,imList(imfn).name);
        %    imBuff(:,:,imfn) = imresize(imread(imfile), [imHpx imWpx]);
        %end
        %clear imfn imfile
    else
        imBuff = zeros(imHpx, imWpx, imNum);
        for imfn = 1:imNum
            imfile = strcat(imPath, filesep ,imList(imfn).name);
            imBuff(:,:,imfn) = imread(imfile);
        end
        clear imfn imfile
    end
    
    barWcm = 2*Mstate.screenDist*tan(Pstruct.barWidth/2*pi/180);  %bar width in cm
    barLcm = 2*Mstate.screenDist*tan(Pstruct.barLength/2*pi/180);  %bar length in cm

    Im = makeBar(barWcm,barLcm,0);
    imBuff = imBuff * (Pstruct.contrast / 100);
    TDim = size(imBuff(:,:,1));
    
    % Convert the images into textures ready for playing.
    for in = 1:imNum
        Gtxtr(in) = Screen('MakeTexture', window, imBuff(:,:,in));
    end