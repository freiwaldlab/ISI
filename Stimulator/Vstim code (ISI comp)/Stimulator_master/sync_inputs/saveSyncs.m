function saveSyncs

global Mstate analogIN analogINdata

%mmf 170109: saveSyncs wasn't called anywhere.  have instead just copied the
%save/write portion of this into 'getSyncTimes' rather than calling a
%separate function.
%samples =  get(analogIN,'samplesAcquired');
%syncs = getdata(analogIN,samples);
%synctimes = processSyncs(syncs);
%title = ['syncs ' Mstate.anim '_' sprintf('u%s',Mstate.unit) '_' Mstate.expt];
%location = ['C:\neurodata\syncs\' title] ;
%save(location,'synctimes')  %Save only the time points (sec)
%flushdata(analogIN)
