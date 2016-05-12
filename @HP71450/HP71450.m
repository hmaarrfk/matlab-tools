classdef HP71450 < handle
  properties
    gpib_handle
    vendor
    board_index
    primary_address
  end

  methods
    function self = HP71450(vendor, board_index, primary_address)
      vendor_default = 'ni';
      board_index_default = 0;
      primary_address_default = 23;
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

    function response = ask(self, cmd)
      self.send(cmd);
      response = self.receive();
    end

    function wl = center_wavelength(self, wl)
        if nargin < 2
            wl = self.ask('CENTERWL?');
            wl = str2double(wl);
        else
            s = sprintf('CENTERWL %.4f nm', wl*1E9);
            self.send(s);
        end
    end

    function wl = span_wavelength(self, wl)
        % you can also just send the command 'SP'
        if nargin < 2
            wl = self.ask('SPANWL?');
            wl = str2double(wl);
        else
            s = sprintf('SPANWL %.4f nm', wl*1E9);
            self.send(s);
        end
    end


    function sens = sensitivity(self, sens)
        if nargin < 2
            sens = self.ask('SENS?');
            sens = str2double(sens);
        else
            s = sprintf('SENS %.4f', sens);
            self.send(s);
        end
    end

    function single_sweep(self)
        self.send('SNGLS');
    end

    function continuous_sweep(self)
       self.send('CONTS');
    end

    function take_sweep(self)
        self.send('TS');
    end

    function d = done(self)
        timeout_prev = self.gpib_handle.Timeout;
        self.gpib_handle.Timeout = 30;
        d = self.ask('DONE?');
        self.gpib_handle.Timeout = timeout_prev;
    end
    function the_trace = get_trace(self, letter)
        if nargin < 2
            letter = 'A';
        end

        self.send('TDF P');
        the_trace = self.ask(['TR', letter, '?']);
        the_trace = strsplit(the_trace, ',');
        the_trace = str2double(the_trace');
    end

    function wl = startwl(self, wl)
        if nargin < 2
            wl = self.ask('STARTWL?');
            wl = str2double(wl);
        else
            s = sprintf('STARTWL %.4f nm', wl*1E9);
            self.send(s);
        end
    end
    function wl = stopwl(self, wl)
        if nargin < 2
            wl = self.ask('STOPWL?');
            wl = str2double(wl);
        else
            s = sprintf('STOPWL %.4f nm', wl*1E9);
            self.send(s);
        end
    end

    % what are the amplitude units used
    function units = aunits(self, units)
        if nargin < 2
            units = self.ask('AUNITS?');
        end
    end

    function rb = resolution_bandwidth(self, rb)
        if nargin < 2
            rb = self.ask('RB?');
            rb = str2double(rb);
        else
            s = sprintf('RB %.4f nm', rb*1E9);
            self.send(s);
        end
    end
    function err_string = check_error(self)
        err_string = self.ask('XERR?');
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
