function configSyncInput

global analogIN

% Session based interface. 
% Updated for MATLAB compatibility, 170109 mmf
analogIN = daq.createSession('ni'); 
addAnalogInputChannel(analogIN,'Dev1',0:1,'Voltage');
analogIN.Rate = 5000; %rate is determined by maximum on device/number of channels
actualInputRate = analogIN.Rate; %to account for rounding done by system
analogIN.IsContinuous = true;

%legacy code. no longer supported by matlab. mmf
% analogIN = analoginput('nidaq','Dev1');
% set(analogIN, 'SampleRate', 10000);
% actualInputRate = get(analogIN, 'SampleRate');
% addchannel(analogIN,[0 1]);
% set(analogIN,'SamplesPerTrigger',inf); 


% % % % % %testing code here on down. should be able to delete it
% % % % %creating log for the data
% % % % fid1 = fopen('log.bin','w');
% % % % 
% % % % %should be put in run/run2 i thnk
% % % % %lh = addlistener(analogIN,'DataAvailable',@(src, event)logData(src, event, fid1));
% % % % %lh = addlistener(analogIN,'DataAvailable',@(src,event) plot(event.TimeStamps, event.Data))
% % % % % function plotData(src,event)
% % % % %      plot(event.TimeStamps, event.Data)
% % % % % end
% % % % 
% % % % lh = addlistener(analogIN,'DataAvailable',@(src, event)logData(src, event, fid1));
% % % % analogIN.startBackground;
% % % % pause(5);
% % % % fclose(fid1);
% % % % 
% % % % analogIN.stop;
% % % % delete(lh);
% % % % 
% % % % fid2 = fopen('log.bin','r');
% % % % [analogINdata,count] = fread(fid2,[3,inf],'double');
% % % % %[data,count] = fread(fid2,[3,inf],'double');
% % % % fclose(fid2);
% % % % 
% % % % t = analogINdata(1,:);
% % % % ch = analogINdata(2:3,:);
% % % % plot(t, ch);
