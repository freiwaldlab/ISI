function configureLstate
    global Lstate

    Lstate.reps = 1;
    Lstate.rand = 1;
    Lstate.blanktog = 0;
    Lstate.blankper = 1;

    %Lstate.param{1} = {'contrast' 100};
    Lstate.param{1} = {[] []};
    Lstate.param{2} = {[] []};
    Lstate.param{3} = {[] []};
    %Lstate.param{4} = {[] []};
    %Lstate.param{5} = {[] []};
    
    Lstate.formula = '';