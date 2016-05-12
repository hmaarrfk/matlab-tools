classdef HP8560 < handle
  properties
    gpib_handle
    vendor
    board_index
    primary_address
  end

  methods
    function self = HP8560(vendor, board_index, primary_address)
      vendor_default = 'ni';
      board_index_default = 0;
      primary_address_default = 18;
      if nargin < 1
        vendor = vendor_default;
      end
      if nargin < 2
        board_index = board_index_default;
      end
      if nargin < 3
        primary_address = primary_address_default;
      end
      self.vendor = vendor;
      self.board_index = board_index;
      self.primary_address = primary_address;

      self.gpib_handle = instrfind('Type', 'gpib', 'BoardIndex', self.board_index, 'PrimaryAddress', self.primary_address, 'Tag', '');
      if ~isempty(self.gpib_handle)
        fclose(self.gpib_handle);
        delete(self.gpib_handle)
      end
      self.gpib_handle = gpib(self.vendor, self.board_index, self.primary_address);
      self.gpib_handle.InputBufferSize = 10000; % make it large so that when we get a trace, it can all be read at once.

      fopen(self.gpib_handle);
    end
    function open(self)
      fopen(self.gpib_handle);
    end

    function close(self)
      fclose(self.gpib_handle);
    end
    function delete(self)
      self.close();
    end

    function cmd = send(self, cmd)
      fprintf(self.gpib_handle, cmd);
    end

    function response = receive(self)
      response = fscanf(self.gpib_handle);
    end

    function [response, cmd] = ask(self, cmd)
      self.send(cmd);
      response = self.receive();
    end

    function [response, cmd] = identify(dg1022)
      cmd = 'ID?'; % Note this is not the standard command format
      [response, cmd] = dg1022.ask(cmd);
    end


    % Quote from the user manual page 298
    %
    % If a TS (Take Sweep) command is executed, but the trigger conditions are not met, the
    % spectrum analyzer will not respond on GPIB. The analyzer continues to
    % take commands into its input buffer, however the commands are not
    % processed at this time. This can also appear to happen if the sweep time
    % is very long. If this occurs, the HP BASIC CLEAR (that is, CLEAR 718)
    % statement can be used to abort the TS command. (CLEAR also causes
    % an instrument preset.)
    %
    % http://www.mathworks.com/help/instrument/clrdevice.html
    function clrdevice(self)
      clrdevice(self.gpib_handle);
    end

    function [cmd] = instrument_preset(self)
      cmd = 'IP;';
      self.send(cmd);
    end

    function [cmd] = single_sweep(self)
      cmd = 'SNGLS;';
      self.send(cmd);
    end

    function [cmd, response] = frequency_span(self, sp)
    % Set the span of the sweep
    % sp = span of the sweep in Hz
    % Returns
    %    cmd = the command sent to the device
      if nargin < 2
        cmd = 'SP?;';
        response = str2double(self.ask(cmd));
      else
        cmd = sprintf('SP %fHZ;', sp);
        self.send(cmd);
      end
    end

    function [cmd, response] = center_frequency(self, cf)
      if nargin < 2
        cmd = 'CF?;';
        response = str2double(self.ask(cmd));
      else
        cmd = sprintf('CF %fHZ;', cf);
        self.send(cmd);
      end
    end

    function [cmd] = take_sweep(self)
      cmd = 'TS;';
      self.send(cmd);
    end

    function [start_frequency, stop_frequency, ...
        reference_level, resolution_bandwidth, ...
        video_bandwidth, sweep_time, ...
        logarithmic_scale, abs_amp_units] = get_settings(self)
      % FA?; Start Frequency        (Hz)
      % FB?; Stop Frequency         (Hz)
      % RL?; Reference/Range Level  (dBm)
      % RB?; Resolution bandwidth   (Hz)
      % VB?; Video Bandwidth        (Hz)
      % ST?; Sweept Time            (s)
      % LG?; Logarithmic Scale      (dB)
      % AUNITS?; Absolute Amplitude Units (dBm, DBmV, dBuV, W, V)
      [cmd] = 'FA?;FB?;RL?;RB?;VB?;ST?;LG?;AUNITS?;';
      self.send(cmd);
      start_frequency      = str2double(self.receive());
      stop_frequency       = str2double(self.receive());
      reference_level      = str2double(self.receive());
      resolution_bandwidth = str2double(self.receive());
      video_bandwidth      = str2double(self.receive());
      sweep_time           = str2double(self.receive());
      logarithmic_scale    = str2double(self.receive());
      abs_amp_units        = sefl.receive();
    end

    function setup_analyzer(self, ...
        start_frequency, stop_frequency, ...
        reference_level, resolution_bandwidth, ...
        video_bandwidth, sweep_time, ...
        logarithmic_scale, abs_amp_units)
      self.start_frequency(start_frequency);
      self.stop_frequency(stop_frequency);
      self.reference_level(reference_level);
      self.resolution_bandwidth(resolution_bandwidth);
      self.video_bandwidth(video_bandwidth);
      self.sweep_time(sweep_time);
      self.logarithmic_scale(logarithmic_scale);
      self.absolute_amplitude_units(abs_amp_units);
    end

    function [cmd, response] = start_frequency(self, sf)
      if nargin < 2
        cmd = sprintf('FA?;');
        response = str2double(self.ask(cmd));
      else
        cmd = sprintf('FA %fHZ;', sf);
        self.send(cmd);
      end
    end

    function [cmd, response] = stop_frequency(self, sf)
      if nargin < 2
        cmd = 'FB?;';
        response = str2double(self.ask(cmd));
      else
        cmd = sprintf('FB %fHZ;', sf);
        self.send(cmd);
      end
    end

    function [cmd, response] = reference_level(self, r_dbm)
      if nargin < 2
        cmd = 'RL?;';
        response = str2double(self.ask(cmd));
      else
        cmd = sprintf('RL %fDBM;', r_dbm);
        self.send(cmd);
      end
    end

    function [cmd, response] = resolution_bandwidth(self, rb)
      if nargin < 2
        cmd = 'RB?;';
        response = str2double(self.ask(cmd));
      else
        cmd = sprintf('RB %fHZ;', rb);
        self.send(cmd);
      end
    end

    function [cmd, response] = video_bandwidth(self, vb)
      if nargin < 2
        cmd = 'VB?;';
        response = str2double(self.ask(cmd));
      else
        cmd = sprintf('VB %fHZ;', vb);
        self.send(cmd);
      end
    end

    function [cmd, response] = sweep_time(self, st)
      if nargin < 2
        cmd = 'ST?;';
        response = str2double(self.ask(cmd));
      else
        cmd = sprintf('ST %fSEC;', st);
        self.send(cmd);
      end
    end

    function [cmd] = continuous_sweep(self)
      cmd = 'CONTS;';
      self.send(cmd);
    end

    function [cmd] = video_average(self, vavg)
      if vavg == 0
        cmd = 'VAVG off;';
      else
        cmd = sprintf('VAVG %d;', vavg);
      end
      self.send(cmd);
    end

    function [cmd, response] = logarithmic_scale(self, lg)
      if nargin < 2
        cmd = 'LG?;';
        response = str2double(self.ask(cmd));
      else
        % lg can be
        %    0 linear scale
        %    1, 2, 5, 10 db/div
        if lg == 0
          cmd = 'LN;';
        else
          cmd = sprintf('LG %ddB', lg);
        end
        self.send(cmd);
      end
    end

    function [cmd, response] = absolute_amplitude_units(self, abs_amp_units)
      if nargin < 2
        cmd = 'AUNITS?;';
        response = self.ask(cmd);
      else
        cmd = ['AUNITS ', abs_amp_units, ';'];
        self.send(cmd);
      end
    end

    function [cmd, trace] = get_trace(self, do_plot)
      % See Page 303 of the manual
      % Make sure to get the settings of the trace
      % SHould probably look into trace data format (TDF) to see if we can
      % send things as binary to send faster, but it might not matter
      % really
      %
      % FA?; Start Frequency        (Hz)
      % FB?; Stop Frequency         (Hz)
      % RL?; Reference/Range Level  (dBm)
      % RB?; Resolution bandwidth   (Hz)
      % VB?; Video Bandwidth        (Hz)
      % ST?; Sweept Time            (s)
      % LG?; Logarithmic Scale      (dB)
      % AUNITS?; Absolute Amplitude Units (dBm, DBmV, dBuV, W, V)

      cmd = 'TRA?;';
      self.send(cmd);
      s = self.receive();
      trace.x = eval( [ '[', s, ']' ] );
      [~, trace.start_frequency]          = self.start_frequency();
      [~, trace.stop_frequency]           = self.stop_frequency();
      [~, trace.resolution_bandwidth]     = self.resolution_bandwidth();
      [~, trace.video_bandwidth]          = self.video_bandwidth();
      [~, trace.sweep_time]               = self.sweep_time();
      [~, trace.logarithmic_scale]        = self.logarithmic_scale();
      [~, trace.absolute_amplitude_units] = self.absolute_amplitude_units();

      trace.frequency = linspace(trace.start_frequency, trace.stop_frequency, length(trace.x));
      if nargin == 2
        if do_plot == 1
          trace_figure = figure;
          trace_axes   = axes('Parent', trace_figure);
          plot(trace_axes, trace.frequency, trace.x);
          xlabel(trace_axes, 'Frequency (Hz)');
          ylabel(trace_axes, ['Amplitude (', trace.absolute_amplitude_units, ')']);

          title_str = '';
          if trace.resolution_bandwidth > 1E6
            title_str = [title_str, 'RB ', num2str(trace.resolution_bandwidth/1E6), ' MHz'];
          elseif trace.resolution_bandwidth > 1E3
            title_str = [title_str, 'RB ', num2str(trace.resolution_bandwidth/1E3), ' KHz'];
          else
            title_str = [title_str, 'RB ', num2str(trace.resolution_bandwidth    ), ' Hz'];
          end

          if trace.video_bandwidth > 1E6
            title_str = [title_str, ', VB ', num2str(trace.video_bandwidth/1E6), ' MHz'];
          elseif trace.resolution_bandwidth > 1E3
            title_str = [title_str, ', VB ', num2str(trace.video_bandwidth/1E3), ' KHz'];
          else
            title_str = [title_str, ', VB ', num2str(trace.video_bandwidth    ), ' Hz'];
          end

          title_str = [title_str, ', ST ', num2str(trace.sweep_time * 1E3), ' ms'];

          title(trace_axes, title_str);
        end
      end
    end
  end
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
