classdef Profilometer
    properties
        filename
        x
        z

        date_taken
        time_taken
    end

    methods
        function self = Profilometer(filename)
            self.filename = filename;
            fid = fopen(self.filename);
            metadata = textscan(fid, '%q', 'Delimiter',',');
            fclose(fid);
            metadata = metadata{1};
            metadata = reshape(metadata', 2, [])';
            units_x_cell = metadata(2, 2);
            if strcmp('NANOMETER', units_x_cell{1})
                units_x = 1E-9;
            else
                error('Unknown x units');
            end
            units_z_cell = metadata(3, 2);
            if strcmp('NANOMETER', units_z_cell{1})
                units_z = 1E-9;
            else
                error('Unknown x units');
            end
            self.date_taken = metadata(1, 1);
            self.date_taken = self.date_taken{1};
            self.time_taken = metadata(1, 2);
            self.time_taken = self.time_taken{1};


            % The first useful line is line 7
            a = csvread(self.filename, 7);
            self.x = a(:, 1) * units_x;
            self.z = a(:, 2) * units_z;
        end

        function [plot_axes, plot_figure] = plot(self, title, figure_name)
            if nargin < 2
                title = [self.date_taken, ' ', self.time_taken];
            end
            if nargin < 3
                figure_name = title;
            end

            [plot_axes, plot_figure] = get_figure_axes(figure_name, title, 'Scan Distance (\mum)', 'Height (nm)', 1, 24);
            plot(plot_axes, self.x *1E6, self.z * 1E9, 'LineWidth', 1.5);
            axis(plot_axes, 'tight');

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
