function stimTime = makeImageBlockTexture
    % Make an image presentation block
    global screenPTR
    %global Mstate
    global Gtxtr TDim
    Gtxtr = []; 
    TDim = [];
    P = getParamStruct;
    window = screenPTR;
    
    % Settings
    imPath = P.image_path;
    imExt = P.image_ext;
    if ~exist(imPath, 'dir')
        error([mfilename ': image_path not found.']);
        return;
    end
    
    %screenRes = Screen('Resolution', screenNum);
    [screenXpx, screenYpx] = Screen('WindowSize', window);
    white = WhiteIndex(window);
    %black = BlackIndex(window);
    grey = white / 2;
    %inc = white - grey;

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
            error([mfilename ': Stimulus images do ' ...
                'not all share the same dimensions.']);
            return;
        end
        if imInfoTmp.Width ~= imWpx
            error([mfilename ': Stimulus images do ' ...
                'not all share the same dimensions.']);
            return;
        end
    end
    clear imfn imfile imInfoTmp
    if imHpx ~= imWpx
        warning([mfilename ': Stimulus image is not square.']);
        warning([mfilename ': Calculations will be made based on ' ...
            'the larger dimension.']);
    end
    
    % Calculate total stimulus time
    stimTcalc = (imNum * P.image_duration) + ...
        ((imNum - 1) * P.interval_duration);
    stimTime = stimTcalc;
    
    % Preload all images into a buffer
    disp([mfilename ': Loading stimulus images.']);
    tic
    if imHpx > screenYpx || imWpx > screenXpx
    % If images are larger than screen, downsample
        warning([mfilename ': Stimulus image is too ' ...
            'big to fit on the screen.']);
        warning([mfilename ':   Resizing image, which ' ...
            'may be slow.']);
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
    % Otherwise, load at full resolution
        imBuff = zeros(imHpx, imWpx, imNum);
        for imfn = 1:imNum
            imfile = strcat(imPath, filesep, imList(imfn).name);
            imBuff(:,:,imfn) = imread_gray(imfile);
        end
        clear imfn imfile I
    end
    load_time = toc;
    disp([mfilename ': Finished loading images (' ...
        num2str(load_time) ' sec).'])
  
    % Adjust contast for each image
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
    Gtxtr = NaN(1, imNum);
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