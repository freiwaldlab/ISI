function updateMstate
    global Mstate GUIhandles
    Gh = GUIhandles;
    
    % Only contains the string 'edit text' fields.  This function is called
    % as a precaution if the user has not pressed enter after entering new
    % values/strings.

    Mstate.anim = get(Gh.main.animal, 'string');
    Mstate.hemi = get(Gh.main.hemisphere, 'string');
    Mstate.screenDist = str2double(get(Gh.main.screendistance, 'string'));
    %Mstate.analyzerRoot = get(Gh.main.analyzerRoots, 'string');
    Mstate.monitor = get(Gh.main.monitor, 'string');
    updateMonitorValues
    
    GUIhandles = Gh;