function makeFourierPhaseMaps(root, subj, datestr, timestr, scale, rotate, gcampFlag)
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

%% Setup
% datestr = '171005';
% timestr = '200835';
% subj = 'blockhead';
% scale = 1;
% root = 'D:\';

if ~regexp(datestr, '^\d{6}')
    error([mfilename ': Input experiment date string format not '
        'recognized (expected YYMMDD).']);
end
if ~regexp(timestr, '^\d{6}')
    error([mfilename ': Input experiment time string format not '
        'recognized (expected YYMMDD).']);
end
main_path = fullfile(root, [datestr 'd_' subj]);
if ~isdir(main_path)
    error([mfilename ': Data directory does not exist.']);
end
map_path = fullfile(main_path, 'maps');
if ~isdir(map_path)
    mkdir(map_path)
    disp([mfilename ': Created ''maps'' output directory ['
        map_path '].']);
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

%% Import experiment details
info_file_ptrn = [datestr 'd' timestr 't_(\D{2})_ExperimentParameters.mat'];
tempfiles = dir(main_path);
files = tempfiles(~[tempfiles.isdir]);
match_files = files(cellfun(@(x) ...
    ~isempty(regexp(x, info_file_ptrn, 'once')), {files.name}));
info_file = fullfile(match_files(1).folder, match_files(1).name);
stim_code = regexprep(info_file, ['.*' info_file_ptrn], '$1');
if numel(match_files) ~= 1
    warning([mfilename ': More than one experiment parameter file matched '
        'this date and time. Using only the first [' info_file '].']);
end
clear info_file_ptrn tempfiles files match_files
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
    if any(strcmpi(Analyzer.loops.conds{c}.symbol(:), 'blank'))
        continue
    end
    if numel(Analyzer.loops.conds{c}.repeats) == reps
        continue
    else
        warning([mfilename ': Number of repeats varies across conditions.']);
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
    I.CondTrials{c} = cell2mat(struct2cell(I.Repeats));
    clear v
end
clear c
for p = 1:length(Analyzer.P.param)
    n = Analyzer.P.param{p}{1};
    v = Analyzer.P.param{p}{3};
    eval(['I.Params.' n ' = v;']);    
end
clear p n v

trial_ptrn = [datestr 'd' timestr 't_' stim_code '_t(\d+)_data'];
tempdirs = dir(main_path);
dirs = tempdirs([tempdirs.isdir]);
match_dirs = dirs(cellfun(@(x) ...
    ~isempty(regexp(x, trial_ptrn, 'once')), {dirs.name}));
match_dirs = sort({match_dirs.name})';
trial_path = cell(numel(match_dirs), 1);
for p = 1:numel(trial_path)
    trial_path(p) = fullfile(main_path, match_dirs(p));
end
clear tempdirs dirs match_dirs p 
if numel(trial_path) < I.NumTrials
    error([mfilename ': There are fewer trial data directories than '
        'trials. Some data is missing.']);
end

