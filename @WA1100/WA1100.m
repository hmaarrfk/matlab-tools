classdef WA1100
  properties
    handle
    vendor
    board_index
    primary_address
  end

  methods
    function self = WA1100(vendor, board_index, primary_address)
      vendor_default = 'ni';
      board_index_default = 0;
      primary_address_default = 25;

      if nargin < 1
        vendor = vendor_default;
      end
      if nargin < 2
        board_index = board_index_default;
      end
      if nargin < 3
        primary_address = primary_address_default;
      end

      self.handle = instrfind('Type', 'gpib', 'BoardIndex', board_index, 'PrimaryAddress', primary_address, 'Tag', '');

      if isempty(self.handle)
        self.handle = gpib(vendor, board_index, primary_address);
      else
        fclose(self.handle);
        self.handle = self.handle(1);
      end

      self.vendor = vendor;
      self.board_index = board_index;
      self.primary_address = primary_address;

      fopen(self.handle);
    end

    function open(self)
      fopen(self.handle);
    end
    function close(self)
      fclose(self.handle);
    end
    function delete(self)
      self.close();
    end

    function cmd = send(self, cmd)
      fprintf(self.handle, cmd);
    end

    function response = receive(self)
      response = fscanf(self.handle);
    end

    function [response, cmd] = ask(self, cmd)
      cmd = self.send(cmd);
      response = self.receive();
    end

    function [response, cmd] = identify(self)
      cmd = '*IDN?';
      [response, cmd] = self.ask(cmd);
    end

    function cmd = clearEvents(self)
      cmd = '*CLS';
      self.send(cmd);
    end

    function [response, cmd] = unitPower(self, unit)
      % Unit should be DMB or W
      unit_default = -1;
      if nargin < 2
        unit = unit_default;
      end

      cmd = ':UNIT:POWer';
      if (isnumeric(unit) && unit == -1)
        cmd = [cmd, '?'];
        response = self.ask(cmd);
      else
        cmd = [cmd, unit];
        self.send(cmd);

        % read what it was set to
        response = self.unitPower();
      end
    end

    function [response, cmd] = resolution(self, res)
      res_default = -1;
      if nargin < 2
        res = res_default;
      end

      cmd = ':DISP:RES';
      if (isnumeric(res) && res == res_default)
        cmd = [cmd, '?'];
        response = self.ask(cmd);
        return
      elseif ischar(res)
        cmd = [cmd,' ', res];
      elseif isnumeric(res)
        display('got here');
        cmd = [cmd, ' ', num2str(res)];
      end

      self.send(cmd);
      response = self.resolution();
    end

    % Measurement functions
    function [response, cmd] = measurePower(self)
      cmd = ':MEASure:POWer?';
      response = str2double(self.ask(cmd));
    end
    function [response, cmd] = measureEnvironment(self)
      cmd = ':MEASure:ENVironment?';
      response = str2double(self.ask(cmd));
    end
    function [response, cmd] = measureWavelength(self)
      cmd = ':MEASure:WAVelength?';
      response = str2double(self.ask(cmd));
    end
    function [response, cmd] = measureWavenumber(self)
      cmd = ':MEASure:WNUMber?';
      response = str2double(self.ask(cmd));
    end
    function [response, cmd] = measureFrequency(self)
      cmd = ':MEASure:FREQuency?';
      response = str2double(self.ask(cmd));
    end

    % Questionable Status

    function [response, cmd] = questionableCondition(self, print_human_readable)
      print_human_readable_default = false;
      if nargin < 2
        print_human_readable = print_human_readable_default;
      end

      cmd = ':STATus:QUEStionable:CONDition?';
      response = str2double(self.ask(cmd));
      if (islogical(print_human_readable) && print_human_readable) || (isnumeric(print_human_readable) && print_human_readable ~= 0)
        self.interpretQuestionableCondition(response);
      end
    end
    function interpretQuestionableCondition(self, response)
      if ischar(response)
        response = str2double(response);
      end
      if response >= 1024
        display('There isd at least one bit set in the Questionable Hardware Condition register.');
        response = response - 1024;
      end
      if response >= 512
        display('The pressure value is outside the valid range of the instrument.');
        response = response - 512;
      end
      if response >= 256
        display('Weird???? Bit 8 is not supposed to be used.');
        response = response - 256;
      end
      if response >= 128
        display('Weird???? Bit 7 is not supposed to be used.');
        response = response - 128;
      end
      if response >= 64
        display('Weird???? Bit 6 is not supposed to be used.');
        response = response - 64;
      end
      if response >= 32
        display('The wavelength value is outside the valid range of the instrument.');
        response = response - 32;
      end
      if response >= 16
        display('The temperature value is outside the valid range of the instrument.');
        response = response - 16;
      end
      if response >= 8
        display('The power value is outside the valid range of the instrument.');
        response = response - 8;
      end
      if response >= 4
        display('Weird???? Bit 2 is not supposed to be used.');
        response = response - 4;
      end
      if response >= 2
        display('Weird???? Bit 1 is not supposed to be used.');
        response = response - 2;
      end
      if response >= 1
        display('The wavelength has already been read for the current scan.');
        %response = response - 1;
      end
    end
    function [response, cmd] = questionableEnable(self, enable)
      enable_default = -1;
      if nargin < 2
        enable = enable_default;
      end
      cmd = ':STATus:QUEStionable:ENABle';
      if isnumeric(enable) && enable == enable_default
        cmd = [cmd, '?'];
        response = str2dobule(self.ask(cmd));
        return;
      elseif isnumeric(enable)
        cmd = [cmd, ' ', num2str(enable, '%.0f')];
      else
        cmd = 'Error, enable needs to be an integer';
        response = cmd;
        return;
      end
      self.send(cmd);
      response = self.questionableEnable();
    end

    function [response, cmd] = questionableHardwareCondition(self, print_human_readable)
      print_human_readable_default = false;
      if nargin < 2
        print_human_readable = print_human_readable_default;
      end

      cmd = ':STATus:QUEStionable:HARDware:CONDition?';
      response = str2double(self.ask(cmd));
      if (islogical(print_human_readable) && print_human_readable) || (isnumeric(print_human_readable) && print_human_readable ~= 0)
        self.interpretQuestionableHardwareCondition(response);
      end
    end
    function interpretQuestionableHardwareCondition(self, response)
      if ischar(response)
        response = str2double(response);
      end

      if response >= 8192
        display('The reference laser % of peak power is out ofrange. (WA-1600 only)');
        response = response - 8192;
      end
      if response >= 4096
        display('The input laser fringe strength is too high.');
        response = response - 4096;
      end
      if response >= 2048
        display('Fringe counter invalid.');
        response = response - 2048;
      end
      if response >= 1024
        display('Fringe counter overflow.');
        response = response - 1024;
      end
      if response >= 512
        display('Fringe counter error.');
        response = response - 512;
      end
      if response >= 256
        display('The input laser fringe strength is too low.');
        response = response - 256;
      end
      if response >= 128
        display('The scan assembly has stopped moving.');
        response = response - 128;
      end
      if response >= 64
        display('Failed to read or write to the SRAM.');
        response = response - 64;
      end
      if response >= 32
        display('Failed to read the EEPROM.');
        response = response - 32;
      end
      if response >= 16
        display('Analog to digital converter error.');
        response = response - 16;
      end
      if response >= 8
        display('Lost reference laser fringes during scan.');
        response = response - 8;
      end
      if response >= 4
        display('No reference laser fringes detected during scan.');
        response = response - 4;
      end
      if response >= 2
        display('Reference laser is over temperature. (WA-1600 only)');
        response = response - 2;
      end
      if response >= 1
        display('Reference laser has not stabilized. (WA-1600 only)');
        %response = response - 1;
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
