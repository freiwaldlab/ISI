function makeFourierPhaseMaps(root, subj, expt, scale, rotate, gcampFlag)
% modified for Freiwald lab
% original author: Onyekachi 'Kachi' Odoemene, last update 2016-08
% based on online analysis of the Fourier phase map from Ian Nauhaus

% Computes Fourier component for each frame, adds them together, and 
% takes the mean.

%subj      :   Animal name. (string, required)
%expt      :   Experiment indicator. (string, required, e.g. '001')
%scale     :   Factor by which to downsample. (optional, default 1.0)
%              For data collected at 600px x 500px (width x height),
%              setting the parameter to 0.5 results in 300px x 250px images.
%              This saves on computation and demands less memory.
%rotate    :   Angle to rotate images. (optional, default 0)
%gcampFlag :   binary flag to indicate whether session was calcium imaging
%              or intrinsic. (optional, default 0)

%example usage:
%   maps = makeFourierPhaseMaps('k32','25-June-2015','000',2,5,0,1);

% Setup
subj = 'zz9';
expt = 'u000_014';
scale = 1;
root = 'H:\intrinsic';

data_path = fullfile(root, subj, expt);
if ~isdir(data_path)
    error([mfilename ': Could not find data directory.']);
end
map_path = fullfile('H:\intrinsic', subj, expt, 'FourierMaps');
if ~isdir(map_path)
    mkdir(map_path)
end
scale_default = 1;
if ~exist('scale', 'var')
    scale = scale_default;
end
rotate_default = 0;
if ~exist('rotate', 'var')
    rotate = rotate_default;
end
if ~exist('gcampFlag', 'var')
    gcampFlag = 0;
end
max_intens = 2^16 - 1;

%set(0, 'DefaultFigureWindowStyle', 'docked')

% Import experiment details
info_file = fullfile(data_path, ls(fullfile(data_path, '*.analyzer')));
load(deblank(info_file), '-mat');
clear info_file
if ~exist('Analyzer', 'var')
    error([mfilename ': Could not load experiment details.']);
end
if ~strcmpi(Analyzer.P.type, 'SB')
    error([mfilename ': The loaded data was not acquired with the spherical bar stimulus.']);
end
I.NumConds = numel(Analyzer.loops.conds);
reps = numel(Analyzer.loops.conds{1}.repeats);
for c = 1:I.NumConds
    if numel(Analyzer.loops.conds{c}.repeats) == reps
        continue
    else
        error([mfilename ': Number of repeats varies across conditions.']);
    end
end
I.NumReps = reps;
clear reps c
I.NumTrials = I.NumConds * I.NumReps;
I.Conditions = Analyzer.loops.conds;
I.NumConds = numel(I.Conditions);
I.CondParams = nan(I.NumConds, numel(Analyzer.L.param));
I.CondTrials = cell(1, I.NumConds);

for c = 1:I.NumConds
    I.CondParamNames(c,:) = I.Conditions{1,c}.symbol;
    v = cell2mat(I.Conditions{1,c}.val);
    if ~isempty(v)
        I.CondParams(c,:) = v;
    end
    I.Repeats = cell2mat(I.Conditions{1,c}.repeats);
    I.CondTrials{c} = struct2array(I.Repeats);
    clear v
end
clear c
for p = 1:length(Analyzer.P.param)
    n = Analyzer.P.param{p}{1};
    v = Analyzer.P.param{p}{3};
    eval(['I.Params.' n ' = v;']);    
end
clear p n v

tempfiles = dir(data_path);
files = tempfiles(~[tempfiles.isdir]);
data_files = files(cellfun(@(x) ...
    ~isempty(regexp(x, '.*_Intrinsic\.mat', 'once')), {files.name}));
data_files = {data_files.name};
clear tempfiles files
if numel(data_files) < I.NumTrials
    error([mfilename ': Fewer data files than trials.']);
end
fr = nan(1, 4);
nf = nan(1, 4);
for d = 1:numel(data_files)
    mv = who('-file', fullfile(data_path, data_files{d}));
    m = matfile(fullfile(data_path, data_files{d}));
    if ismember('NumFrames', mv)
        nf(d) = m.NumFrames;
    elseif ismember('Frames', mv)
        nf(d) = m.Frames;
    else
        warning([mfilename ': Could not import number of frames.']);
    end
    % Calculate frame rate as the mean difference in all frame timestamps
    fr(d) = round((1 ./ mean(diff(m.FrameTimes))), 2);
