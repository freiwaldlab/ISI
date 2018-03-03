function twoPFinishedRecordingTrigger(src, event)
    global daqCOUNT    
    if any(event.Data > 1.0)
        disp([mfilename ': Event listener: Detected voltage exceeds 1, acquisition stopped'])
        % Continuous acquisitions need to be stopped explicitly.
        daqCOUNT.stop;
        %plot(event.TimeStamps, event.Data)
        %else
        %    fprintf('.')
    end
end