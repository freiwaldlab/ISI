function playgrating_flashCartesian
%This one uses the sequences that were already defined in the make file
    global Mstate screenPTR screenNum
    global Gtxtr TDim  % from makeGratingTexture_flashCartesia
    global Stxtr % from makeSyncTexture
    syncHigh = Stxtr(1);
    syncLow = Stxtr(2);

    P = getParamStruct;
    window = screenPTR;
    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    syncWpx = round(resXpxpercm * Mstate.syncSize);
    syncHpx = round(resYpxpercm * Mstate.syncSize);
    % ifi = Screen('GetFlipInterval', window);
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = (white + black) / 2;
    inc = white - grey;
    if strcmp(P.altazimuth, 'none')
       stimWcm = 2 * pi * Mstate.screenDist * (P.x_size / 360);
       stimWpx = round(resXpxpercm * stimWcm);
       stimHcm = 2 * pi * Mstate.screenDist * (P.y_size / 360);
       stimHpx = round(resYpxpercm * stimHcm);
    else
       stimWcm = 2 * Mstate.screenDist * tan((P.x_size / 2) * (pi / 180));
       stimWpx = round(resXpxpercm * stimWcm);
       stimHcm = 2 * Mstate.screenDist * tan((P.y_size / 2) * (pi / 180));
       stimHpx = round(resYpxpercm * stimHcm);
    end
    rngXpx = [(P.x_pos - floor(stimWpx / 2) + 1) ...
       (P.x_pos + ceil(stimWpx / 2))];
    rngYpx = [(P.y_pos - floor(stimHpx / 2) + 1) ...
       (P.y_pos + ceil(stimHpx / 2))];
    syncPos = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    syncPiece = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    stimPos = [rngXpx(1) rngYpx(1) rngXpx(2) rngYpx(2)]';
    %stimPiece = [0 0 imWpx imHpx]';

Npreframes = ceil(P.predelay*screenRes.hz);
Npostframes = ceil(P.postdelay*screenRes.hz);
N_Im = round(P.stim_time*screenRes.hz/P.h_per); %number of images to present

srcrect = [0 0 TDim(1) TDim(2)]';

Screen(screenPTR, 'FillRect', P.background)

% Commented 170109 mmf, no slave Daq
% %Wake up the daq:
% %do this at the beginning because it improves timing on the first call to daq below
%DaqDOut(daq, 0, 0);

%%%Play predelay %%%%
Screen('DrawTexture', screenPTR, Stxtr(1),syncPiece,syncPos);
Screen(screenPTR, 'Flip');
% Commented 170109 mmf, no slave Daq
%if loopTrial ~= -1
%    digWord = 7;  %Make 1st,2nd,3rd bits high
%    DaqDOut(daq, 0, digWord);
%end
for i = 2:Npreframes
    Screen('DrawTexture', screenPTR, Stxtr(2),syncPiece,syncPos);
    Screen(screenPTR, 'Flip');
end

%%%%%Play whats in the buffer (the stimulus)%%%%%%%%%%

%Unlike periodic grater, this doesn't produce a digital sync on last frame, just
%the start of each grating.  But this one will always show 'h_per' frames on
%the last grating, regardless of 'stimtime'.
    
for i = 1:N_Im
    
    Screen('DrawTextures', screenPTR, [Gtxtr(i) Stxtr(2-rem(i,2))],[],[stimPos syncPos]);
    
    Screen(screenPTR, 'Flip');
    %digWord = bitxor(digWord,4);  %toggle only the 3rd bit on each grating update
    %DaqDOut(daq,0,digWord);
    for j = 2:P.h_per                  %sync flips on each update
        Screen('DrawTextures', screenPTR, [Gtxtr(i) Stxtr(2-rem(i,2))],...
            [],[stimPos syncPos]);
        
        Screen(screenPTR, 'Flip');
    end
end

    

%%%Play postdelay %%%%
for i = 1:Npostframes-1
    Screen('DrawTexture', screenPTR, Stxtr(2),syncPiece,syncPos);
    Screen(screenPTR, 'Flip');
end
Screen('DrawTexture', screenPTR, Stxtr(1),syncPiece,syncPos);
Screen(screenPTR, 'Flip');
%digWord = bitxor(digWord,7); %toggle all 3 bits (1st/2nd bits go low, 3rd bit is flipped)
%DaqDOut(daq, 0,digWord);  

% Commented 170109 mmf, no slave Daq
%if loopTrial ~= -1
%    DaqDOut(daq, 0, 0);  %Make sure 3rd bit finishes low
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('DrawTexture', screenPTR, Stxtr(2),syncPiece,syncPos);  
Screen(screenPTR, 'Flip');