function saveLog_rain(x, varargin)
global Mstate pathBase

expt = [Mstate.anim '_' Mstate.unit '_' Mstate.expt];
fname = [pathBase expt '.mat'];
frate = Mstate.refresh_rate;

if isempty(varargin)  %from 'make' (happens on first trial only)
    if ~exist(fname)
        save(fname, 'domains', 'frate', '-v6');
    end
else %from 'play'
    eval(['rseed' num2str(varargin{1}) '=x;' ]);
    eval(['save ' fname ' rseed' num2str(varargin{1}) ' -v6 -append']);
end

size(x)
warning([mfilename ': Fix saveLog_rain directory handling!']);