function [dispSynctimes, acqSynctimes, dsyncwave] = getSyncTimes
    global analogIN analogINdata

    Fs = analogIN.Rate;
    
    % analogINdata is a 3 x samples matrix where...
    %   (1,:) is the time each sample is taken from start
    %   (2,:) is the voltage on analog input 0: photodiode from display
    %   (3,:) is the voltage on analog input 1: TTL from camera
    syncs = analogINdata(2:3,:)';
    dispSynctimes = processLCDSyncs(syncs(:,1), Fs);
    acqSynctimes = processGrabSyncs(syncs(:,2), Fs);
    dsyncwave = syncs(:,1);

% 4 lines below are optional to save synctimes. replaces saveSync. however,
% looks like data is saved in run2 by saveSyncInfo. confirm and then delete
% 170109mmf
% % processedSynctimes = {dispSynctimes, acqSynctimes};
% % title = ['processedSynctimes ' Mstate.anim '_' sprintf('u%s',Mstate.unit) '_' Mstate.expt];
% % location = ['C:\neurodata\syncs\' title] ;
% % save(location,'processedSynctimes')  %Save only the time points (sec)