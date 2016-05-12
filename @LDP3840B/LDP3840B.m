classdef LDP3840B < handle
   properties
      gpib_handle
      vendor
      board_index
      primary_address
   end

   methods
      function self = LDP3840B(vendor, board_index, primary_address)
         vendor_default = 'ni';
         board_index_default = 0;
         primary_address_default = 9;
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

      function [response, cmd] = identify(self)
         cmd = '*IDN?'; % Note this is not the standard command format
         [response, cmd] = self.ask(cmd);
      end

      function [dc, cmd] = dutyCycle(self, dc)
          cmd = 'CDC';
          if nargin < 2;
              cmd = [cmd, '?'];
              dc = str2double(self.ask(cmd)) / 100;
          else
              cmd = [cmd, ' ', num2str(dc * 100, '%.2f')];
              self.send(cmd);
          end
      end

      function [dis, cmd] = display(self, dis)
          % No parameters:
          %    Returns the display message or value
          % 1 parameters
          %    Turns the display on or off
          cmd = 'DIS';
          if nargin < 2;
              cmd = [cmd, '?'];
              dis = self.ask(cmd);
          else
              cmd = [cmd, ' ', num2str(dis, '%.f')];
              self.send(cmd);
          end
      end
      function [ilim, cmd] = currentLimit(self, ilim)
          % Set the laser drive current limit in A
          cmd = 'LIM:I';
          if nargin < 2;
              cmd = [cmd, '?'];
              ilim = str2double(self.ask(cmd))/1000;
          else
              warning('Setting limit using a program. Be very sure of this...');
              cmd = [cmd, ' ', num2str(ilim*1000, '%.f')];
              self.send(cmd);
          end
      end

      function [mode, cmd] = mode(self, mode)
          % Returns the mode:
          % PRI (pulse repetition interval)
          % DUTY (duty cycle%)
          % EXT (external trigger)
          % Or sets the mode if you send it one of the parameters above
          cmd = 'MODE';
          if nargin < 2;
              cmd = [cmd, '?'];
              mode = self.ask(cmd);
          elseif strcmpi(mode, 'PRI')
              cmd = [cmd, ':PRI'];
              self.send(cmd);
          elseif strcmpi(mode, 'EXT');
              cmd = [cmd, ':EXT'];
              self.send(cmd);
          else%if strcmpi(mode, 'DUTY');
              cmd = [cmd, ':CDC'];
              self.send(cmd);
          end
      end

      function [out, cmd] = output(self, out)
          % No parameters:
          %     Returns the OUTPUT switch status.
          % 1 parameter:
          %     Same action as setting the OUTPUT switch on/off.
          cmd = 'OUT';
          if nargin < 2;
              cmd = [cmd, '?'];
              out = str2double(self.ask(cmd));
          else
              cmd = [cmd, ' ', num2str(out, '%.f')];
              self.send(cmd);
          end
      end

      function [pol, cmd] = polarization(self, pol)
          % Returns the polarization, P or N
          cmd = 'POL';
          if nargin < 2;
              cmd = [cmd, '?'];
              pol = self.ask(cmd);
          elseif strcmpi(pol, 'N');
              cmd = [cmd, ':N'];
              self.send(cmd);
          else%if strcmpi(pol, 'P')
              cmd = [cmd, ':P'];
              self.send(cmd);
          end
      end
      function [pri, cmd] = pulseRepetitionInterval(self, pri)
          % use SI units
          % Data expected in ms. conversion done for you in the function
          cmd = 'PRI';
          if nargin < 2;
              cmd = [cmd, '?'];
              pri = str2double(self.ask(cmd)) / 1000;
          else
              cmd = [cmd, ' ', num2str(pri * 1000)];
              self.send(cmd);
          end
      end

      function [pw, cmd] = pulseWidth(self, pw)
          % in us
          cmd = 'PW';
          if nargin < 2;
              cmd = [cmd, '?'];
              pw = str2double(self.ask(cmd)) / 1E6;
          else
              cmd = [cmd, ' ', num2str(pw * 1E6)];
              self.send(cmd);
          end
      end

      %% Warning, untested features below
      function [i, cmd] = currentSetpoint(self, i)
          % Set the laser drive current in A
          cmd = 'LDI';
          if nargin < 2;
              cmd = [cmd, '?'];
              i = str2double(self.ask(cmd))/1000;
          else
              cmd = [cmd, ' ', num2str(i*1000, '%.f')];
              self.send(cmd);
          end
      end

      function [cdc, cmd] = setpointCDC(self)
          % Return the setpoint duty cycle, the true one, not the one you
          % enetered
          cmd = 'SET:CDC?';
          cdc = str2double(self.ask(cmd))/100;
      end

      function [ldi, cmd] = setpointLDI(self)
          % Return the setpoint current
          cmd = 'SET:LDI?';
          % data returned in mA
          ldi = str2double(self.ask(cmd))*1E-3;
      end

      function [pri, cmd] = setpointPRI(self)
          % return the setpoint pulse repetition interval
          cmd = 'SET:PRI?';
          % data returned in ms
          pri = str2double(self.ask(cmd))*1E-3;
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
