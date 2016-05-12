function [fig_axes, fig] = get_figure_axes(figure_name, axes_title, axes_xlabel, axes_ylabel, clear_axes, fontsize, axes_type)
    if nargin < 2; axes_title = []; end
    if nargin < 3; axes_xlabel = []; end
    if nargin < 4; axes_ylabel = []; end
    if nargin < 5; clear_axes = 1; end
    if nargin < 6; fontsize = 16; end
    if nargin < 7; axes_type = 'linear'; end

    fig = findobj('type', 'figure', 'name', figure_name);

    figure_already_found = ~isempty(fig);


    if figure_already_found
        if clear_axes
            clf(fig);
            fig_axes = axes('Parent', fig);
        else
            fig_axes = gca(fig);
        end
    else
        fig = figure('name', figure_name);

        fig_axes = axes('Parent', fig);
    end

    % See http://www.mathworks.com/help/matlab/ref/print.html#f30-443485
    set(fig, 'PaperPositionMode', 'auto');

    fix_axes(fig_axes, figure_already_found, axes_title, axes_xlabel, axes_ylabel, clear_axes, fontsize, axes_type)
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
