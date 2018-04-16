function configCom
global comState Mstate

%Modification of MP285Config, for configuration of udp port connection to visual stimulus PC (pep) 	

%comState is not initialized in the .ini file, nor is it saved in the state.headerString

% close all open serial port objects on the same port and remove
% the relevant object from the workspace
port = instrfindall('RemoteHost', Mstate.masterIDP);
if ~isempty(port)
    fclose(port); 
    delete(port);
    clear port;
end

% make udp object named 'stim'
comState.serialPortHandle = udp(Mstate.masterIDP, 'RemotePort', 8844, 'LocalPort', 8866);

%For unknown reasons, the output buffer needs to be set to the amount that the input
%buffer needs to be.  For example, we never exptect to send a packet higher
%than 512 bytes, but the receiving seems to want the output buffer to be
%high as well.  Funny things happen if I don't do this.  (For UDP)
set(comState.serialPortHandle, 'InputBufferSize', 8192)
set(comState.serialPortHandle, 'OutputBufferSize', 8192)  %This is necessary for UDP!!!
%set(comState.serialPortHandle, 'Datagramterminatemode', 'off')  %things are screwed w/o this

%Establish serial port event callback criterion
comState.serialPortHandle.BytesAvailableFcn = @Mastercb;
comState.serialPortHandle.Terminator = '~'; %Magic number to identify request from Stimulus ('c' as a string)
comState.serialPortHandle.BytesAvailableFcnMode = 'Terminator';
set(comState.serialPortHandle, 'Terminator', '~')
set(comState.serialPortHandle, 'BytesAvailableFcn', @Mastercb)
set(comState.serialPortHandle, 'BytesAvailableFcnMode', 'Terminator')

% open and check status 
fopen(comState.serialPortHandle);
stat=get(comState.serialPortHandle, 'Status');
if ~strcmp(stat, 'open')
    comState.serialPortHandle = [];
    error([mfilename ': trouble opening port; cannot proceed']);
end

%set(comState.serialPortHandle, 'BytesAvailableFcn', @Mastercb)