function makeGratingTexture_flashCartesian
global Mstate screenNum
global Gtxtr TDim
Screen('Close');
Gtxtr = [];
TDim = [];
P = getParamStruct;

screenRes = Screen('Resolution', screenNum);
resXpxpercm = screenRes.width / Mstate.screenXcm;
resYpxpercm = screenRes.height / Mstate.screenYcm;
% Assumes curved screen (projects flat)
stimWcm = (2 * pi * Mstate.screenDist * P.x_size) / 360;
stimWpx = round(stimWcm * resXpxpercm);
stimHcm = (2 * pi * Mstate.screenDist * P.y_size) / 360;
stimHpx = round(stimHcm * resYpxpercm);
% Create mask
stimWpx = round(stimWpx / P.x_zoom);
stimHpx = round(stimHpx / P.y_zoom);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Create Sequence for this trial%%%%%

%Make spatial phase domain
phasedom = linspace(0,360,P.n_phase+1);
phasedom = phasedom(1:end-1);
%Make orientation domain
orirange = 180;
oridom = linspace(P.ori,P.ori+orirange,P.n_ori+1);
oridom = oridom(1:end-1);
%Make spatial frequency domain
if strcmp(P.sf_domain,'log')
    sfdom = logspace(log10(P.min_sf),log10(P.max_sf),P.n_sfreq);
elseif strcmp(P.sf_domain,'lin')
    sfdom = linspace(P.min_sf,P.max_sf,P.n_sfreq);
end
sfdom = unique(sfdom);

colordom = getColorDomain(P.colorspace);

N_Im = round(P.stim_time * screenRes.hz / P.h_per); %number of images to present

s = RandStream.create('mrg32k3a','NumStreams',1,'Seed',P.rseed);
phaseseq = randi(s,[1 length(phasedom)],1,N_Im); %N_Im random indices for the "mixed bag"
oriseq = randi(s,[1 length(oridom)],1,N_Im); %N_Im random indices for the "mixed bag"
sfseq = randi(s,[1 length(sfdom)],1,N_Im); %N_Im random indices for the "mixed bag"
colorseq = randi(s,[1 length(colordom)],1,N_Im); %N_Im random indices for the "mixed bag"

blankflag = zeros(1,N_Im);
if P.blankProb > 0
    nblanks = round(P.blankProb*N_Im);
    bidx = zeros(1,N_Im);    
    bidx(1:nblanks) = 1;
    [~, id] = sort(randn(1,N_Im));
    bidx = find(bidx(id));  %randomly shuffle
    
    %blank condition is identified with the following indices
    phaseseq(bidx) = 1;
    oriseq(bidx) = 1;
    sfseq(bidx) = length(sfdom) + 1;
    colorseq(bidx) = 1;
    blankflag(bidx) = 1;
end
    

for i = 1:N_Im    %loop through each image in the sequence
    if ~blankflag(i)
        %Compression: Change zoom based on spatial frequency in x/y dimensions
        %independently.  Spatial frequency along x/y dimensions are modulated
        %by the grating's orientation.
        %Xcycperimage = sfdom(sfseq(i)) * P.x_size; %* abs(cos(oridom(oriseq(i))*pi/180));
        %Ycycperimage = sfdom(sfseq(i)) * P.y_size; %* abs(sin(oridom(oriseq(i))*pi/180));
        %disp([mfilename ' DEBUG: regcond... Xcycperimage ' num2str(Xcycperimage) ...
        %    ' Ycycperimage '  num2str(Ycycperimage)]);
        stimWpxp = stimWpx;%min([25*Xcycperimage+1 stimWpx]); %No point in having the resolution higher than the screen
        stimHpxp = stimHpx;%min([25*Ycycperimage+1 stimHpx]);
        disp([mfilename ' DEBUG: regcond... stimWpxp ' num2str(stimWpxp) ...
            ' stimHpxp'  num2str(stimHpxp)]);
        
        x_ecc = P.x_size / 2;
        y_ecc = P.y_size / 2;
        disp([mfilename ' DEBUG: regcond... x_ecc ' num2str(x_ecc) ...
            ' y_ecc '  num2str(y_ecc)]);
        
        x_ecc = single(linspace(-x_ecc,x_ecc,stimWpxp));  %deg
        y_ecc = single(linspace(-y_ecc,y_ecc,stimHpxp));
        
        [x_ecc, y_ecc] = meshgrid(x_ecc,y_ecc);  %deg
        
        Im = buildImage(oridom(oriseq(i)), sfdom(sfseq(i)), ...
            phasedom(phaseseq(i)), x_ecc, y_ecc, P); %Make the shape
        Ix = size(Im, 1);
        Iy = size(Im, 2);
        mx = size(mask, 1);
        my = size(mask, 2);
        disp([mfilename ' DEBUG: regcond... Im size ' num2str(Ix) ...
            'x'  num2str(Iy) ', mask size ' ...
            num2str(mx) 'x' num2str(my)]);
        putinTexture(Im,colordom,colorseq(i),P,i,mask); %Put in texture as RGB
    else
        Ix = size(Im, 1);
        Iy = size(Im, 2);
        mx = size(mask, 1);
        my = size(mask, 2);
        disp([mfilename ' DEBUG: blankcond... Im size ' num2str(Ix) ...
            'x'  num2str(Iy) ', mask size ' ...
            num2str(mx) 'x' num2str(my)]);
        putinTexture(0,colordom,colorseq(i),P,i,[]); %Blank
    end
end