end
clear d
if ~all(nf == nf(1))
    warning([mfilename ': Number of frames is not the same for all trials.']);
end
if ~all(fr == fr(1))
    warning([mfilename ': Frame rate is not the same for all trials.']);
end
I.NumFrames = mean(nf);
I.FrameRate = mean(fr);
clear fr nf m mv

%% Compute Fourier maps

% Initialize variables where Fourier maps will be stored
I.meanFourierPhaseMaps = cell(I.NumConds, 1);
I.meanFourierMagMaps = cell(I.NumConds, 1);

fignum = 0;
for condNum = 1:I.NumConds
    disp([mfilename ': Processing condition ' num2str(condNum) ', ' ...
        I.CondParamNames{condNum,1} '=' num2str(I.CondParams(condNum,1))]);
    % Each trial is saved as a sequence of images.
    % For example, 32 trials for the imaging session and 4 conditions turns
    % out to be 8 trials per condition.
    % However, the sequence of trials and consequently the data files might
    % not be saved sequentially.
    % To solve this, loop through each condtion to find the trial numbers 
    % that correspond to each condition.
    timer = tic;
    condTrials = I.CondTrials{condNum};
    for trialIdx = 1:numel(condTrials)
        trialNum = condTrials(trialIdx);
        trialStr = sprintf('t%02d', trialNum);
        disp([mfilename ': Processing trial ' trialStr]);
        try
            % Load data file(s) corresponding to trial
            trialFile = fullfile(data_path, data_files{trialNum});
            trialData = matfile(trialFile, 'Writable', false);
            %trial_data = load(deblank(trial_file));
        catch err
            % Warn if data file(s) cannot be found, but continue processing
            warning([mfilename ': Could not load file. Experiment may ' ...
                'have been interrupted.']);
            continue
        end
        trailVars = who('-file', trialFile);
        if ismember('NumFrames', trailVars)
            trialFrameNum = trialData.NumFrames;
        elseif ismember('Frames', trailVars)
            trialFrameNum = trialData.Frames;
        else
            warning([mfilename ': Could not import number of frames.']);
        end
        clear trailVars
        
        % Find frame files
        trial_path = fullfile(data_path, [trialStr '_data']);
        data_list = dir(trial_path);
        file_list = data_list(~[data_list.isdir]);
        match_str = strcat('.*_', trialStr, '_f(\d+)_data\.mat');
        im_files = struct2cell(file_list(cellfun(@(x) ...
            ~isempty(regexp(x, match_str, 'once')), {file_list.name})));
        im_names = im_files(1,:);
        
        % Index trial epochs (predelay, stim_time, and postdelay)
        %preFrameIdx = 1:trialData.PreStimFrames;
        stimFrameIdx = (trialData.PreStimFrames + 1):(trialFrameNum - trialData.PostStimFrames);
        %postFrameIdx = (trialFrameNum - trialData.PostStimFrames + 1):trialFrameNum;
        
        load(fullfile(trial_path, im_names{1}), 'im');
        [imHpx,imWpx] = size(im);
        
        frameTimes = trialData.FrameTimes(stimFrameIdx,1);
        frameTimes = frameTimes - frameTimes(1);

        % Compute the discrete Fourier transform (i.e. component) for each 
        % frame the Fourier transform at k cycles of a sequence x[n] is
        %   X[k] = cumsum( x[n]*exp((-j*2*pi*n*k)/N) ), from n = 1 to N, 
        % otherwise expressed as
        %   x[n]*exp(-j*w*n)
        % where,
        %   x[n] is the image frame with w by h pixels
        %   n is the frame time point
        %   k is the number of cycles presented during the stimulus epoch
        %   N is equal to number of frames (samples) in one cycle period
        %        (i.e. k = 1) or the total number of frames 
        %        (i.e. k = however many cycles of your stimulus was
        %         presented within the total number of frames)
        %   w is the angular frequency = (2*pi*k)/N
        n = frameTimes;
        k = I.Params.NumCycles;
        N = I.Params.stim_time;
        w = (2*pi * k * n) ./ N;
     
        firstTwoFrames = zeros(imHpx, imWpx, 2, 'double');
        clear im tm
        for f = 1:length(stimFrameIdx)
            %frame = double(trialFrames(:,:,stimFrameIdx(f)));
            fidx = stimFrameIdx(f);
            load(fullfile(trial_path, im_names{fidx}), 'im');
            if exist('im', 'var')
                if (scale == scale_default) && (rotate == rotate_default)
                    frame = double(squeeze(im));
                elseif (scale ~= scale_default) && (rotate ~= rotate_default)
                    frame = imrotate(imresize(double(squeeze(im)), scale), rotate);
                elseif scale ~= scale_default
                    frame = imresize(double(squeeze(im)), scale);
                elseif rotate ~= rotate_default
                    frame = imrotate(double(squeeze(im)), rotate);
                end
            else
                error([mfilename ': Could not load image data for ' ...
                    'frame ' num2str(f) '.']);
            end
            if f == 1
                firstTwoFrames(:,:,1) = im;
            elseif f == 2
                firstTwoFrames(:,:,2) = im;
            end
            if ~gcampFlag
                % Inverts the pixel intensity for intrinsic data,
                % which is a negative dip.
                frame = max_intens - frame;
            end
            if f == 1
                % Start with zeros.
                % The Fourier transforms of all frames will be summed.
                fourierTransform = zeros(size(frame));
            end
            fourierComponent = frame .* exp(1i * w(f));  % x[n]*exp(-j*w*n)
            % The Fourier transform at k cycles, 
            %   X[k] = cumsum( x[n]*exp((-j*2*pi*n*k)/N) )
            % from n = 1 to k,
            % so sum of the Fourier components of frames 1 to k.
            fourierTransform = fourierTransform + fourierComponent;
        end
        clear f fidx fourierComponent
        clear im tm
        
        % (optionally) Remove spectral (F0) leakage.
        % Helps to reduce smearing of the frequency spectrum caused by
        % computing the Fourier transform.  The smearing occurs because
        % the FFT assumes that the signal is periodic with an infinite
        % duration, but we only ever observe a fraction of the infinitely
        % long signal. Therefore, there may be discontinuities (or 
        % imperfect, non-periodic signals) that cause spectral leakage.
        % see http://bugra.github.io/work/notes/2012-09-15/Spectral-Leakage/
        %f0 = sum(double(trialFrames(:,:,stimFrameIdx(1:2))), 3) / 2;
        f0 = sum(double(firstTwoFrames(:,:,1:2)), 3) / 2;
        if ~gcampFlag
            f0 = max_intens - f0;
        end
        fourierTransform = fourierTransform - f0 * sum(exp(1i * w));
        % Normalize (scale) the transform
        fourierTransform = 2 * fourierTransform ./ length(stimFrameIdx);
        clear f0
        % Sum phase and magnitude maps
        if trialIdx == 1
            fourierPhase = zeros(size(frame));
            fourierMag = zeros(size(frame));
        end
        clear frame
        % Compute the mean phase (angle) for each peak and sum for all 
        % trials within condition.
        fourierPhase = fourierPhase + angle(fourierTransform);
        fourierMag = fourierMag + abs(fourierTransform);
        
        clear w k n N;
    end
    % Average the angle (phase) map across trials for this condition
    condPhaseMap = fourierPhase / trialIdx;
    % Average the magnitude map across trials for this condition
    condMagMap = fourierMag / trialIdx;
    % Normalize magnitude map
    condMagMap = (condMagMap - min(condMagMap(:))) ./ range(condMagMap(:));
    
    condTitle = [];
    for i = 1:size(I.CondParamNames, 2)
        condTitle = [condTitle I.CondParamNames(condNum,i) ': ' ...
            num2str(I.CondParams(condNum,i))];
    end
    condTitle = cell2mat(condTitle);
    condTitle = deblank(condTitle);
    
    % Plot mean phase map
    figure(fignum + 1);
    subplot(2,1,1); axis equal;
    imshow(rot90(condPhaseMap, -1), []); colorbar; colormap(parula);
    title(condTitle);
    subplot(2,1,2); axis equal;
    imshow(rot90(condMagMap, -1), stretchlim(condMagMap)'); 
    colorbar; colormap(parula);
    
    % Convert to RGB image
    bit = 2^8;
    % Scale map from 0 to 1 by subtracting the min value from the mean phase
    % map, then dividing by the range.
    condPhaseMapDisp = (condPhaseMap - min(condPhaseMap(:))) ./ ...
        (max(condPhaseMap(:)) - min(condPhaseMap(:)));
    phaseMapIdx = gray2ind(imadjust(condPhaseMapDisp), bit);
    phaseMapRGB = ind2rgb(phaseMapIdx, parula(bit));
    figFilename = strcat(subj, '_', expt, '_', condTitle);
    figFilename(~((figFilename ~= ':') & (figFilename ~= ';'))) = '_';
    figFilename(figFilename == ' ') = '';
    
    imwrite(rot90(phaseMapRGB, -1), ...
        (fullfile(map_path, [figFilename '.png'])));

    I.ConditionTitles{condNum} = condTitle;
    % Store maps
    I.meanFourierPhaseMaps{condNum} = condPhaseMap; 
    I.meanFourierMagMaps{condNum} = condMagMap;
    
    toc(timer)
end

%% Subtract from each map the map generated from stimulus moving in the
%  orthogonal direction
I.screenXcm = Analyzer.M.screenXcm;
I.screenYcm = Analyzer.M.screenYcm;
I.screenDcm = Analyzer.M.screenDist;
I.screenWdeg = 2 * atand((I.screenXcm / 2) / I.screenDcm);
I.screenHdeg = 2 * atand((I.screenYcm / 2) / I.screenDcm);
azimWdeg = round(I.screenWdeg);
elevHdeg = round(I.screenHdeg);
I.screenAdeg = 0;
I.screen2eyeAdeg = 0;
monAZIMdeg = round(I.screenAdeg);
monELEVdeg = round(I.screen2eyeAdeg);
azimRange = [(monAZIMdeg - round(azimWdeg / 2)) ...
    (monAZIMdeg + round(azimWdeg / 2))];
elevRange = [0 elevHdeg] - elevHdeg/2 + monELEVdeg;

if isfield(I.Params, 'BarDirection')
    % BarDirection == 0, right-to-left or bottom-to-top 
    % BarDirection == 1, left-to-right or top-to-bottom
    barDirParamCol = find(strcmp('BarDirection', I.CondParamNames));
    disp([mfilename ' WARNING: TODO *** CHECK FOR TWO SEPARATE DIRECTIONS'])
    pause
    elevInds = find(I.CondParams(barDirParamCol) == 1)
    % Cancel hemodynamic delay by subtracting phase map for reverse direction
    I.meanFourierPhaseMaps
    elevPhaseMap = I.meanFourierPhaseMaps{elevInds(1)} - ...
        I.meanFourierPhaseMaps{elevInds(2)};
    % Scale
    elevPhaseMap = (elevPhaseMap - min(elevPhaseMap(:))) ./ ...
        (max(elevPhaseMap(:)) - min(elevPhaseMap(:)));
    % Scale to stimulus units
    elevPhaseMapScaled = (diff(elevRange) * elevPhaseMap) + elevRange(1);
    elevMagMap =(I.meanFourierMagMaps{elevInds(1)} + ...
        I.meanFourierMagMaps{elevInds(2)}) / 2;
    elevMagMap = (elevMagMap - min(elevMagMap(:))) ./ range(elevMagMap(:));
    I.elevPhaseMap = elevPhaseMap;
    I.elevMagMap = elevMagMap;

    % Plot elevation map
    figure(fignum + 1); clf;
    subplot(2,1,1);
    imshow(rot90(elevPhaseMapScaled, -1), []);
    colorbar; colormap(parula);
    title('elevation retinotopy')
    subplot(2,1,2);
    imshow(rot90(elevMagMap, -1), stretchlim(elevMagMap));
    colorbar; colormap(parula);
    figFilename = 'retinotopy_elevation_map';
    elevMapIdx = gray2ind(imadjust(elevPhaseMap), bit);
    elevMapRGB = ind2rgb(elevMapIdx, parula(bit));
    imwrite(rot90(elevMapRGB, -1), fullfile(map_path, [figFilename '.png']));
   
    % Plot azimuth map
    azimInds = find(I.CondParams(barDirParamCol) == 0);
    azimPhaseMap = I.meanFourierPhaseMaps{azimInds(1)} - ...
        I.meanFourierPhaseMaps{azimInds(2)};
    azimPhaseMap = (azimPhaseMap - min(azimPhaseMap(:))) ./ ...
        (max(azimPhaseMap(:)) - min(azimPhaseMap(:)));
    azimPhaseMapScaled = (diff(azimRange) * azimPhaseMap) + azimRange(1);
    azimMagMap = (I.meanFourierMagMaps{azimInds(1)} + ...
        I.meanFourierMagMaps{azimInds(2)}) / 2;
    azimMagMap = (azimMagMap - min(azimMagMap(:))) ./ range(azimMagMap(:));
    I.azimPhaseMap = azimPhaseMap;
    I.azimMagMap = azimMagMap;
    
    figure(fignum + 1); clf;
    subplot(2,1,1);
    imshow(rot90(azimPhaseMapScaled, -1), []);
    colorbar; colormap(parula);
    title('horizontal (azimuth) retinotopy')
    subplot(2,1,2);
    imshow(rot90(azimMagMap, -1), stretchlim(azimMagMap));
    colorbar; colormap(parula);
    figFilename = 'retinotopy_azimuth_map';   
    azimMapIdx = gray2ind(imadjust(azimPhaseMap), bit);
    azimMapRGB = ind2rgb(azimMapIdx, parula(bit));
    imwrite(rot90(azimMapRGB, -1), fullfile(map_path, [figFilename '.png']));
    
    save(fullfile(map_path, 'retinotopy_azimuth_map.mat'), 'azimPhaseMapScaled');
    save(fullfile(map_path, 'retinotopy_elevation_map.mat'), 'elevPhaseMapScaled');
    
    %% (optionally) Compute visual field sign map from Callaway lab visual
    %  area segmentation paper
    azimKmap = spatialFilterGaussian(azimPhaseMapScaled, 1);
    elevKmap = spatialFilterGaussian(elevPhaseMapScaled, 1);
    % camera: 1 pixel = 7.2 um
    pixpermm = (scale * 1000) / 5.86; %%% TODO !!! *** stop hardcoding px size
    mmperpix = 1 / pixpermm;
    [dadx, dady] = gradient(azimKmap);
    [dedx, dedy] = gradient(elevKmap);
    xdom = (0:size(azimKmap, 2) - 1) * mmperpix;
    ydom = (0:size(azimKmap, 1) - 1) * mmperpix;

    azimGradDir = atan2(dady, dadx);
    elevGradDir = atan2(dedy, dedx);
    
    % Should be elev-azim, but the gradient in MATLAB indexing for y is opposite
    diffGrad = exp(1i * azimGradDir) .* exp(-1i * elevGradDir);
    % Visual field sign map
    visFieldSignMap = sin(angle(diffGrad));
    id = isnan(visFieldSignMap);
    visFieldSignMap(id) = 0;
    % Smooth before thresholding
    visFieldSignMap = spatialFilterGaussian(visFieldSignMap, 5);
    
    figure(fignum + 1); clf;
    imagesc(xdom, ydom, visFieldSignMap, [-1 1]);
    axis image; axis off; colorbar;
    title('sin(angle(elev)-angle(azim))')
end
clear fignum

%set(0,'DefaultFigureWindowStyle', 'normal');
% horizontalMapScaled = imrotate(horizontalMapScaled, rotateImage);
% verticalMapScaled = imrotate(verticalMapScaled, rotateImage);


function img = spatialFilterGaussian(img, sigma)
% cutoff = ceil(2*sigma);
% h=fspecial('gaussian',[1,2*cutoff+1],sigma);
% imgOut = conv2(h,h,img,'same'); %apply spatial filter
    hh = fspecial('gaussian', size(img), sigma); 
    hh = hh / sum(hh(:));
    img = ifft2(fft2(img) .* abs(fft2(hh)));