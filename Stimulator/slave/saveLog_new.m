function saveLog_new(domains, seqs)
global Mstate loopTrial

root = 'C:\Dropbox\ExperimentLogs\';
expt = [Mstate.anim '_' Mstate.unit '_' Mstate.expt];
fname = [root expt '.mat'];
frate = Mstate.refresh_rate;
basename = ['randlog_T' num2str(loopTrial)];

eval([basename '.seqs = seqs;'])
eval([basename '.domains = domains;'])

if loopTrial == 1
    save(fname, ['randlog_T' num2str(loopTrial)], '-v6');
    save(fname,'frate', '-v6', '-append');
else
    save(fname, ['randlog_T' num2str(loopTrial)], '-v6', '-append');
end