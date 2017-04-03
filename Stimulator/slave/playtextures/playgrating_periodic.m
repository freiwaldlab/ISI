function playgrating_periodic

global Mstate screenPTR screenNum %loopTrial 
global Gtxtr TDim %daq  %Created in makeGratingTexture
global Stxtr % from makeSyncTexture
syncHigh = Stxtr(1);
syncLow = Stxtr(2);

P = getParamStruct;
window = screenPTR;
screenRes = Screen('Resolution', screenNum);
pixpercmX = screenRes.width / Mstate.screenXcm;
pixpercmY = screenRes.height / Mstate.screenYcm;

syncWX = round(pixpercmX * Mstate.syncSize);
syncWY = round(pixpercmY * Mstate.syncSize);

white = WhiteIndex(screenPTR); % pixel value for white
black = BlackIndex(screenPTR); % pixel value for black
gray = (white + black) / 2;
amp = white - gray;

if strcmp(P.altazimuth, 'none')
    %The following assumes the screen is curved
    xcm = 2*pi*Mstate.screenDist*P.x_size/360;  %stimulus width in cm
    xN = round(xcm*pixpercmX);  %stimulus width in pixels
    ycm = 2*pi*Mstate.screenDist*P.y_size/360;   %stimulus height in cm
    yN = round(ycm*pixpercmY);  %stimulus height in pixels
else
    xN = 2*Mstate.screenDist*tan(P.x_size/2*pi/180);  %grating width in cm
    xN = round(xN*pixpercmX);  %grating width in pixels
    yN = 2*Mstate.screenDist*tan(P.y_size/2*pi/180);  %grating height in cm
    yN = round(yN*pixpercmY);  %grating height in pixels
end

%Note: I used to truncate these things to the screen size, but it is not
%needed.  It also messes things up.
xran = [P.x_pos-floor(xN/2)+1  P.x_pos+ceil(xN/2)];
yran = [P.y_pos-floor(yN/2)+1  P.y_pos+ceil(yN/2)];

cycles = P.stim_time/(P.t_period/screenRes.hz);
Nlast = round(TDim(3)*(cycles-floor(cycles)));  %number of frames on last cycle

nDisp = TDim(3) * ones(1, floor(cycles));  %vector of the number of frames for N-1 cycles
if Nlast >= 2 %Need one for sync start, and one for stop
    nDisp = [nDisp Nlast];  %subtract one because of last sync pulse 
elseif Nlast == 1  %This is an annoying circumstance because I need one frame for sync start
                    %and one for sync stop.  I just get rid of it as a hack.
    cycles = cycles - 1;
end

nDisp(end) = nDisp(end) - 1; %subtract one because of last sync pulse

Npreframes = ceil(P.predelay * screenRes.hz);
Npostframes = ceil(P.postdelay * screenRes.hz);
syncPos = [0 0 syncWX-1 syncWY-1]';
syncPiece = [0 0 syncWX-1 syncWY-1]';
stimPos = [xran(1) yran(1) xran(2) yran(2)]';
stimPiece = [0 0 TDim(2)-1 TDim(1)-1]';

Screen(screenPTR, 'FillRect', P.background)

% %%%Play predelay %%%%
% Screen('DrawTexture', screenPTR, syncHigh, syncPiece, syncPos);
% Screen(screenPTR, 'Flip');
% for i = 2:Npreframes
%     Screen('DrawTexture', screenPTR, syncLow, syncPiece, syncPos);
%     Screen(screenPTR, 'Flip');
% end
    % Pre-delay
    % Draw "high" sync state for first half of pre-delay to indicate 
    % beginning of new block
    Screen('DrawTexture', window, syncHigh, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay / 2);
    % Draw "low" sync state during rest of pre-delay
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay / 2);

%%%%%%Play sound also%%%%%%
switch P.sound_type
    case 0
        
    case 1
        d = P.stim_time; f = P.tone_freq; Fs = 22050;
        soundwave = audioplayer(sin(linspace(0, d*f*2*pi, round(d*Fs))),Fs);        
        play(soundwave);
    case 2
        d = P.stim_time; Fs = 22050;
        soundwave = audioplayer(randn(d*Fs,1)/2,Fs);
        play(soundwave);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%Play whats in the buffer (the stimulus)%%%%%%%%%%
for j = 1:ceil(cycles)
    Screen('DrawTextures', screenPTR, [Gtxtr(1) syncHigh],[stimPiece syncPiece],[stimPos syncPos]);
    Screen(screenPTR, 'Flip');
    for i=2:nDisp(j)
        Screen('DrawTextures', screenPTR, [Gtxtr(i) syncHigh],[stimPiece syncPiece],[stimPos syncPos]);
        Screen(screenPTR, 'Flip');
    end
end
Screen('DrawTextures', screenPTR, [Gtxtr(nDisp(j)+1) syncLow],[stimPiece syncPiece],[stimPos syncPos]);
Screen(screenPTR, 'Flip');  %Show sync on last frame of stimulus

%%%Play postdelay %%%%
for i = 1:Npostframes-1
    Screen('DrawTexture', screenPTR, syncLow,syncPiece,syncPos);
    Screen(screenPTR, 'Flip');
end
Screen('DrawTexture', screenPTR, syncHigh,syncPiece,syncPos);
Screen(screenPTR, 'Flip');

Screen('DrawTexture', screenPTR, syncLow,syncPiece,syncPos);  
Screen(screenPTR, 'Flip');