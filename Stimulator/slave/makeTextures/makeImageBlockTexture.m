function makeImageBlockTexture
    % Make an image presentation block
    global screenPTR %Mstate
    global Gtxtr TDim % for 'playimageblock'
    Gtxtr = []; 
    TDim = [];
    P = getParamStruct;
    window = screenPTR;
    
    % %%% DEBUG XXX ***
    % % Get the screen numbers
    % screens = Screen('Screens');
    % % Draw to the external screen if avaliable
    % screenNumber = max(screens);
    % % Open an on screen window
    % [window, ~] = Screen('OpenWindow', screenNumber, 128, [0 0 500 500]);
    
    % Settings
    imPath = P.image_path;
    imExt = P.image_ext;
    if ~exist(imPath, 'dir')
        disp('makeImageBlockTexture ERROR: image_path not found.');
        return;
    end
    
    % % Get screen resolution
    % screenRes = Screen('Resolution', screenNum);
    % Get the size of the on screen window
    [screenXpx, screenYpx] = Screen('WindowSize', window);
    % Define black and white
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = white / 2;
    inc = white - grey;

    % Get information about images
    imList = dir(strcat(imPath, filesep, '*.', imExt));
    imNum = length(imList);
    imInfo = imfinfo(strcat(imPath, filesep, imList(1).name));
    imHpx = imInfo.Height;
    imWpx = imInfo.Width;
    for imfn = 1:imNum
        imfile = strcat(imPath, filesep, imList(imfn).name);
        imInfoTmp = imfinfo(imfile);
        if imInfoTmp.Height ~= imHpx
            disp(['makeImageBlockTexture ERROR: Stimulus images do ' ...
                'not all share the same dimensions.']);
            return;
        end
        if imInfoTmp.Width ~= imWpx
            disp(['makeImageBlockTexture ERROR: Stimulus images do ' ...
                'not all share the same dimensions.']);
            return;
        end
    end
    clear imfn imfile imInfoTmp
    if imHpx ~= imWpx
	disp('makeImageBlockTexture WARNING: Stimulus image is not square.');
        disp(['makeImageBlockTexture WARNING:   All calculations will ' ...
            'be made based on larger dimension.']);
    end
    % Make sure that set stimulus time is correct
    %%% TODO throw an error elsewhere, not just on slave
    stimTcalc = (imNum * P.image_duration) + ...
        ((imNum - 1) * P.interval_duration);
    if stimTcalc ~= P.stim_time
        disp(['makeImageBlockTexture ERROR: Stimulus time set to ' ...
            num2str(P.stim_time) ' sec, calculated' ...
            num2str(stimTcalc) ' sec.'])
    end
    
    % Preload all images into a buffer
    disp('makeImageBlockTexture: Loading stimulus images.')
    tic
    if imHpx > screenYpx || imWpx > screenXpx
        disp(['makeImageBlockTexture WARNING: Stimulus image is too ' ...
            'big to fit on the screen.']);
        disp(['makeImageBlockTexture WARNING:   Resizing image, which ' ...
            'is slow and undesireable!']);
        if imHpx > imWpx
            imHpx = screenYpx;
            imWpx = round(imWpx * (imHpx / screenYpx));
        elseif imWpx > imHpx
            imWpx = screenXpx;
            imHpx = round(imHpx * (imWpx / screenXpx));
        else
            imHpx = screenYpx;
            imWpx = screenXpx;
        end
        imBuff = zeros(imHpx, imWpx, imNum);
        for imfn = 1:imNum
            imfile = strcat(imPath, filesep, imList(imfn).name);
            imBuff(:,:,imfn) = imresize(imread_gray(imfile), ...
                [imHpx imWpx]);
        end
        clear imfn imfile
    else
        imBuff = zeros(imHpx, imWpx, imNum);
        for imfn = 1:imNum
            imfile = strcat(imPath, filesep, imList(imfn).name);
            imBuff(:,:,imfn) = imread_gray(imfile);
        end
        clear imfn imfile I
    end
    load_time = toc;
    disp(['makeImageBlockTexture: Finished loading images (' ...
        num2str(load_time) ' sec)'])
    
    % % Calculate width and height in centimeters from degrees
    % %   TODO: Check to make sure specified width/height matches 
    % %   image dimensions.
    % if imHpx == imWpx
    %     stimHdeg = P.y_size;
    %     stimWdeg = P.x_size;
    % elseif imHpx > imWpx
    %     stimHdeg = P.y_size;
    %     stimWdeg = round(P.x_size * (imWpx / imHpx));
    % elseif imWpx > imHpx
    %     stimHdeg = round(P.y_size * (imHpx / imWpx));
    %     stimWdeg = P.x_size;
    % end
    % stimHcm = 2 * Mstate.screenDist * tan(((stimHdeg / 2) * pi) / 180);
    % stimWcm = 2 * Mstate.screenDist * tan(((stimWdeg / 2) * pi) / 180);
    % clear Hdeg Wdeg
  
    % Adjust the contast for each image
    %     f(x) = ?(x?128) + 128 + b
    %     slope ? controls contrast
    %         (?>1 means more contrast and 0<?<1 less contrast)
    %     constant b controls brightness
    alpha = P.contrast / 100;
    beta = 0;
    for imn = 1:imNum
        I = imBuff(:,:,imn);
        imBuff(:,:,imn) = (alpha * (I - grey)) + grey + beta;
    end
    clear alpha beta imn I
    
    % Convert the images into textures that are ready to be played
    Gtxtr = zeros(1, imNum);
    for imn = 1:imNum
        Gtxtr(imn) = Screen('MakeTexture', window, imBuff(:,:,imn));
    end
    clear imn
    
    % Save image dimensions
    TDim = [imWpx imHpx];
    
function I = imread_gray(file_path)
    I = imread(file_path);
    if size(I, 3) > 1
        I = rgb2gray(I);
    end