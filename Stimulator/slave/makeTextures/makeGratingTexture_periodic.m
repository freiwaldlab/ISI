function makeGratingTexture_periodic
    % Make single periodic grating cycle
    global screenPTR screenNum
    global Mstate
    global Gtxtr TDim
    Gtxtr = []; 
    TDim = [];
    P = getParamStruct;
    window = screenPTR;
    
    disp([mfilename ': screenXcm ' num2str(Mstate.screenXcm)]);
    disp([mfilename ': screenYcm ' num2str(Mstate.screenYcm)]);
    screenRes = Screen('Resolution', screenNum)
    resXpxpercm = screenRes.width / Mstate.screenXcm
    resYpxpercm = screenRes.height / Mstate.screenYcm

    if strcmp(P.altazimuth, 'none')
        % Assumes curved screen (projects flat)
        stimWcm = (2 * pi * Mstate.screenDist * P.x_size) / 360;
        stimWpx = round(stimWcm * resXpxpercm);
        stimHcm = (2 * pi * Mstate.screenDist * P.y_size) / 360;
        stimHpx = round(stimHcm * resYpxpercm);
    else
        % Assumes flat screen (projects spherical)
        stimWpx = 2 * Mstate.screenDist * tan(P.x_size/2 * pi/180);
        stimWpx = round(stimWpx * resXpxpercm);
        stimHpx = 2 * Mstate.screenDist * tan(P.y_size/2 * pi/180);
        stimHpx = round(stimHpx * resYpxpercm);
    end
    
    % Downsample for the zoom
    stimWpx = round(stimWpx / P.x_zoom)
    stimHpx = round(stimHpx / P.y_zoom)
    
    % Create mask
    xdom = linspace(-P.x_size/2, P.x_size/2, stimWpx);
    ydom = linspace(-P.y_size/2, P.y_size/2, stimHpx);
    [xdom, ydom] = meshgrid(xdom, ydom);
    r = sqrt(xdom.^2 + ydom.^2);
    if strcmp(P.mask_type, 'disc')
        mask = zeros(size(r));
        mask(r <= P.mask_radius) = 1;
    elseif strcmp(P.mask_type, 'gauss')
        mask = exp((-r.^2) / (2 * P.mask_radius^2));
    else
        mask = [];
    end
    mask = single(mask);

    [sdom, tdom, x_ecc, y_ecc] = makeGraterDomain_beta(stimWpx, stimHpx, P.ori, ...
        P.s_freq, P.t_period, P.altazimuth);
    if P.plaid_bit
        %Ignoring t_period2 for now, and just setting it to t_period
        AZ2 = P.altazimuth;
        [sdom2, tdom2, x_ecc2, y_ecc2] = makeGraterDomain(stimWpx, stimHpx, P.ori2, ...
            P.s_freq2, P.t_period, AZ2);
    end
    disp([mfilename ': tdom length ' num2str(length(tdom))]);

    flipbit = 0;
    if ~P.separable
        Gtxtr = NaN(1, length(tdom));
        for i = 1:length(tdom)
            Im = makePerGratFrame_insep(sdom, tdom, i, 1);
            if P.plaid_bit
                Im = makePerGratFrame_insep(sdom2, tdom2, i, 2) + Im;
            end
            if P.noise_bit
                if rem(i, P.noise_lifetime) == 1
                    %nwx = round(P.noise_width/P.x_zoom);
                    %nwy = round(P.noise_width/P.y_zoom);
                    %noiseIm = makeNoiseIm(size(Im),nwx,nwy,P.noise_type);
                    noiseIm = makeNoiseIm(size(Im), P, x_ecc, y_ecc);
                    flipbit = 1 - flipbit;
                    if flipbit
                        noiseIm = 1 - noiseIm;
                    end
                end
                Im = Im - (2 * noiseIm);
                Im(Im(:) < -1) = -1;
            end
            ImRGB = ImtoRGB(Im,P.colormod,P,mask);
            Gtxtr(i) = Screen('MakeTexture', window, ImRGB);
        end
    else
        [amp, temp] = makeSeparableProfiles(tdom, sdom, x_ecc, y_ecc, 1);
        if P.plaid_bit
            [amp2, temp2] = makeSeparableProfiles(tdom2, sdom2, x_ecc2, ...
                y_ecc2, 2);
        end
        
        Gtxtr = NaN(1, length(tdom));
        for i = 1:length(tdom)
            Im = amp(i) * temp;
            if P.plaid_bit
                Im = Im + (amp2(i) * temp2);
            end
            ImRGB = ImtoRGB(Im, P.colormod, P, mask);
            Gtxtr(i) = Screen('MakeTexture', window, ImRGB);
        end
    end
    
    TDim = size(ImRGB(:,:,1));
    TDim(3) = length(Gtxtr);