function buildStimulus(cond, trial)
% Sends loop information and buffers
    global DcomState looperInfo Mstate DataPath

    mod = getmoduleID;
    msg = ['B;' mod ';' num2str(trial)];
    bflag = strcmp(looperInfo.conds{cond}.symbol{1}, 'blank');
    
    % In case there are dependencies on Mstate in the 'formula'...
    Mf = fields(Mstate);
    for i = 1:length(fields(Mstate))
        eval([Mf{i} '= Mstate.'  Mf{i} ';' ])
    end

    if ~bflag % Not a blank condition
        % Send the contrast in Pstate in case last trial was a blank
        pval = getParamVal('contrast');
        msg = sprintf('%s;%s=%.4f', msg, 'contrast', pval);

        Nparams = length(looperInfo.conds{cond}.symbol);
        for i = 1:Nparams
            pval = looperInfo.conds{cond}.val{i};
            if iscell(pval)
                pval = strjoin(pval, '');
            end
            psymbol = looperInfo.conds{cond}.symbol{i};
            msg = updateMsg(pval, psymbol, msg);
            if ischar(pval)
                eval([psymbol '=''' pval ''';'])
            else
                eval([psymbol '=' num2str(pval) ';'])
            end
            eyefunc(psymbol, pval)
        end
        
        % Append the message with the 'formula' information
        fmla = looperInfo.formula;
        fmla(fmla == ' ') = [];
        if ~isempty(fmla)
            fmla = [';' fmla ';'];
            ide = find(fmla == '=');
            ids = find(fmla == ';' | fmla == ',');
            
            for e = 1:length(ide)
                delim1 = max(find(ids < ide(e)));
                delim1 = ids(delim1) + 1;
                delim2 = min(find(ids > ide(e)));
                delim2 = ids(delim2) - 1;
                
                try
                    eval([fmla(delim1:delim2) ';'])  % Dependencies established above
                catch ME
                    if strcmp(ME.message(1:30), 'Undefined function or variable')
                        varname = ME.message(33:end-2);
                        pval = getParamVal(varname);  % Get value from Pstate
                        eval([varname '=' num2str(pval) ';'])
                        eval([fmla(delim1:delim2) ';'])  % Try again
                    end
                end
                
                psymbol_Fmla = fmla(delim1:ide(e)-1);
                pval_Fmla = eval(psymbol_Fmla);
                % Moves eye shutters if its the right symbol
                eyefunc(psymbol_Fmla, pval_Fmla)
                msg = updateMsg(pval_Fmla, psymbol_Fmla, msg);
            end
        end
    else % Blank condition
        disp([mfilename ': Blank trial.'])
        msg = sprintf('%s;%s=%.4f', msg, 'contrast', 0);
    end
    
    if strcmpi(mod, 'IB')
        if exist('image_path', 'var')
            imPath = image_path;
        else
            imPath = getParamVal('image_path');
        end
        if exist(imPath, 'dir')
            cpdir = strcat(DataPath, filesep, 'stimuli_t', ...
                sprintf('%02d', trial));
            [cpstatus,cpmsg] = copyfile(imPath, cpdir);
            if cpstatus
                disp([mfilename ': ImageBlock stimulus images copied to ' ...
                    'data directory.']);
            else
                error([mfilename ': ImageBlock stimulus ', ...
                    'directory could not be copied (' cpmsg ')'])
            end
        else
            error([mfilename ': image_path not found.']);
        end
    end
    
    msg = [msg ';~'];
    fwrite(DcomState.serialPortHandle, msg);


function eyefunc(sym, bit)
    if strcmp(sym, 'Leye_bit')
        moveShutter(1, bit);
        waitforDisplayResp
    elseif strcmp(sym,'Reye_bit')
        moveShutter(2, bit);
        waitforDisplayResp
    elseif strcmp(sym, 'eye_bit')
        switch bit
            case 0
                moveShutter(1, 1);
                waitforDisplayResp
                moveShutter(2, 0);
                waitforDisplayResp
            case 1
                moveShutter(1, 0);
                waitforDisplayResp
                moveShutter(2, 1);
                waitforDisplayResp
            case 2
                moveShutter(1, 1);
                waitforDisplayResp
                moveShutter(2, 1);
                waitforDisplayResp
            otherwise
        end
    end
    
    
function msg = updateMsg(pval, psymbol, msg)
    global Pstate

    % Remove whitespace from user entry
    psymbol(psymbol == ' ') = [];

    % Find parameter in Pstruct
    idx = [];
    for j = 1:length(Pstate.param)
        if strcmp(psymbol, Pstate.param{j}{1})
            idx = j;
            break
        end
    end

    % Change value based on looper
    if ~isempty(idx)
        prec = Pstate.param{idx}{2};
        switch prec
            case 'float'
                msg = sprintf('%s;%s=%.4f', msg, psymbol, pval);
            case 'int'
                msg = sprintf('%s;%s=%d', msg, psymbol, round(double(pval)));
            case 'string'
                msg = sprintf('%s;%s=%s', msg, psymbol, pval);
        end
    end