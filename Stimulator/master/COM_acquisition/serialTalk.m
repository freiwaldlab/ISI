function out=serialTalk(in)
	out=[];
	global serialstate

	if isempty(serialstate.serialPortHandle)
		error([mfilename ': Stimulus not configured']);
	end
 
	if nargin < 2
		verbose=0;
	end 

	n=get(serialstate.serialPortHandle,'BytesAvailable');
	if n > 0
		temp=fread(serialstate.serialPortHandle,n); 
	end

	fwrite(serialstate.serialPortHandle, [in 13]);
	
	temp=StimulusReadAnswer;
	temp=temp';
	if isempty(temp)
		error([mfilename ': Stimulus timed out.']);
	else
		if length(temp)>1 || temp(1)~=13
			warning([mfilename ': Stimulus did not return 13.']);
		end

		disp([mfilename ': Stimulus returned [' num2str(double(temp)) '] = ' char(temp(1:end-1))]);
	end
	out=temp;