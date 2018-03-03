function sendtoImager(cmd)
    global imagerhandles
    global pathData prefixTrial pathBase
    global daqOUTtrig daqOUTlist
    ih = imagerhandles;
    
    switch(cmd(1))
        case 'A'  %% animal
            set(findobj('Tag', 'animaltxt'), ...
                'string', deblank(cmd(3:end)));
            set(findobj('Tag', 'pathtxt'), 'string', pathBase);
        case 'G'  %% tag
           set(findobj('Tag','tagtxt'), ...
               'string', deblank(cmd(3:end)));
           set(findobj('Tag', 'pathtxt'), 'string', pathBase);
        case 'D'  %% datadir
           set(findobj('Tag','datadirtxt'), ...
               'string', deblank(cmd(3:end)));
           set(findobj('Tag', 'pathtxt'), 'string', pathBase);
        case 'M'  %% set mode
            m = str2double(cmd(3:end-1));
        case 'I'  %% total_time
            set(findobj('Tag', 'timetxt'), 'String', deblank(cmd(3:end)));
            preallocateTensor
        case 'S'  %% start sampling...
            %animal = get(findobj('Tag', 'animaltxt'), 'string');
            %datadir = get(findobj('Tag', 'datadirtxt'), 'string');
            %tag = get(findobj('Tag', 'tagtxt'), 'string');
            %trial = str2double(cmd(3:end));
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