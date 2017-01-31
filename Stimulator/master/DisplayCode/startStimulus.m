function startStimulus
    global DcomState
    % Send start command to slave and indicate module ID
    mod = getmoduleID;
    msg = ['G;' mod ';~'];
    fwrite(DcomState.serialPortHandle, msg);