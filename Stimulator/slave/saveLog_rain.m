function saveLog_rain(x, varargin)
global Mstate

root = 'C:\Dropbox\ExperimentLogs\';
expt = [Mstate.anim '_' Mstate.unit '_' Mstate.expt];
fname = [root expt '.mat'];
frate = Mstate.refresh_rate;

if isempty(varargin)  %from 'make' (happens on first trial only)
    domains = x; 
    if ~exist(fname)
        save(fname, 'domains', 'frate', '-v6');
    end
else %from 'play'
    eval(['rseed' num2str(varargin{1}) '=x;' ]);
    eval(['save ' fname ' rseed' num2str(varargin{1}) ' -v6 -append']);
end