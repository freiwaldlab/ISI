function Stimulator
    global imagerWinOffYpx

    % Initialize stimulus parameter structures, 
    % defaulting to Image Block mode
    configurePstate('IB')
    configureLstate
    configureMstate
    updateMonitorValues

    % Set up master-slave communication
    configDisplayCom

    % NI USB input for ISI acquisition timing from frame grabber
    configSyncInput  

    % No eye shutter is currently supported
    %configEyeShutter

    % Get screen information for window positioning
    scpx = get(0, 'ScreenSize');
    offy = 30;
    
    % Open the main window
    fmw = MainWindow;
    mwpx = getpixelposition(fmw);
    % Open parameter selection window
    fps = paramSelect;
    pspx = getpixelposition(fps);
    % Open the looper window
    flp = Looper;
    lppx = getpixelposition(flp);
    % Set window positions
    winHpx = max([mwpx(4) pspx(4) lppx(4)]);
    setpixelposition(fmw, [scpx(1) ...
        (scpx(4) - winHpx - offy) ...
        mwpx(3) winHpx]);
    mwpx = getpixelposition(fmw);
    setpixelposition(fps, [(scpx(1) + mwpx(3)) ...
        (scpx(4) - winHpx - offy) ...
        pspx(3) winHpx]);
    pspx = getpixelposition(fps);
    setpixelposition(flp, [(scpx(1) + mwpx(3) + pspx(3)) ...
        (scpx(4) - winHpx - offy) ...
        lppx(3) winHpx]);
   
    imagerWinOffYpx = winHpx + (2 * offy);
    
    % Open slimImager at the same time
    updateExptName
    slimImager