function sendPinfo
    global Pstate DcomState

    mod = getmoduleID;
    msg = ['P;' mod];
    
    tag_time = str2double(get(findobj('tag', 'timetxt'), 'string'));
    if tag_time > 0
        Pstate.stim_time = tag_time;
    end
    
    for i = 1:length(Pstate.param)
        p = Pstate.param{i};
        switch p{2}
            case 'float'
                msg = sprintf('%s;%s=%.4f', msg, p{1}, p{3});
            case 'int'
                msg = sprintf('%s;%s=%d', msg, p{1}, round(double(p{3})));
            case 'string'
                msg = sprintf('%s;%s=%s', msg, p{1}, p{3});
        end
    end

    msg = [msg ';~'];
    fwrite(DcomState.serialPortHandle, msg);