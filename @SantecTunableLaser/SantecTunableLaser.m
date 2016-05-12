classdef SantecTunableLaser < handle
  properties
    gpib_handle
    PrimaryAddress
    BoardIndex
    vendor
  end

  methods
    function self = SantecTunableLaser(PrimaryAddress, BoardIndex, vendor)
      PrimaryAddress_default = 1;
      BoardIndex_default = 0;
      vendor_default = 'NI';

      if nargin < 1
        PrimaryAddress = PrimaryAddress_default;
      end
      if nargin < 2
        BoardIndex = BoardIndex_default;
      end
      if nargin < 3
        vendor = vendor_default;
      end

      self.PrimaryAddress = PrimaryAddress;
      self.BoardIndex = BoardIndex;
      self.vendor = vendor;

      self.gpib_handle = instrfind('Type', 'gpib', 'BoardIndex', BoardIndex, 'PrimaryAddress', PrimaryAddress, 'Tag', '');
      if ~isempty(self.gpib_handle)
        fclose(self.gpib_handle);
        delete(self.gpib_handle);
      end
      self.gpib_handle = gpib(vendor, BoardIndex, PrimaryAddress);
      fopen(self.gpib_handle);
    end

    function open(self)
       fopen(self.gpib_handle);
    end
    function close(self)
       fclose(self.gpib_handle);
    end

    function cmd = send(self, cmd)
      fprintf(self.gpib_handle, cmd);
    end
    function response = ask(self, cmd)
      self.send(cmd);
      response = self.receive();
    end

    function [response, cmd] = identification_query(self)
      cmd = '*IDN?';
      response = self.ask(cmd);
    end

    function response = receive(self)
        response = fscanf(self.gpib_handle);
    end

    function [response, cmd] = power_unit(self, u)
      % 0 dBm
      % 1 mW
      % else error
      if nargin == 2
        if u ~= 0
          u = 1;
        end
        cmd = sprintf('power:unit %d', u);
        self.send(cmd);
      else
        cmd = 'power:unit?';
        response = self.ask(cmd);
      end
    end

    function [response, cmd] = power(self, p)
      if nargin == 2
        cmd = sprintf('power %0.2f', p);
        self.send(cmd);
      else
        cmd = 'power?';
        response = str2double(self.ask(cmd));
      end
    end

    function [response, cmd] = power_maximum(self)
      cmd = 'power:level:maximum?';
      response = str2double(self.ask(cmd));
    end

    function [response, cmd] = power_minimum(self)
      cmd = 'power:level:minimum?';
      response = str2double(self.ask(cmd));
    end

    function [response, cmd] = power_actual(self)
      cmd = 'power:actual?';
      response = str2double(self.ask(cmd));
    end

    function [response, cmd] = wavelength(self, w)
      if nargin == 2
        cmd = sprintf('wavelength %0.3f',w);
        self.send(cmd);
      else
        cmd = 'wavelength?';
        response = str2double(self.ask(cmd));
      end
    end

    function [response, cmd] = frequency(self, f)
      if nargin == 2
        cmd = sprintf('frequency %0.4f', f);
        self.send(cmd);
      else
        cmd  = 'frequency?';
        response = str2double(self.ask(cmd));
      end
    end

    function [response, cmd] = wavelength_unit(self, u)
      % 0 nm
      % 1 THz
      % else nothing
      if nargin == 2
        if u ~= 0
          u = 1;
        end
        cmd = sprintf('wavelength:unit %d', u);
        self.send(cmd);
      else
        cmd ='wavelength:unit?';
        response = self.ask(cmd);
      end
    end

    function [response, cmd] = wavelength_start(self, w)
        if nargin == 2
            cmd = sprintf('wavelength:sweep:start %0.3f',w);
            self.send(cmd);
        else
            cmd = 'wavelength:sweep:start?';
            response = str2double(self.ask(cmd));
        end
    end
    function [response, cmd] = wavelength_stop(self, w)
        if nargin == 2
            cmd = sprintf('wavelength:sweep:stop %0.3f',w);
            self.send(cmd);
        else
            cmd = 'wavelength:sweep:stop?';
            response = str2double(self.ask(cmd));
        end
    end

    function [response, cmd] = wavelength_sweep_speed(self, s)
        % In nm / s
        if nargin == 2
            cmd = sprintf('wavelength:sweep:speed %0.3f',s);
            self.send(cmd);
        else
            cmd = 'wavelength:sweep:speed?';
            response = str2double(self.ask(cmd));
        end
    end

    function [cmd] = sweep_state_stop(self)
        % stop state = 0
        cmd = 'wavelength:sweep:state 0';
        self.send(cmd);
    end
    function [response, cmd] = sweep_state(self, state)
        if nargin == 2
            cmd = sprintf('wavelength:sweep:state %d',state);
            self.send(cmd);
        else
            cmd = 'wavelength:sweep:state?';
            response = str2double(self.ask(cmd));
        end
    end
    function wait_until_stopped(self)
        while (self.sweep_state() ~= 0);
        end
    end
    function [cmd] = sweep_repeat(self)
        cmd = 'wavelength:sweep:repeat';
        self.send(cmd);
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
