function configSyncInput

global analogIN

%legacy code. no longer supported by matlab. mmf
% analogIN = analoginput('nidaq','Dev1');
% set(analogIN, 'SampleRate', 10000);
% actualInputRate = get(analogIN, 'SampleRate');
% addchannel(analogIN,[0 1]);
% set(analogIN,'SamplesPerTrigger',inf);

analogIN = daq.createSession('ni');
addAnalogInputChannel(analogIN,'Dev1',0:1,'Voltage');
analogIN.Rate = 5000; %rate is determined by maximum on device/number of channels
actualInputRate = analogIN.Rate; %to account for rounding done by system
analogIN.IsContinuous = true;