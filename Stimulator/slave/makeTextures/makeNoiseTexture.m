function makeNoiseTexture
    global Mstate screenPTR screenNum
    global Gtxtr TDim
    Gtxtr = [];
    TDim = [];
    P = getParamStruct;
    window = screenPTR;
    
    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    % Define black and white
    white = WhiteIndex(screenPTR);
    black = BlackIndex(screenPTR);
    grey = white / 2;
    inc = white - grey;
    
    % Assumes the screen is curved
    xcm = 2 * pi * Mstate.screenDist * (P.x_size / 360);
    xN = round(xcm * resXpxpercm);
    ycm = 2 * pi * Mstate.screenDist * (P.y_size / 360);
    yN = round(ycm * resYpxpercm);
    %number of images to present
    N_Im = round(P.stim_time * (screenRes.hz / P.h_per));
    %Downsample for the zoom
    xN = round(xN / P.x_zoom);
    yN = round(yN / P.y_zoom);

    %Set sample rates
    Fx = xN / xcm; %pixels/cm (sample rate)
    Fy = yN / ycm; %pixels/cm
    Ft = Mstate.refresh_rate; %frames/sec

    %Set Fourier domains
    Fxdom = single(linspace(-Fx/2,Fx/2,xN)); %cycles/cm
    Fydom = single(linspace(-Fy/2,Fy/2,yN)); %cycles/cm

    [Fxdom, Fydom] = meshgrid(Fxdom, Fydom);
    sf = sqrt(Fxdom.^2 + Fydom.^2);

    Ht = getFilt(N_Im,Ft,P.h_per,P.tlp_cutoff,P.thp_cutoff);
    Hxy = 1./(sf.^P.freq_decay);

    Hxy(round(yN/2),round(xN/2),:) = 0;
    Hxy = fftshift(fftshift(Hxy, 1), 2);

    stream = RandStream('mt19937ar', 'Seed', P.rseed); 
    RandStream.setGlobalStream(stream);

    % Make randomization single instead of double to save memory
    Im = rand(yN, xN, N_Im, 'single');
    Im = round(Im);
    Im = Filt_xy(Im, Hxy);
    Im = Filt_t(Im, Ht);
    Im = real(Im);
    
    switch P.tAmp_profile
        case 'sin'
            Nt = length(Im(1,1,:));
            Ncyc = Nt/P.tAmp_period;
            tdom = single(linspace(0,2*pi*Ncyc,Nt));
            A = sin(tdom);
            for i = 1:length(Im(1,1,:))
                Im(:,:,i) = Im(:,:,i) * A(i);
            end
        case 'square'
            Nt = length(Im(1,1,:));
            Ncyc = Nt/P.tAmp_period;
            tdom = single(linspace(0,2*pi*Ncyc,Nt));
            A = sign(sin(tdom));
            for i = 1:length(Im(1,1,:))
                Im(:,:,i) = Im(:,:,i) * A(i);
            end
    end
    
    Im = Im - min(Im(:));
    Im = Im * (white / max(Im(:)));
    Im = Im - grey;
    Im = Im * (P.contrast / 100) + grey;
    % Convert single to uint8 for display
    Im = uint8(Im);
    
    for i = 1:N_Im
        Gtxtr(i) = Screen(screenPTR, 'MakeTexture', Im(:,:,i));
    end
    
    TDim = size(Im);
    
function Im = Filt_xy(Im,H)
    dim = size(Im);
    for z = 1:dim(3)
        %2D FFT and filter
        Im(:,:,z) = fft2(Im(:,:,z)).*H;
        Im(:,:,z) = ifft2(Im(:,:,z));
    end

function Im = Filt_t(Im,H)
    dim = size(Im);
    Hmat = ones(dim(2), 1) * H;
    for z = 1:dim(1)
        dum = squeeze(Im(z,:,:));
        %1D FFT and filter
        dum = fft(dum,[],2).*Hmat;
        Im(z,:,:) = ifft(dum,[],2);
    end

function H = getFilt(N_Im,Ft,hper,tlp,thp)
    fdom = linspace(-Ft/hper/2,Ft/hper/2,N_Im);  %cycles/sec
    %fdom = fdom(1:end-1);
    if tlp > Ft/hper/2  %it can't be greater than the Nyquist
        Hlp = ones(1,length(fdom));
    else
        Hlp = 1./(1+(fdom./tlp).^2);
    end
    Hhp = 1./(1+(thp./fdom).^2);
    H = Hlp.*Hhp;
    H = fftshift(H);