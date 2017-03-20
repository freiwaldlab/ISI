function startStimulus
% Send start command to slave and indicate module ID
    global DcomState
    
    mod = getmoduleID;
    msg = ['G;' mod ';~'];
    fwrite(DcomState.serialPortHandle, msg);