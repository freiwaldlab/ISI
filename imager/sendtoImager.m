function sendtoImager(cmd)
    global imagerhandles
    
    %%% XXX *** LOOKS UNUSED, SO REMOVED... LET US SEE WHAT BREAKS
    %global fname nframes maxframes T running NBUF

    switch(cmd(1))
        case 'A'  %% animal
            set(findobj('Tag', 'animaltxt'), ...
                'String', deblank(cmd(3:end)));
            deblank(cmd(3:end))
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
            fname = sprintf('%s%su%s_%s', dd, filesep, unit, expt);
            fname = [fname  '_' sprintf('%03d', trial)];
            
            %%% XXX *** LOOKS UNUSED, SO REMOVED... LET US SEE WHAT BREAKS
            %nframes = 1;

            %mmf - I don't think we need anything other than h = imagerhandles;
            %and h = GrabSaveLoop
            %h = imagerhandles;
            %h.mildig.set('GrabFrameEndEvent',0,'GrabEndEvent',0,'GrabStartEvent',0);
            %set(1,'Name','imager :: Sampling ::');
            %drawnow;
            %%h.mildig.Image = h.buf{1};

            %set(1,'Name','imager');
            %drawnow;
            GrabSaveLoop(fname)
        otherwise
            disp('sendtoImager ERROR: Send command was not understood.');
    end