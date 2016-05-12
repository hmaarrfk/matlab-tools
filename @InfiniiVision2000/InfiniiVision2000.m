classdef InfiniiVision2000 < handle
  properties
    scope_handle;
    usb_str_name;
  end

  methods
    function self = InfiniiVision2000(ManufacturerID_hex, ModelCode_hex, SerialNumber_str, InterfaceNumber_str)
      % To call it for the Oscilloscope Christos Bought:
      % scope = InfiniiVision2000(['0x', dec2hex(2391, 4)], ['0x', dec2hex(6041, 4)], 'MY52011887');
      %
      if nargin < 1; ManufacturerID_hex = ['0x', dec2hex(2391, 4)]; end
      if nargin < 2; ModelCode_hex = ['0x', dec2hex(6041, 4)];      end
      if nargin < 3; SerialNumber_str = 'MY52011887';               end
      if nargin < 4; InterfaceNumber_str = num2str(0);              end

      self.usb_str_name = ...
        ['USB0::', ManufacturerID_hex, '::', ModelCode_hex, '::', ...
         SerialNumber_str, '::', InterfaceNumber_str, '::INSTR'];
      self.open();
    end % Constructor

    function open(self)
      self.scope_handle = instrfind('Type', 'visa-usb', 'RsrcName', self.usb_str_name);
      delete(self.scope_handle); % delete all those that were found

      self.scope_handle = visa('ni', self.usb_str_name);

      % By default the buffer size is small, so make it bigger
      set(self.scope_handle, 'InputBufferSize', 20e6);
      set(self.scope_handle, 'Timeout', 20);
      set(self.scope_handle, 'OutputBufferSize', 20e6); % set output fubber of object accordingly

      fopen(self.scope_handle);
    end % open

    function close(self)
      %if ~isempty(self.scope_handle)
      if self.scope_handle.isvalid
        fclose(self.scope_handle);
      end
    end % close

    function delete(self)
      self.close();
    end % delete

    function send(self, s)
      fprintf(self.scope_handle, s);
    end

    function r = receive(self)
      r = fscanf(self.scope_handle, '%s');
    end
    function r = query(self, s)
      self.send(s);
      r = self.receive();
    end

    function err = check_instrument_errors(self)
      err_raw = self.query(':SYSTem:ERRor?');
      [err_num, err_str] = strtok(err_raw, ',');
      err_num = str2double(err_num);
      err_str(1) = []; % remove the ,
      err_str(1) = []; % remote the "
      err_str(end) = []; % remove the new line
      err_str(end) = []; % remove the "

      err.num = err_num;
      err.str = err_str;
    end

    function errs = check_all_instrument_errors(self)
      errs = {};
      while true
        this_err = self.check_instrument_errors();
        if this_err.num == 0
          break
        end

        errs{end+1} = this_err;
      end

      if ~isempty(errs)
        fprintf('There were %d errors from the scope. Please check them and fix the MATLAB code', length(errs));
      end
    end

    function edge_trigger(self, source, slope, level)
      self.send(':TRIGger:MODE Edge');
      self.send([':TRIGger:EDGE:SOURce ', source]);
      self.send([':TRIGger:EDGE:SLOPe ', slope]);
      self.send(sprintf(':TRIGger:EDGE:LEVel %e', level));
    end

    function position = timebasePosition(self, position)
      % POSITION in seconds
      % If one argument is given, then the position is set
      % If no arguments are given, then the position is queried
      if nargin < 2
        position = str2double(query(self.scope_handle, ':TIMebase:POSition?'));
      else
        self.send([':TIMebase:POSition ', num2str(position, '%e')]);
      end
    end

    function holdoff = holdOffTime(self, holdoff)
      if nargin < 2
        holdoff = str2double(query(self.scope_handle, ':TRIGger:HOLDoff?'));
      else
        self.send([':TRIGger:HOLDoff ', num2str(holdoff, '%e')]);
      end
    end
    function range = timebaseRange(self, range)
      % range in seconds
      % If one argument is given, then the position is set
      % If no arguments are given, then the position is queried
      if nargin < 2
        range = str2double(query(self.scope_handle, ':TIMebase:RANGe?'));
      else
        self.send([':TIMebase:RANGe ', num2str(range, '%e')]);
      end
    end
    function actual_period = autorangeTime(self, trigger_source, period_estimate)
      % multiply the period by 20 so that the scope has a few periods to count
      self.send(sprintf(':TIMebase:RANGe %e', period_estimate*20));
      self.send(sprintf(':TIMebase:POSition %e', (period_estimate*20)/2));
      actual_period = str2double(self.query([':MEASure:PERiod? ', trigger_source]));

      self.send(sprintf(':TIMebase:RANGe %e', actual_period));
      self.send(sprintf(':TIMebase:POSition %e', actual_period/2));
    end

    function autorange(self, source, vmin_search, vmax_search, extent_multiplier)
      if nargin < 3; vmin_search = -20; end
      if nargin < 4; vmax_search = +20; end
      if nargin < 5; extent_multiplier = 1.2; end

      self.setVoltageExtent(source, vmin_search, vmax_search);
      pause(1);
      [vmin, vmax] = self.getVoltageExtent(source);

      v_mean =  (vmax + vmin) / 2;
      v_delta = (vmax - vmin) / 2;
      vmin = v_mean - v_delta*extent_multiplier;
      vmax = v_mean + v_delta*extent_multiplier;

      self.setVoltageExtent(source, vmin, vmax);
      pause(1);
    end

    function [vmin, vmax] = getVoltageExtent(self, source)
      vmax = str2double(self.query(sprintf([':MEASure:VMAX? ', source])));
      vmin = str2double(self.query(sprintf([':MEASure:VMIN? ', source])));
    end

    function setVoltageExtent(self, source, vmin, vmax, range_multiplier)
      if nargin < 5
        range_multiplier = 1.1;
      end
      self.send(sprintf(':%s:RANGe %e V', source, (vmax - vmin) * range_multiplier));
      self.send(sprintf(':%s:OFFSet %e V', source, (vmax + vmin) /2));
    end

    function saveScreen(self, filename, format, palette)
      if nargin < 3
        format = 'PNG';
      end
      if nargin < 4
        palette = 'COLor';
      end


      self.send([':DISPlay:DATA? ', format, ', ', palette]);
      screen_data = binblockread(self.scope_handle, 'uint8');
      fread(self.scope_handle, 1); %read the termination character

      fid = fopen(filename, 'wb');
      fwrite(fid, screen_data);
      fclose(fid);
    end

    function waveforms = singleTrace(self, sources)
      if nargin < 2
        sources = {};
        sources{1} = 'CHANnel1';
      end

      self.send(':Timebase:MODE Main'); % set timebase
      %self.send(':Acquire:TYPE Normal'); % set acquisition type
      self.send(':ACQuire:TYPE HRESolution');
      self.send(':WAVeform:points MAXimum'); % sets number of points to be read up to 4e6
      s = [':DIGitize ', sources{1}];
      for i = 2:length(sources)
        s = [s, ',', sources{i}];
      end
      self.send(s); %':DIGitize CHANnel1');

      operationComplete = str2double(query(self.scope_handle, '*OPC?')); % wait until digitization of waveform is donebefore moving on
      while ~operationComplete
          operationComplete = str2double(query(self.scope_handle, '*OPC?'));
      end

      waveforms = cell(size(sources));
      for i = 1:length(sources)
        waveforms{i}.source_name = sources{i};

        % Specify how the data should be sent to the computer
        self.send([':WAVeform:SOURce ', sources{i}]); %select channel

        self.send(':WAVeform:POINts:MODE RAW'); % allows the full buffer to be read

        self.send(':WAVeform:FORMat word'); % get data back as word
        self.send(':WAVeform:UNSigned ON');
        self.send(':WAVeform:BYTeorder LSBFirst');
        preambleBlock = query(self.scope_handle, 'WAVeform:preamble?');

        % Now send commmand to read data
        self.send(':WAV:DATA?');
        % Special meaning values:
        % 0x0000 - Hole: locations where data was not acquired
        % 0x0001 - clipped low
        % 0xFFFF - clipped high


        % read back the BINBLOCK with the data in specified format and store it in
        % the waveform structure.
        % binblockread seems to read in lsbfirst

        waveforms{i}.RawData = binblockread(self.scope_handle, 'uint16');
        %FREAD removes the extra terminator in the buffer
        fread(self.scope_handle, 1);

        % extract the data

        % Maximum value storable in a INT16
        maxVal = intmax('uint16'); %2^16;

        %  split the preambleBlock into individual pieces of info
        preambleBlock = regexp(preambleBlock,',','split');


        % Store it all for future use
        waveforms{i}.preable.Format = str2double(preambleBlock{1});
        % FORMAT : int16 - 0 = BYTE, 1 = WORD, 4 = ASCII.
        waveforms{i}.preable.Type = str2double(preambleBlock{2});
        % TYPE : int16 - 0 = NORMAL, 1 = PEAK DETECT, 2 = AVERAGE
        waveforms{i}.preable.Points = str2double(preambleBlock{3});
        % POINTS: int32 - number of data points transferred.
        waveforms{i}.preable.Count = str2double(preambleBlock{4});      % This is always 1
        % COUNT: int32 - 1 and is always 1.
        waveforms{i}.preable.XIncrement = str2double(preambleBlock{5}); % in seconds
        % XINCREMENT: float64 - time difference between data points.
        waveforms{i}.preable.XOrigin = str2double(preambleBlock{6});    % in seconds
        % XORIGIN: float64 - always the first data point in memory.
        waveforms{i}.preable.XReference = str2double(preambleBlock{7});
        % XREFERENCE: int32 - specifies the data point associated with x-origin.
        waveforms{i}.preable.YIncrement = str2double(preambleBlock{8}); % V
        % YINCREMENT: float32 - voltage diff between data points.
        waveforms{i}.preable.YOrigin = str2double(preambleBlock{9});
        % YORIGIN: float32 - value is the voltage at center screen.
        waveforms{i}.preable.YReference = str2double(preambleBlock{10});
        % YREFERENCE: int32 - specifies the data point where y-origin occurs.
        %waveform1.preable = InifiiVision2000.analyzePreamble(preambleBlock);

        waveforms{i}.Offset = ((maxVal/2 - waveforms{i}.preable.YReference) * waveforms{i}.preable.YIncrement + waveforms{i}.preable.YOrigin);         % V
        waveforms{i}.Delay = ((waveforms{i}.preable.Points/2 - waveforms{i}.preable.XReference) * waveforms{i}.preable.XIncrement + waveforms{i}.preable.XOrigin); % seconds

        % Generate X & Y Data
        waveforms{i}.XData = ((waveforms{i}.preable.XIncrement.*(0:(length(waveforms{i}.RawData)-1))) + waveforms{i}.preable.XOrigin)';
        waveforms{i}.YData = (waveforms{i}.preable.YIncrement.*(waveforms{i}.RawData - waveforms{i}.preable.YReference)) + waveforms{i}.preable.YOrigin;
      end
      % TODO: get errors
      self.send(':RUN');
      if length(waveforms) == 1
        waveforms = waveforms{1};
      end
    end % getSingleTrace
    %{
    function preamble = analyzePreamble(preable_str)

    end % analyze preamble
    %}
  end % methods
end
%{
Copyright (c) 2016, Mark Harfouche
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Mark Harfouche nor the
      names of his/her contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Mark Harfouche BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%}
