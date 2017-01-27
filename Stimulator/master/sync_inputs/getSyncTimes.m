function [dispSynctimes, acqSynctimes, dsyncwave] = getSyncTimes

global analogIN syncs analogINdata

% Updated for MATLAB compatibility, 170109 mmf
samples = length(analogINdata);
Fs = analogIN.Rate;
syncs = analogINdata(2:3,:)';

figure(69)
hold on
plot(syncs(1:1:end,1),'r')
plot(syncs(1:1:end,2),'k')
hold off

%First channel should be from display
dispSynctimes = processLCDSyncs(syncs(:,1),Fs);
%dispSynctimes = processDaqSyncs(syncs(:,1),Fs);
%Second channel should be ttl sent off of audio or parallel port
acqSynctimes = processGrabSyncs(syncs(:,2),Fs);

dsyncwave = syncs(:,1);

% 4 lines below are optional to save synctimes. replaces saveSync. however,
% looks like data is saved in run2 by saveSyncInfo. confirm and then delete
% 170109mmf
% % processedSynctimes = {dispSynctimes, acqSynctimes};
% % title = ['processedSynctimes ' Mstate.anim '_' sprintf('u%s',Mstate.unit) '_' Mstate.expt];
% % location = ['C:\neurodata\syncs\' title] ;
% % save(location,'processedSynctimes')  %Save only the time points (sec)