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
            primary_address_default = 18; % TODO Fix me
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

        function r = identify(self)
            r = self.ask('*IDN?');
        end



        function f = frequency(self, f)
            %Sets the output frequency to x Hz.
            if nargin < 2
                f = str2double(self.ask('FREQ?'));
            else
                self.send(['FREQ ' num2str(f)]);
            end
        end

        function f = sampling_frequency(self, f)
            %Sets the arbitrary waveform sampling frequency to x Hz.
            if nargin < 2
                f = str2double(self.ask('FSMP?'));
            else
                self.send(['FSMP ' num2str(f)]);
            end
        end
        function func_type = output_function(self, func_type)
            % Sets the output function. 0 = sine, 1 = square, 2 = triangle, 3 = ramp, 4 = noise,
            % 5= arbitrary.
            if nargin < 2
                func_type = str2double(self.ask('FUNC?'));
            else
                self.send(['FUNC ', num2str(func_type)]);
            end
        end

        function i = output_inversion(self, i)
            % Set output inversion on (i=1) or off (i=0)
            if nargin < 2
                i = str2double(self.ask('INVT?'));
            else
                self.send(['INVT ', num2str(i)]);
            end
        end

        function v = offset_voltage(self, v)
            % Sets the output offset to x volts.
            if nargin < 2
                v = str2double(self.ask('OFFS?'));
            else
                self.send(['OFFS ', num2str(v)]);
            end
        end

        function clear_phase(self)
            % Sets the current waveform phase to zero.
            self.send('PCLR');
        end

        function p = phase(self, p)
            Sets the waveform output phase to x degrees.
            if nargin < 2
                p = str2double(self.ask('PHSE?'));
            else
                self.send(['PHSE ', num2str(p)]);
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
