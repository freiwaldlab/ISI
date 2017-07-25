function modID = getmoduleID
    global GUIhandles

    modID = get(GUIhandles.param.module, 'value');
    switch modID
        case 1  % Periodic Grating
            modID = 'PG';
        case 2
            modID = 'FG';
        case 3
            modID = 'RD';
        case 4
            modID = 'FN';
        case 5  % Manual Mapper
            modID = 'MP';
        case 6
            modID = 'CM';
        case 7  % Image Block
            modID = 'IB';
        case 8  % Spherical Bar
            modID = 'SB';
    end