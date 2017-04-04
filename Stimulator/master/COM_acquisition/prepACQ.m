function prepACQ

%Prep Scanimage... give it trial time and hit the loop button

%total_time = getParamVal('stim_time');
predelay = getParamVal('predelay');
postdelay = getParamVal('postdelay');
tag_time = str2double(get(findobj('tag', 'timetxt'), 'string'));
total_time = predelay + postdelay + tag_time;

%Send trial length values
Stimulus_localCallback(['StimTimeInfo=' 13 ...
    num2str(total_time) 13 ...
    num2str(predelay) 13 ...
    num2str(postdelay)]);

%Tell ScanImage to hit Loop button and then wait for response:
Stimulus_localCallback('loop'); %Tell ScanImage to start 'loop' button