%% Check data for all trials
nf = nan(numel(trial_path), 1);
fr = nan(numel(trial_path), 1);
I.PreStimTimes = nan(numel(trial_path), 2);
I.PostStimTimes = nan(numel(trial_path), 2);
I.TrialFrameTimes = cell(numel(trial_path), 1);
I.TrialFrameRate = cell(numel(trial_path), 1);
I.TrialPreStimFrames = cell(numel(trial_path), 1);
I.TrialPostStimFrames = cell(numel(trial_path), 1);
for tp = 1:numel(trial_path)
    trialStr = regexprep(trial_path{tp}, '.*_(t\d+)_.*', '$1');
    trialFullStr = [datestr 'd' timestr 't_' stim_code '_' trialStr];
    disp([mfilename ': Checking ' trialFullStr ' data...']);
    log_name = [trialFullStr '.log'];
    log_path = fullfile(main_path, log_name);
    if ~exist(log_path, 'file')
        error([mfilename ': Could not find trial ' trialStr ...
            ' log file [' log_path '].']);
    end
    log_file = fopen(log_path, 'r');
    [log_data,~] = fread(log_file, [6,inf], 'double');
    % log_data is a 6 x samples matrix where...
    %   (1,:) is the time each sample is taken from start
    %   (2,:) is the voltage on analog input 0: photodiode from display
    %   (3,:) is the voltage on analog input 1: strobe from camera
    %   (4,:) is the voltage on analog input 2: trigger copy
    %   (5,:) is the voltage on analog input 3: audio copy
    %   (6,:) is the voltage on analog input 4: start/stop ttl copy
    fclose(log_file);
    clear log_name log_path log_file
    samples = length(log_data);
    time_sec = log_data(1,:)';
    Fs = 1000;  % sampling frequency in Hz % analogIN.Rate
    % Normalize photodiode signal
    photodiode = log_data(2,:)';
    pd_high = max(photodiode);
    pd_low = median(photodiode);  % median to avoid negative transients
    pd_thresh = (pd_high + pd_low) / 2;
    photodiode = sign(photodiode - pd_thresh);
    photodiode(photodiode == 0) = 1;
    photodiode = (photodiode - min(photodiode)) / ...
        (max(photodiode) - min(photodiode));
    % Filter out down states caused by monitor refresh
    %Mstate.refresh_rate
    delta = 120 / Fs;  % window of one monitor refresh period
    pd_hightimes = time_sec(photodiode == 1);
    highidx = find(photodiode == 1);
    for idx = 1:length(highidx)-1
        if (pd_hightimes(idx+1) - pd_hightimes(idx)) <= delta
            photodiode(highidx(idx):highidx(idx+1)) = 1;
        end
    end
    clear idx highidx delta Fs pd_hightimes
    pd_high = max(photodiode);
    pd_low = min(photodiode);
    pd_thresh = (pd_high + pd_low) / 2;
    pd_ups = nan(samples, 1);
    pd_dns = nan(samples, 1);
    pd_last = pd_low;
    for trial = 1:samples
        if (photodiode(trial) < 1)
            if (pd_last == pd_high)
                pd_dns(trial) = 1;
            else
                pd_dns(trial) = 0;
            end
            pd_ups(trial) = 0;
            pd_last = pd_low;
        elseif (photodiode(trial) > pd_thresh)
            if (pd_last == pd_low)
                pd_ups(trial) = 1;
            else
                pd_ups(trial) = 0;
            end
            pd_dns(trial) = 0;
            pd_last = pd_high;
        else
            pd_dns(trial) = 0;
            pd_ups(trial) = 0;
            pd_last = pd_low;
        end
    end
    clear t
    clear pd_high pd_low pd_thresh pd_last
    uptimes = time_sec(pd_ups==1);
    dntimes = time_sec(pd_dns==1);
    clear pd_ups pd_dns
    I.TrialPreStimTimes(tp, 1) = uptimes(1);
    I.TrialPreStimTimes(tp, 2) = dntimes(1);
    I.TrialPostStimTimes(tp, 1) = uptimes(end);
    I.TrialPostStimTimes(tp, 2) = dntimes(end);
    clear uptimes dntimes
    
    % Normalize camera strobe
    strobe = log_data(3,:)';
    strb_high = max(strobe);
    strb_low = min(strobe);
    strobe(strobe < 0) = 0;
    strb_thresh = (strb_high + strb_low) / 2;
    strobe = sign(strobe - strb_thresh);
    strobe(strobe == 0) = 1;
    strobe = (strobe - min(strobe)) / ...
        (max(strobe) - min(strobe));
    strb_high = max(strobe);
    strb_low = min(strobe);
    strb_thresh = (strb_high + strb_low) / 2;
    frame_fin = nan(samples, 1);
    strb_last = strb_low;
    for t = 1:samples
        if (strobe(t) < 1)
            if (strb_last == strb_high)
                frame_fin(t) = 1;
            else
                frame_fin(t) = 0;
            end
            strb_last = strb_low;
        elseif (strobe(t) > strb_thresh)
            frame_fin(t) = 0;
            strb_last = strb_high;
        else
            frame_fin(t) = 0;
            strb_last = strb_low;
        end
    end
    clear t
    clear strb_high strb_low strb_thresh strb_last

    I.TrialFrameTimes{tp} = time_sec(frame_fin==1);
    I.TrialFrameRate{tp} = round((1 ./ mean(diff(time_sec(frame_fin==1)))), 2);
    I.TrialPreStimFrames{tp} = sum(I.TrialFrameTimes{tp} <= I.TrialPreStimTimes(tp,2));
    I.TrialPostStimFrames{tp} = sum(I.TrialFrameTimes{tp} >= I.TrialPostStimTimes(tp,1));
    
    %figure(1); clf;
    %hold on;
    %plot(time_sec, photodiode, 'm'); % photodiode filtered
    %plot(time_sec, 0.20*frame_fin, 'r'); % camera strobe filtered
    %plot(m.PreStimTimes, [0.8 0.8], 'y');
    %plot(m.PostStimTimes, [0.8 0.8], 'y');
    %hold off;
    %xlim([0 time_sec(samples)]);
    %xlabel('Time');
    %ylim([-0.1 1.1]);
    %ylabel('Signal');
    clear log_data samples photodiode frame_fin strobe time_sec

    data_list = dir(trial_path{tp});
    file_list = data_list(~[data_list.isdir]);
    im_match_str = [trialStr '_f(\d+).*'];
    im_files = struct2cell(file_list(cellfun(@(x) ...
        ~isempty(regexp(x, im_match_str, 'once')), {file_list.name})));
    clear log_match_str im_match_str
    im_names = im_files(1,:);
    nf(tp) = length(im_names);
    %frt = nan(nf(tp), 1);
    %for f = 1:nf(tp)
    %    % Extract frame timing information from camera relative time values
    %    frame_file = fullfile(trial_path{tp}, im_names{f});
    %    % MATfile approach seems slower than direct loading
    %    load(frame_file, 'tm');
    %    %m = matfile(frame_file, 'Writable', false);
    %    %tm = m.tm;
    %    if exist('tm', 'var')
    %        frt(f) = squeeze(tm);
    %    else
    %        warning([mfilename ': Could not find frame time for ' ...
    %            num2str(f) ' [' frame_file '].']);
    %    end
    %    clear tm m frame_file
    %end
    % % Calculate frame rate as the mean difference in all frame timestamps
    %fr(tp) = round((1 ./ mean(diff(frt))), 2);
