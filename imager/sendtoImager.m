function sendtoImager(cmd)
    global imagerhandles
    global pathData prefixTrial
    global daqOUTtrig daqOUTlist
    ih = imagerhandles;
    
    switch(cmd(1))
        case 'A'  %% animal
            set(findobj('Tag', 'animaltxt'), ...
                'string', deblank(cmd(3:end)));
        %case 'E' %% expt
        %    set(findobj('Tag', 'expttxt'),...
        %        'string', num2str(deblank(cmd(3:end))));
        %case 'U'  %% unit
        %    set(findobj('Tag', 'unittxt'), ...
        %        'string', num2str(deblank(cmd(3:end))));
        %case 'T'  %% time tag
        %    set(findobj('Tag','tagtxt'),...
        %    'String',deblank(sprintf('%03d',str2num(cmd(3:end)))));
        case 'M'  %% set mode
            m = str2double(cmd(3:end-1));
        case 'I'  %% total_time
            set(findobj('Tag', 'timetxt'), 'String', deblank(cmd(3:end)));
            preallocateTensor
        case 'S'  %% start sampling...
            animal = get(findobj('Tag', 'animaltxt'), 'string');
            %unit = get(findobj('Tag', 'unittxt'), 'string');
            %expt = get(findobj('Tag', 'expttxt'), 'string');
            datadir = get(findobj('Tag', 'datatxt'), 'string');
            tag = get(findobj('Tag', 'tagtxt'), 'string');
            trial = str2double(cmd(3:end));
            GrabSaveLoop(pathData, prefixTrial)
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
            clearvars -global Tens FrameTimes
        otherwise
            error([mfilename ': Send command was not understood.']);
    end
    
    imagerhandles = ih;