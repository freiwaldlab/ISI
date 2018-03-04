function makeLoop
    global Lstate GUIhandles looperInfo

looperInfo = struct;

%%% TODO *** !!! Looper needs one parameter in it... bad.
%Nparam = length(Lstate.param) %number of looper parameters
  
%Produces a cell array 'd', with each element corresponding to a different
%looper variable.  Each element contains a multidimensional array from
%meshgrid with as many elements as there are conditions. They are id's, not
%actually variable values.

if numel(Lstate.param) > 1 || ~isempty(Lstate.param{:})
    Nparam = length(Lstate.param);
    nc = 1;
else
    Nparam = 1;
    nc = 1;
    Lstate.param{1} = {'fakesymbol' '0'};
end

for i = 1:Nparam
    eval(['paramV = ' Lstate.param{i}{2} ';']);
    nc = nc * length(paramV);
    if i == 1
        istring = ['1:' num2str(length(paramV))];  % input string for 'meshgrid'
        ostring = ['d{' num2str(i) '}'];  % output string for meshgrid
    else
        istring = [istring ',1:' num2str(length(paramV))];
        ostring = [ostring ',' 'd{' num2str(i) '}'];
    end
end
istring = ['meshgrid(' istring ')'];
ostring = ['[' ostring ']'];
eval([ostring ' = ' istring ';']);

% meshgrid outputs 2D grid, even for 1D input...
if Nparam == 1
    d{1} = d{1}(1,:);
end

nr = str2double(get(GUIhandles.looper.repeats, 'string'));                      

% Create random sequence across conditions, for each repeat
for rep = 1:nr
    if get(GUIhandles.looper.randomflag, 'value')
        [~, seq{rep}] = sort(rand(1, nc));  % generate random sequence
    else                          
        seq{rep} = 1:nc;                                   
    end                      
end 

bflag = get(GUIhandles.looper.blankflag, 'value');
bPer = str2double(get(GUIhandles.looper.blankPeriod, 'string'));

% Make the analyzer structure
for c = 1:nc
    for p = 1:Nparam
        idx = d{p}(c); %index into value vector of parameter p

        paramS = Lstate.param{p}{1};
        eval(['paramV = ' Lstate.param{p}{2} ';']);  %value vector

        looperInfo.conds{c}.symbol{p} = paramS;
        looperInfo.conds{c}.val{p} = paramV(idx);
    end
    for r = 1:nr
        pres = find(seq{r} == c);
        looperInfo.conds{c}.repeats{r}.trialno = nc*(r-1) + pres;      
    end
end

% Interleave blanks
looperInfoDum = looperInfo;
blankcounter = 0;
if bflag
    for t = 1:nr*nc
        [c, r] = getcr(t, looperInfoDum, nc);

        if rem(t, bPer) == 0 && t ~= 1
            %disp([mfilename ' DEBUG: blankcounter incremented']);
            blankcounter = blankcounter + 1;
            looperInfo.conds{nc+1}.repeats{blankcounter}.trialno = t + blankcounter - 1;
        end
        looperInfo.conds{c}.repeats{r}.trialno = looperInfo.conds{c}.repeats{r}.trialno + blankcounter;
    end
end

% If the total number of trials is less than the blank period,
% then no blanks are shown.
if blankcounter > 0
    for p = 1:Nparam
        looperInfo.conds{nc+1}.symbol{p} = 'blank';
        looperInfo.conds{nc+1}.val{p} = [];
    end
end

% Put formula in looperInfo
looperInfo.formula = get(GUIhandles.looper.formula, 'string');


function [c, r] = getcr(t,looperInfo,nc)
%need to input nc so that it is always the number of conditions w/o blanks
nr = length(looperInfo.conds{1}.repeats);
for c = 1:nc
    for r = 1:nr
        if t == looperInfo.conds{c}.repeats{r}.trialno
            return
        end
    end
end