end
clear tp data_list file_list match_str im_files im_names frameN frt f
clear trialFullStr
if ~all(nf == nf(1))
    warning([mfilename ': Number of frames is not the same for all ' ...
        'trials. Using the minimum across trials.']);
end
I.NumFrames = min(nf);
clear nf
e = 0.05;
I.FrameRate = mean([I.TrialFrameRate{:}]);
if any(diff([I.TrialFrameRate{:}]) > e)
    warning([mfilename ': Frame rate is not the same for all trials.' ...
        'Using mean.']);
end
clear fr nf e

%% Compute Fourier maps

% Initialize variables where Fourier maps will be stored
I.meanFourierPhaseMaps = cell(I.NumConds, 1);
I.meanFourierMagMaps = cell(I.NumConds, 1);

fignum = 0;
for condNum = 1:I.NumConds
    condTitle = [];
    for i = 1:size(I.CondParamNames, 2)
        condTitle = [condTitle I.CondParamNames(condNum,i) ...
            num2str(I.CondParams(condNum,i))];
        if i < size(I.CondParamNames, 2)
            condTitle = [condTitle '_'];
        end
    end
    clear i
    condTitle = cell2mat(condTitle);
    condTitle = deblank(condTitle);
    if ~any(strcmpi(I.CondParamNames(condNum,:), 'blank'))
        disp([mfilename ': Processing condition ' num2str(condNum) ', ' ...
            condTitle '...']);
    else
        disp([mfilename ': Skipping blank condition ' num2str(condNum) '...']);
        continue
    end
    
    % Each trial is saved as a sequence of images.
    % For example, 32 trials for the imaging session and 4 conditions turns
    % out to be 8 trials per condition.
    % However, the sequence of trials and consequently the data files might
    % not be saved sequentially.
    % To solve this, loop through each condtion to find the trial numbers 
    % that correspond to each condition.
    timer = tic;
    condTrials = I.CondTrials(condNum);
    %for repIdx = 1:numel(
    for trialIdx = 1:numel(condTrials)
        trialStr = regexprep(trial_path{condTrials{trialIdx}}, '.*_(t\d+)_.*', '$1');
        trialFullStr = [datestr 'd' timestr 't_' stim_code '_' trialStr];
        disp([mfilename ': Processing trial ' trialFullStr '...']);
        data_list = dir(trial_path{condTrials{trialIdx}});
        file_list = data_list(~[data_list.isdir]);
        match_str = [trialStr '_f(\d+).*'];
        im_files = struct2cell(file_list(cellfun(@(x) ...
            ~isempty(regexp(x, match_str, 'once')), {file_list.name})));
        im_names = im_files(1,:);
        
        % Index trial epochs (predelay, stim_time, and postdelay)
        %preFrameIdx = 1:I.TrialPreStimFrames{trialIdx};
        stimFrameIdx = (I.TrialPreStimFrames{trialIdx} + 1):(I.NumFrames - I.TrialPostStimFrames{trialIdx});
        %postFrameIdx = (I.NumFrames - I.TrialPostStimFrames{trialIdx} + 1):I.NumFrames;
        
        load(fullfile(trial_path{condTrials{trialIdx}}, im_names{1}), 'im');
        [imHpx,imWpx] = size(im);
        
        frameTimes = I.TrialFrameTimes{trialIdx};
        stimFrameTimes = frameTimes(stimFrameIdx);
        stimFrameTimes = stimFrameTimes - stimFrameTimes(1);

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
        n = stimFrameTimes;
        k = I.Params.NumCycles;
        N = I.Params.stim_time;
        w = (2*pi * k * n) ./ N;
     
        firstTwoFrames = zeros(imHpx, imWpx, 2, 'double');
        clear im tm
        for f = 1:length(stimFrameIdx)
            %frame = double(trialFrames(:,:,stimFrameIdx(f)));
            fidx = stimFrameIdx(f);
            load(fullfile(trial_path{condTrials{trialIdx}}, im_names{fidx}), 'im');
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
    
    % Plot mean phase map
    fignum = fignum + 1;
    figure(fignum); clf;
    subplot(2,1,1); axis equal;
    imshow(rot90(condPhaseMap, -1), []); colorbar; colormap(parula);
    title(condTitle, 'Interpreter', 'none');
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
    figFilename = strcat(trialFullStr, '_', condTitle);
    figFilename(~((figFilename ~= ':') & (figFilename ~= ';'))) = '_';
    figFilename(figFilename == ' ') = '';
    
    imwrite(fliplr(rot90(phaseMapRGB, -1)), ...
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
    elevInds = find(I.CondParams(barDirParamCol) == 1);
    % Cancel hemodynamic delay by subtracting phase map for reverse direction
    %I.meanFourierPhaseMaps
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
    fignum = fignum + 1;
    figure(fignum); clf;
    subplot(2,1,1);
    imshow(fliplr(rot90(elevPhaseMapScaled, -1)), []);
    colorbar; colormap(parula);
    title('elevation retinotopy')
    subplot(2,1,2);
    imshow(fliplr(rot90(elevMagMap, -1)), stretchlim(elevMagMap));
    colorbar; colormap(parula);
    figFilename = [trialFullStr '_map_retinotopy_elevation'];
    elevMapIdx = gray2ind(imadjust(elevPhaseMap), bit);
    elevMapRGB = ind2rgb(elevMapIdx, parula(bit));
    imwrite(fliplr(rot90(elevMapRGB, -1)), fullfile(map_path, ...
        [figFilename '.png']));
   
    % Plot azimuth map
    azimInds = find(I.CondParams(barDirParamCol) == -1);
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
    
    fignum = fignum + 1;
    figure(fignum); clf;
    subplot(2,1,1);
    imshow(fliplr(rot90(azimPhaseMapScaled, -1)), []);
    colorbar; colormap(parula);
    title('horizontal (azimuth) retinotopy')
    subplot(2,1,2);
    imshow(fliplr(rot90(azimMagMap, -1)), stretchlim(azimMagMap));
    colorbar; colormap(parula);
    figFilename = [trialFullStr 'map_retinotopy_azimuth'];   
    azimMapIdx = gray2ind(imadjust(azimPhaseMap), bit);
    azimMapRGB = ind2rgb(azimMapIdx, parula(bit));
    imwrite(fliplr(rot90(azimMapRGB, -1)), fullfile(map_path, ...
        [figFilename '.png']));
    
    save(fullfile(map_path, [trialFullStr '_map_retinotopy_azimuth.mat']), ...
        'azimPhaseMapScaled');
    save(fullfile(map_path, [trialFullStr '_map_retinotopy_elevation.mat']), ...
        'elevPhaseMapScaled');
    
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
    
    fignum = fignum + 1;
    figure(fignum); clf;
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