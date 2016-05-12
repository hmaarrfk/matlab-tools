classdef NE1000
    % Syringe Pump Class
    properties
        handle
    end

    methods
        function ne1000 = NE1000(com, baud_rate)
            com_default = 'COM1';
            baud_rate_default = 19200;

            if nargin < 1
                com = com_default;
            end
            if nargin < 2
                baud_rate = baud_rate_default;
            end
            ne1000.handle = instrfind('Type', 'serial','Port','COM1', 'Status', 'Open');

            if isempty(ne1000.handle )
              ne1000.handle = serial(com,'BaudRate', baud_rate,'DataBits',8,'StopBits',1,'Terminator', 'CR','FlowControl','none');
            else
              fclose(ne1000.handle );
              ne1000.handle  = ne1000.handle(1);
            end

            fopen(ne1000.handle);
        end
        function open(ne1000)
            fopen(ne1000.handle)
        end
        function close(ne1000)
            fclose(ne1000.handle);
        end

        function delete(ne1000)
            ne1000.close();
        end

        function [response, cmd] = address(ne1000, new_address, baud_rate, query_address)
            new_address_default   = -1;
            baud_rate_default    = -1;
            query_address_default = -1;

            if nargin < 2
              new_address = new_address_default;
            end

            if nargin < 3
              baud_rate = baud_rate_default;
            end

            if nargin < 4
              query_address = query_address_default;
            end


            if query_address < 0
              if new_address < 0
                cmd = sprintf('*ADR');
              else
                if baud_rate < 0
                  cmd = sprintf('*ADR%d', new_address);
                else
                  cmd = sprintf('*ADR%dB%d', new_address, baud_rate);
                end
              end
            else
              if new_address < 0
                cmd = sprintf('%dADR', query_address);
              else
                if baud_rate < 0
                  cmd = sprintf('%dADR%d', query_address, new_address);
                else
                  cmd = sprintf('%dADR%dB%d', query_address, new_address, baud_rate);
                end
              end
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end

        function [response, cmd] = buz_off(ne1000, address)
            address_default = -1;

            if nargin < 2
              address = address_default;
            end


            if address < 0
              cmd = sprintf('*BUZ0');
            else
              cmd = sprintf('%dBUZ0', address);
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end

        function [response, cmd] = buz_on(ne1000, address, n)
            address_default = -1;
            n_default = 0;

            if nargin < 2
              address = address_default;
            end
            if nargin < 3
              n = n_default;
            end

            if address < 0
              cmd = sprintf('*BUZ1%d', n);
            else
              cmd = sprintf('%dBUZ1%d', address, n);
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end
        function [response, cmd] = clear_volume_dispensed(ne1000, address, direction)
            address_default = -1;
            direction_default = 'INF'; % or 'WDR'

            if nargin < 2
              address = address_default;
            end
            if nargin < 3
              direction = direction_default;
            end

            if address < 0
              cmd = sprintf('*CLD%s', direction);
            else
              cmd = sprintf('%dCLD%s', address, direction);
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end


        function [response, cmd] = pumping_direction(ne1000, address, direction)
            address_default = -1;
            direction_default = '';

            if nargin < 2
              address = address_default;
            end
            if nargin < 3
              direction = direction_default;
            end


            if address < 0
              cmd = sprintf('*DIR%s', direction);
            else
              cmd = sprintf('%dDIR%s', address, direction);
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end

        function [response, cmd] = pumping_rate(ne1000, address, rate, units)
            address_default = -1;
            rate_default = -1;
            units_default = '';

            if nargin < 2
              address = address_default;
            end
            if nargin < 3
              rate = rate_default;
            end
            if nargin < 4
              units = units_default;
            end

            if address < 0
                  if rate < 0
                      cmd = sprintf('*RAT');
                  elseif rate >= 1000
                      cmd = sprintf('*RAT%.0f%s', rate, units);
                  elseif rate >= 100.0
                      cmd = sprintf('*RAT%.1f%s', rate, units);
                  else
                      cmd = sprintf('*RAT%.2f%s', rate, units);
                  end
            else
                if rate < 0
                    cmd = sprintf('%dRAT', address);
                elseif rate >= 1000
                    cmd = sprintf('%dRAT%.0f%s', address, rate, units);
                elseif rate >=100
                    cmd = sprintf('%dRAT%.1f%s', address, rate, units);
                else
                    cmd = sprintf('%dRAT%.2f%s', address, rate, units);
                end
            end
            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end
        function [response, cmd] = run(ne1000, address)
            address_default = -1;

            if nargin < 2
              address = address_default;
            end

            if address < 0
              cmd = sprintf('*RUN');
            else
              cmd = sprintf('%dRUN', address);
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end

        function [response, cmd] = set_volume_units(ne1000, address, units)
            address_default = -1;
            units_default = 'ul';

            if nargin < 2
              address = address_default;
            end
            if nargin < 3
              units = units_default;
            end


            if address < 0
              cmd = sprintf('*VOL%s', units);
            else
              cmd = sprintf('%dVOL%s', address, units);
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end
        function [response, cmd] = stop(ne1000, address)
            address_default = -1;

            if nargin < 2
              address = address_default;
            end

            if address < 0
              cmd = sprintf('*STP');
            else
              cmd = sprintf('%dSTP', address);
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end
        function [response, cmd] = volume_dispensed(ne1000, address)
            address_default = -1;

            if nargin < 2
              address = address_default;
            end

            if address < 0
              cmd = sprintf('*DIS');
            else
              cmd = sprintf('%dDIS', address);
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end
        function [response, cmd] = volume_to_be_dispensed(ne1000, address, volume)
            address_default = -1;
            volume_default = -1;

            if nargin < 2
              address = address_default;
            end
            if nargin < 3
              volume = volume_default;
            end

            if address < 0
              if volume < 0
                cmd = sprintf('*VOL');
              else
                cmd = sprintf('*VOL%.2f', volume);
              end
            else
              if volume < 0
                cmd = sprintf('%dVOL', address);
              else
                cmd = sprintf('%dVOL%.2f', address, volume);
              end
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end
        function [response, cmd] = syringe_diameter(ne1000, address, diameter)
            address_default = -1;
            diameter_default = -1;

            if nargin < 2
              address = address_default;
            end
            if nargin < 3
              diameter = diameter_default;
            end

            if address < 0
              if diameter < 0
                cmd = sprintf('*DIA');
              else
                cmd = sprintf('*DIA%.2f', diameter);
              end
            else
              if diameter < 0
                cmd = sprintf('%dDIA', address);
              else
                cmd = sprintf('%dDIA%.2f', address, diameter);
              end
            end

            fprintf(ne1000.handle, cmd);
            response = ne1000.get_response();
        end

        function response = get_response(ne1000)
            % The respoonse is stupid and isn't delimited by 'CR' so we
            % need to loop through the sent characters one by one
            response = '';
            while 1
                [c, count] = fscanf(ne1000.handle, '%c', 1);
                if count == 0
                    fprintf(2, 'Timeout reached before we could read the full response\n');
                    break;
                end
                if c == 2
                    % start transmission
                elseif c == 3
                    % end transmission
                    break;
                else
                    % useful characters
                    response = [response, c];
                end
                % When you send * commands, it returns something, but it
                % returns garbage that cannot be read, there will be at
                % least one byte sent, so this check is a hard check so
                % that we do not wait for ever to get the bytes
                if get(ne1000.handle, 'BytesAvailable') == 0
                    break;
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
