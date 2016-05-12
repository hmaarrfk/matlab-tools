%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a class to run the ESP300 newport motor controller.                  %
%                                                                              %
% Similar to                                                                   %
% http://www.newport.com/ESP301-Series-3-Axis-Motion-Controller-Driver/771081/1033/info.aspx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef ESP300 < handle
  properties
    handle_id
    vendor
    board_index
    primary_address
    terminator
  end

  methods
    function self = ESP300(vendor, board_index, primary_address)
      vendor_default = 'ni';
      board_index_default = 0;
      primary_address_default = 27;

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

      self.handle_id = instrfind('Type', 'gpib', 'BoardIndex', self.board_index, 'PrimaryAddress', self.primary_address, 'Tag', '');

      if ~isempty(self.handle_id)
        fclose(self.handle_id);
        delete(self.handle_id)
      end
      self.handle_id = gpib(self.vendor, self.board_index, self.primary_address);
      self.terminator = 13;
      %set(self.handle_id, 'Timeout', 2);
      self.open();
    end

    function open(self)
      fopen(self.handle_id);
    end

    function close(self)
      fclose(self.handle_id);
    end
    function delete(self)
      self.close();
    end

    function cmd = send(self, cmd)
      fprintf(self.handle_id, [cmd, self.terminator]);
      pause(0.1)
    end
    function response = receive(self)
      response = fscanf(self.handle_id);
    end
    function response = ask(self, cmd)
      self.send(cmd);
      response = self.receive();
    end

    function wait_until_finished(self, motor_id)
      % This basically forces
      % Matlab to wait until the desired motor has stopped

      while true
        pause(0.1);
        wanted_pos = str2double(self.position_absolute(motor_id));
        actual_pos = str2double(self.read_actual_position(motor_id));
        if(abs(wanted_pos - actual_pos) < 0.1)
          pause(1);
          return
        end
      end

      % Now we should be able to ask for this and it shouldn't time out
      s = sprintf('0WS;%dMD', motor_id);
      self.ask(s);
    end

    function r = position_absolute(self, motor_id, pos_or_units)
      if nargin < 3
        s = sprintf('%dPA?', motor_id);
        r = self.ask(s);
      else
        s = sprintf('%dPA%.3f', motor_id, pos_or_units);
        self.send(s);
      end
    end

    function search_for_home(self, motor_id)
      s = sprintf('%dOR0', motor_id);
      self.send(s);
    end

    function r = is_motor_on(self, motor_id)
      s = sprintf('%dMO?', motor_id);
      r = self.ask(s);
    end

    function motor_on(self, motor_id)
      s = sprintf('%dMO', motor_id);
      self.send(s);
    end

    function motor_off(self, motor_id)
      s = sprintf('%dMF', motor_id);
      self.send(s);
    end

    function r = velocity(self, motor_id, velocity)
      if nargin < 3
        s = sprintf('%dVA?', motor_id);
        r = self.ask(s);
      else
        s = sprintf('%dVA%.3f', motor_id, velocity);
        self.send(s);
      end
    end

    function r = min_speed(self, motor_id, speed)
      if nargin < 2
        s = sprintf('%dVA?', motor_id);
        r = self.ask(s);
      else
        s = sprintf('%dVA%f', motor_id, speed);
        self.send(s);
      end
    end

    function r = max_speed(self, motor_id, speed)
      if nargin < 2
        s = sprintf('%dVU?', motor_id);
        r = self.ask(s);
      else
        s = sprintf('%dVU%f', motor_id, speed);
        self.send(s);
      end
    end

    function r = min_speed_homing(self, motor_id, speed)
      if nargin < 2
        s = sprintf('%dOL?', motor_id);
        r = self.ask(s);
      else
        s = sprintf('%dOL%f', motor_id, speed);
        self.send(s);
      end
    end

    function r = max_speed_homing(self, motor_id, speed)
      if nargin < 2
        s = sprintf('%dOH?', motor_id);
        r = self.ask(s);
      else
        s = sprintf('%dOH%f', motor_id, speed);
        self.send(s);
      end
    end

    function r = read_error_message(self)
      r = self.ask('TB?');
    end

    function r = read_actual_position(self, motor_id)
      s = sprintf('%dTP', motor_id);
      r = self.ask(s);
    end

    function r= read_error_message_formatted(self)
      raw = self.read_error_message();
      raw(end) = []; % remove the newline char
      raw(end) = [];
      [r.error_code, raw] = strtok(raw, ',');
      raw(1:2) = []; % remove the space
      [r.timestamp, raw] = strtok(raw, ',');
      raw(1:2) = []; % remove the space
      [r.error_message] = strtok(raw, ',');
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
