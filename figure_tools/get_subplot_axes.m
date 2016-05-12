function [subplot_axes, fig] = get_subplot_axes(figure_name, x_subplot, ...
    y_subplot, axes_titles, axes_xlabels, axes_ylabels, clear_axes, fontsize, axes_type)
    if nargin < 2; x_subplot = 1; end
    if nargin < 3; y_subplot = 1; end
    if nargin < 4; axes_titles = cell(x_subplot, y_subplot); end
    if nargin < 5; axes_xlabels = cell(x_subplot, y_subplot); end
    if nargin < 6; axes_ylabels = cell(x_subplot, y_subplot); end
    if nargin < 7; clear_axes = 0; end
    if nargin < 8; fontsize = 16; end

    if nargin < 9;
        axes_type = cell(x_subplot, y_subplot);
        for i=1:x_subplot
            for j=1:y_subplot
                axes_type{i,j} = 'linear';
            end
        end
    end

    fig = findobj('type', 'figure', 'name', figure_name);

    figure_already_found = ~isempty(fig);
    if figure_already_found
        if clear_axes
            clf(fig);
        end
    end

    if ~figure_already_found
        fig = figure('name', figure_name);
    end

    subplot_axes = cell(x_subplot, y_subplot);

    subplot_count = 1;
    for j = 1:y_subplot
        for i = 1:x_subplot

        subplot_axes{i, j} = subplot(y_subplot, x_subplot, subplot_count, 'parent', fig);
        subplot_count = subplot_count +1;

        fix_axes(subplot_axes{i, j}, figure_already_found, axes_titles{i,j}, axes_xlabels{i,j}, axes_ylabels{i,j}, clear_axes, fontsize, axes_type{i, j})
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
