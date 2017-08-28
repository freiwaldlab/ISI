function saveLog(x, varargin)
    global Mstate loopTrial pathBase
%An important thing to note on the way this is saved:  Since domains are
%only saved once, I can't put variables in the looper that
%would change this.  Also, rseeds are saved on top of each other. The
%sequences would also change if other parameters change, such as nori.

title = [Mstate.anim];% '_' Mstate.unit '_' Mstate.expt];
fname = [pathBase title '.mat'];
frate = Mstate.refresh_rate;

if isempty(varargin)  %from 'make'  (happens on first trial only)... save domains and frame rate
    domains = x; 
    %save(fname, 'domains', 'frate', '-v6');
else %from 'play'... save sequence as 'rseedn'
    eval(['rseed' num2str(varargin{1}) '=x;' ]);
    %eval(['save ' fname ' rseed' num2str(varargin{1}) ' -v6 -append']);
end

%%%The following version would save the domains on each trial (but I haven't tested it).
%I would also have to change the conditional statement that calls it in the
%make file

if isempty(varargin)  %from 'make'  (happens on first trial only)... save domains and frame rate
    eval(['domains' num2str(loopTrial) '= x']);     
    %eval(['save ' fname 'domains' num2str(loopTrial) ' -v6 -append']);
else %from 'play'... save sequence as 'rseedn'
    eval(['rseed' num2str(varargin{1}) '=x;' ]);
    %eval(['save ' fname ' rseed' num2str(varargin{1}) ' -v6 -append']);
end

warning([mfilename ': Fix saveLog directory handling!']);