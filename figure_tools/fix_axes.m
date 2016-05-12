function fix_axes(fig_axes, figure_already_found, axes_title, axes_xlabel, axes_ylabel, clear_axes, fontsize, axes_type)
    if ~figure_already_found || clear_axes
        if fontsize > 0
            set(fig_axes, 'FontSize', fontsize);
        end

        if clear_axes
            cla(fig_axes);
        end

        set(fig_axes, 'DefaultLineLineWidth', 1);
        set(fig_axes, 'DefaultLineMarkerSize', 10);


        if strcmp(axes_type, 'loglog')
            set(fig_axes, 'XScale', 'log');
            set(fig_axes, 'YScale', 'log');
            %set(fig_axes, 'XMinorTick','on');
            %set(fig_axes, 'YMinorTick','on');
        elseif strcmp(axes_type, 'semilogx')
            set(fig_axes, 'XScale', 'log');
            %set(fig_axes, 'XMinorTick','on');
        elseif strcmp(axes_type, 'semilogy')
            set(fig_axes, 'YScale', 'log');
            %set(fig_axes, 'YMinorTick','on');
        end
        title(fig_axes, axes_title); %, 'Interpreter','LaTex');
        xlabel(fig_axes, axes_xlabel); %, 'Interpreter','LaTex');
        ylabel(fig_axes, axes_ylabel); %, 'Interpreter','LaTex');

        hold(fig_axes, 'on');
  		set(fig_axes,'Box','on');


        set(fig_axes, 'Box', 'on');
        set(fig_axes, 'XGrid', 'on');
        set(fig_axes, 'YGrid', 'on');
        %set(fig_axes, 'XMinorGrid', 'on');
        %set(fig_axes, 'YMinorGrid', 'on');
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
