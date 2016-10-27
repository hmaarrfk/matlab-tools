function [y1 t1 y2 t2] = get_agilentDSO2012()



%
% 
% clear all
% close all

% tic
% fclose all
% Create TCP/IP object 't'. Specify server machine and port number. 
% t = tcpip('131.215.238.140',5025); 
% t = instrfind('Type', 'visa-usb','RsrcName','USB0::2391::6041::MY52011887::INSTR','Tag','' );
t = instrfind('Type', 'visa-usb'); % this will close all visa-usb objects

if isempty(t)
     t = visa('ni','USB0::2391::6041::MY52011887::INSTR'); % DSO 2000 (Christos's)
    %t = visa('agilent','USB0::2391::6052::MY52163723::INSTR'); % DSO-X 3034A (Jacob's)

    else
    fclose(t);
    t = t(1);
end




% Set size of receiving buffer, if needed. 
set(t, 'InputBufferSize', 20e6); 
set(t,'Timeout',10);
set(t,'OutputBufferSize',20e6); % set output fubber of object accordingly

% Open connection to the server. 
fopen(t); 
% info = propinfo(t);
% Transmit data to the server (or a request for data from the server). 
% fprintf(t, '*IDN?'); 

% Pause for the communication delay, if needed. 
% pause(1) 
% 
% % Receive lines of data from server 
% while (get(t, 'BytesAvailable') > 0) 
% t.BytesAvailable 
% DataReceived = fscanf(t) ;
% end 
% identify = fscanf(t,'%s');


% fprintf(t,':Single'); % single trace 
fprintf(t,':Timebase:Mode Main'); % set timebase
fprintf(t,':Acquire:Type Normal'); % set acquisition type
% fprintf(t,':Acquire:Count 1');% set number of acquisitions when in averaging mode
% fprintf(t,':Waveform:mode raw');
fprintf(t,':waveform:points:mode raw'); % allows the full buffer to be read 
fprintf(t,':Waveform:points 4000000'); % sets number of points to be read up to 4e6
fprintf(t,':DIGitize Channel1, Channel2');

operationComplete = str2double(query(t,'*OPC?')); % wait until digitization of waveform is donebefore moving on 
while ~operationComplete
    operationComplete = str2double(query(t,'*OPC?'));
end

fprintf(t,':Waveform:Source Channel1'); %select channel
fprintf(t,':Waveform:format word'); % get data back as word

fprintf(t,':Waveform:BYTEORDER LSBFirst');
preambleBlock1 = query(t,'Waveform:preamble?');
% Now send commmand to read data
fprintf(t,':WAV:DATA?');
% read back the BINBLOCK with the data in specified format and store it in
% the waveform structure. FREAD removes the extra terminator in the buffer
waveform1.RawData = binblockread(t,'uint16'); fread(t,1);




fprintf(t,':Waveform:Source Channel2'); %select channel
fprintf(t,':Waveform:format word'); % get data back as word

fprintf(t,':Waveform:BYTEORDER LSBFirst');
preambleBlock2 = query(t,'Waveform:preamble?');
% Now send commmand to read data
fprintf(t,':WAV:DATA?');
waveform2.RawData = binblockread(t,'uint16'); fread(t,1);

% read back the BINBLOCK with the data in specified format and store it in
% the waveform structure. FREAD removes the extra terminator in the buffer







fprintf(t,':RUN');
% Read back the error queue on the instrument
% instrumentError = query(t,':SYSTEM:ERR?');
% while ~isequal(instrumentError,['+0,"No error"' char(10)])
%     disp(['Instrument Error: ' instrumentError]);
%     instrumentError = query(t,':SYSTEM:ERR?');
% end
fclose(t);

% extract the data

% Maximum value storable in a INT16
maxVal = 2^16; 

%  split the preambleBlock into individual pieces of info
preambleBlock1 = regexp(preambleBlock1,',','split');

% store all this information into a waveform structure for later use
waveform1.Format = str2double(preambleBlock1{1});     % This should be 1, since we're specifying INT16 output
waveform1.Type = str2double(preambleBlock1{2});
waveform1.Points = str2double(preambleBlock1{3});
waveform1.Count = str2double(preambleBlock1{4});      % This is always 1
waveform1.XIncrement = str2double(preambleBlock1{5}); % in seconds
waveform1.XOrigin = str2double(preambleBlock1{6});    % in seconds
waveform1.XReference = str2double(preambleBlock1{7});
waveform1.YIncrement = str2double(preambleBlock1{8}); % V
waveform1.YOrigin = str2double(preambleBlock1{9});
waveform1.YReference = str2double(preambleBlock1{10});
waveform1.VoltsPerDiv = (maxVal * waveform1.YIncrement / 8);      % V
waveform1.Offset = ((maxVal/2 - waveform1.YReference) * waveform1.YIncrement + waveform1.YOrigin);         % V
waveform1.SecPerDiv = waveform1.Points * waveform1.XIncrement/10 ; % seconds
waveform1.Delay = ((waveform1.Points/2 - waveform1.XReference) * waveform1.XIncrement + waveform1.XOrigin); % seconds

% Generate X & Y Data
waveform1.XData = (waveform1.XIncrement.*(1:length(waveform1.RawData))) - waveform1.XIncrement;
waveform1.YData = (waveform1.YIncrement.*(waveform1.RawData - waveform1.YReference)) + waveform1.YOrigin; 

preambleBlock2 = regexp(preambleBlock2,',','split');

% store all this information into a waveform structure for later use
waveform2.Format = str2double(preambleBlock2{1});     % This should be 1, since we're specifying INT16 output
waveform2.Type = str2double(preambleBlock2{2});
waveform2.Points = str2double(preambleBlock2{3});
waveform2.Count = str2double(preambleBlock2{4});      % This is always 1
waveform2.XIncrement = str2double(preambleBlock2{5}); % in seconds
waveform2.XOrigin = str2double(preambleBlock2{6});    % in seconds
waveform2.XReference = str2double(preambleBlock2{7});
waveform2.YIncrement = str2double(preambleBlock2{8}); % V
waveform2.YOrigin = str2double(preambleBlock2{9});
waveform2.YReference = str2double(preambleBlock2{10});
waveform2.VoltsPerDiv = (maxVal * waveform2.YIncrement / 8);      % V
waveform2.Offset = ((maxVal/2 - waveform2.YReference) * waveform2.YIncrement + waveform2.YOrigin);         % V
waveform2.SecPerDiv = waveform2.Points * waveform2.XIncrement/10 ; % seconds
waveform2.Delay = ((waveform2.Points/2 - waveform2.XReference) * waveform2.XIncrement + waveform2.XOrigin); % seconds

% Generate X & Y Data
waveform2.XData = (waveform2.XIncrement.*(1:length(waveform2.RawData))) - waveform2.XIncrement;
waveform2.YData = (waveform2.YIncrement.*(waveform2.RawData - waveform2.YReference)) + waveform2.YOrigin; 


% toc

% Plot it
% subplot(211),plot(waveform1.XData,waveform1.YData);
% set(gca,'XTick',(min(waveform1.XData):waveform1.SecPerDiv:max(waveform1.XData)))
% xlabel('Time (s)');
% ylabel('Volts (V)');
% title('Oscilloscope Data');
% grid on;
% subplot(212),plot(waveform2.XData,waveform2.YData);
% set(gca,'XTick',(min(waveform2.XData):waveform2.SecPerDiv:max(waveform2.XData)))
% xlabel('Time (s)');
% ylabel('Volts (V)');
% title('Oscilloscope Data');
% grid on;


% output = fscanf(t,'%f');

% fprintf(t,':Waveform:Source:Channel3')
% [y,t] = fscanf(t,'%f %f');

% disp(response);
% fprintf(t,'*CLS');
% fprintf(t,'*RST');



% npoints = fscanf(t);




% Disconnect and clean up the server connection. 
 
% delete(t); 
% clear t 
t1 = waveform1.XData;
y1 = waveform1.YData;
t2 = waveform2.XData;
y2 = waveform2.YData;

end