%Save it if 'running' experiment
if Mstate.running
    Pseq = struct;
    Pseq.phaseseq = phaseseq;
    Pseq.oriseq = oriseq;
    Pseq.sfseq = sfseq;
    Pseq.colorseq = colorseq;
    
    domains = struct;
    domains.oridom = oridom;
    domains.sfdom = sfdom;
    domains.phasedom = phasedom;
    domains.colordom = colordom;
    
    saveLog_new(domains,Pseq)
end


function temp = buildImage(ori,sfreq,phase,x_ecc,y_ecc,P)

sdom = x_ecc*cos(ori*pi/180) - y_ecc*sin(ori*pi/180); %deg
sdom = sdom*sfreq*2*pi + pi; %radians
temp = cos(sdom - phase*pi/180);  

switch P.s_profile
    case 'sin'
        temp = temp*P.contrast/100;
    case 'square'
        thresh = cos(P.s_duty*pi);
        temp = sign(temp-thresh);
        temp = temp*P.contrast/100;
    case 'pulse'
        thresh = cos(P.s_duty*pi);
        temp = (sign(temp-thresh) + 1)/2;
        temp = temp*P.contrast/100;
end


function putinTexture(Im,colordom,colorID,P,i,mask)
global Gtxtr screenPTR TDim

Ix = size(Im, 1);
Iy = size(Im, 2);
mx = size(mask, 1);
my = size(mask, 2);
disp([mfilename ' DEBUG: preHack... Im size ' num2str(Ix) ...
    'x'  num2str(Iy) ', mask size ' ...
    num2str(mx) 'x' num2str(my)]);
%%%%%%%%%%%%%%%%%%%%%%%
%This is a total hack%%
if strcmp(P.colorspace,'DKL')
    switch colordom(colorID)
        case 4 %S
            Im = Im*.16/.86 * 2;
        case 5 %L-M
            Im = Im;
        case 6 %L+M
            Im = Im*.16/1.05;
    end
elseif strcmp(P.colorspace,'LMS')
    switch colordom(colorID)
        case 2 %L
            Im = Im;
        case 3 %M
            Im = Im*.21/.24;
        case 4 %S
            Im = Im*.21/.86 * 2;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(size(Im) ~= size(mask))
    % note that this assumes both Im and mask are within the bounds of the
    % display screen pixel dimensions
    if isempty(mask) || all(size(Im) == size(mask))
        % all is good
        disp([mfilename ' DEBUG: Im and mask sizes are okay.']);
    elseif all(size(Im) >= size(mask))
        % mask is too small, must be expanded to Im dimensions
        disp([mfilename ' DEBUG: mask smaller... Im size ' num2str(Ix) ...
            'x'  num2str(Iy) ', mask size ' ...
            num2str(mx) 'x' num2str(my)]);
        maskpad = zeros(size(Im));
        maskpad(floor(Ix/2-mx/2)+1:floor(Ix/2+mx/2), floor(Iy/2-my/2)+1:floor(Iy/2+my/2)) = mask;
        mask = maskpad;
    elseif all(size(Im) <= size(mask))
        % Im is too small, must be expanded to mask dimensions
        disp([mfilename ' DEBUG: Im smaller... Im size ' num2str(Ix) ...
            'x'  num2str(Iy) ', mask size ' ...
            num2str(mx) 'x' num2str(my)]);
        Ipad = P.background * zeros(size(mask));
        Ipad(floor(mx/2-Ix/2)+1:floor(mx/2+Ix/2), floor(my/2-Iy/2)+1:floor(my/2+Iy/2)) = Im;
        Im = Ipad;
    elseif (Ix >= mx) && (my >= Iy)
        disp([mfilename ' DEBUG: mixed... Im size ' num2str(Ix) ...
            'x'  num2str(Iy) ', mask size ' ...
            num2str(mx) 'x' num2str(my)]);
        Ipad = P.background * ones(Ix,my);
        Ipad(floor(Ix/2-mx/2)+1:floor(Ix/2+mx/2), floor(my/2-Iy/2)+1:floor(my/2+Iy/2)) = Im;
        Im = Ipad;
        maskpad = zeros(Ix,my);
        maskpad(floor(Ix/2-mx/2)+1:floor(Ix/2+mx/2), floor(my/2-Iy/2)+1:floor(my/2+Iy/2)) = mask;
        mask = maskpad;
    elseif (mx >= Ix) && (Iy >= my)
        disp([mfilename ' DEBUG: mixed... Im size ' num2str(Ix) ...
            'x'  num2str(Iy) ', mask size ' ...
            num2str(mx) 'x' num2str(my)]);
        Ipad = P.background * ones(mx,Iy);
        Ipad(floor(mx/2-Ix/2)+1:floor(mx/2+Ix/2), floor(Iy/2-my/2)+1:floor(Iy/2+my/2)) = Im;
        Im = Ipad;
        maskpad = zeros(Ix,my);
        maskpad(floor(mx/2-Ix/2)+1:floor(mx/2+Ix/2), floor(Iy/2-my/2)+1:floor(Iy/2+my/2)) = mask;
        mask = maskpad;
    else
        disp([mfilename ' DEBUG: Missed a case. Check Im size and mask size.'])
    end
end
Idraw = ImtoRGB(Im, colordom(colorID), P, mask);
disp([mfilename ' DEBUG: Idraw size ' num2str(size(Idraw,1)) ...
    'x'  num2str(size(Idraw,2))]);
Gtxtr(i) = Screen(screenPTR, 'MakeTexture', Idraw);
TDim = size(Idraw(:,:,1));
TDim(3) = length(Gtxtr);
