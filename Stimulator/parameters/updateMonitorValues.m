function updateMonitorValues
    global Mstate
    msgpre = 'updateMonitorValues';

    % Correct pixel values are not important because the stimulus computer
    % asks for the actual value anyway.
    % It only matters if the analysis needs the right number of pixels 
    % (like retinotopy stimuli).

    switch Mstate.monitor
       case 'VPX'
            Mstate.screenXcm = 52.07;
            Mstate.screenYcm = 29.21;
            Mstate.xpixels = 1920;
            Mstate.ypixels = 1080;
        case 'LCD' 
            Mstate.screenXcm = 33.7;
            Mstate.screenYcm = 27;
            Mstate.xpixels = 1024;
            Mstate.ypixels = 768;
        case 'CRT'
            Mstate.screenXcm = 30.5;
            Mstate.screenYcm = 22;
            Mstate.xpixels = 1024;
            Mstate.ypixels = 768;
        case 'TEL'
            Mstate.screenXcm = 121;
            Mstate.screenYcm = 68.3;
            Mstate.xpixels = 1024;
            Mstate.ypixels = 768;
       case '40in'
            Mstate.screenXcm = 88.8;
            Mstate.screenYcm = 50;
            Mstate.xpixels = 1024;
            Mstate.ypixels = 768;
       case 'LIN'
            Mstate.screenXcm = 52.07;
            Mstate.screenYcm = 29.21;
        otherwise
            disp([msgpre ' WARNING: monitor not recognized, assuming LIN.']);
            Mstate.screenXcm = 52.07;
            Mstate.screenYcm = 29.21;
    end