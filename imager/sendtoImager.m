function sendtoImager(cmd)
    global daqOUTtrig daqOUTlist DataPath imagerhandles
    ih = imagerhandles;
    
    switch(cmd(1))
        case 'A'  %% animal
            set(findobj('Tag', 'animaltxt'), ...
                'String', deblank(cmd(3:end)));
        case 'E' %% expt
            set(findobj('Tag', 'expttxt'),...
                'String', num2str(deblank(cmd(3:end))));
        case 'U'  %% unit
            set(findobj('Tag', 'unittxt'), ...
                'String', num2str(deblank(cmd(3:end))));
        %case 'T'  %% time tag
        %    set(findobj('Tag','tagtxt'),...
        %    'String',deblank(sprintf('%03d',str2num(cmd(3:end)))));
        case 'M'  %% set mode
            m = str2double(cmd(3:end-1));
        case 'I'  %% total_time
            set(findobj('Tag', 'timetxt'), 'String', deblank(cmd(3:end)));
            preallocateTensor
        case 'S'  %% start sampling...
            trial = str2double(cmd(3:end));
            animal = get(findobj('Tag', 'animaltxt'), 'String');
            unit = get(findobj('Tag', 'unittxt'), 'String');
            expt = get(findobj('Tag', 'expttxt'), 'String');
            datadir = get(findobj('Tag', 'datatxt'), 'String');
            tag = get(findobj('Tag', 'tagtxt'), 'String');
            dd = [datadir filesep lower(animal) filesep 'u' unit '_' expt];
            DataPath = dd;
            fname = sprintf('%s%su%s_%s', dd, filesep, unit, expt);
            fname = [fname  '_' sprintf('t%03d', trial)];
            GrabSaveLoop(fname)
        case 'C'
            % Stop video object and clean up
            if isvalid(daqOUTtrig)
                disp([mfilename ': daqOUTtrig exists, stopping.']);
                stop(daqOUTtrig);
                if event.hasListener(daqOUTtrig, 'DataRequired')
                    disp([mfilename ': daqOUTlist exists, deleting.']);
                    delete(daqOUTlist);
                    clear global daqOUTlist
                end
                outputSingleScan(daqOUTtrig, 0);
            end
            flushdata(ih.video);
            disp([mfilename ': Stopped triggering video.'])
        otherwise
            error([mfilename ': Send command was not understood.']);
    end
    
    imagerhandles = ih;