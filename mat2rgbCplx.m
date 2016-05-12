function rgb = mat2rgbCplx(m, m_max, dark_light_not)
    % mat2rgbCpmx
    % Converts a matrix of complex numbers into a color (phase) and intensity (brightness)
    % map. Returns an associated RGB matrix that you can use with imshow
    %
    % rgb = mat2rgbCplx(m)
    % rgb = mat2rgbCplx(m, m_max)
    % rgb = mat2rgbCplx(m, m_max, dark_light_not)
    %
    %
    % m: the complex matrix
    % m_max: the max intensity
    % dark_light_not: values above m_max become black by default (1) else they become white (0)
    if nargin < 2; m_max = max(reshape(abs(m), [], 1)); end
    if nargin < 3; dark_light_not = 1; end
    %{
    h = angle(m)/(2*pi) + 0.5;
    v = abs(m) ./ m_max;
    bad_indicies = isnan(v) | isinf(v);
    s = min(v, (1./v).^0.5);
    s(bad_indicies) = 0.0;
    v(bad_indicies) = 1.0;
    v = min(v, 1.0);

    hsv = cat(3, h, s, v);
    rgb = hsv2rgb(hsv);
    %}

    % http://www.rapidtables.com/convert/color/hsl-to-rgb.htm
    % Look at conversion from HSL
    h = angle(m) / (2 * pi) + 0.5;
    s = 1.0;
%    l = 1 ./ (1 + exp(- 3 * (abs(m) ./ m_max - 0.8)));
    l = 0.5 * (abs(m) ./ m_max);
    %l = atan((abs(m) ./ m_max));

    l = max(l, 0);
    l = min(l, 1);

    if dark_light_not == 0
        l = 1 - l;
    end


    % HSL to RGB
    H = h * 360;
    H(H>360) = H(H>360) - 360;
    H(H<0) = H(H<0) + 360;
    Hprime = H / 60;

    C = (1 - abs(2 * l - 1)) .* s;
    X = C .* (1 - abs(mod(Hprime, 2) - 1));
    M = l - 0.5 * C;
    rgb = zeros([size(H), 3]);

    % R = C for  0 < H < 1 and 5 < H < 6

    rgb(:, :, 1) = rgb(:, :, 1) + C .* ((Hprime >= 0) & (Hprime < 1));
    rgb(:, :, 2) = rgb(:, :, 2) + X .* ((Hprime >= 0) & (Hprime < 1));

    rgb(:, :, 2) = rgb(:, :, 2) + C .* ((Hprime >= 1) & (Hprime < 2));
    rgb(:, :, 1) = rgb(:, :, 1) + X .* ((Hprime >= 1) & (Hprime < 2));

    rgb(:, :, 2) = rgb(:, :, 2) + C .* ((Hprime >= 2) & (Hprime < 3));
    rgb(:, :, 3) = rgb(:, :, 3) + X .* ((Hprime >= 2) & (Hprime < 3));

    rgb(:, :, 3) = rgb(:, :, 3) + C .* ((Hprime >= 3) & (Hprime < 4));
    rgb(:, :, 2) = rgb(:, :, 2) + X .* ((Hprime >= 3) & (Hprime < 4));

    rgb(:, :, 3) = rgb(:, :, 3) + C .* ((Hprime >= 4) & (Hprime < 5));
    rgb(:, :, 1) = rgb(:, :, 1) + X .* ((Hprime >= 4) & (Hprime < 5));

    rgb(:, :, 1) = rgb(:, :, 1) + C .* ((Hprime >= 5) & (Hprime <= 6));
    rgb(:, :, 3) = rgb(:, :, 3) + X .* ((Hprime >= 5) & (Hprime <= 6));

    rgb(:, :, 1) = rgb(:, :, 1) + M;
    rgb(:, :, 2) = rgb(:, :, 2) + M;
    rgb(:, :, 3) = rgb(:, :, 3) + M;

    rgb = max(rgb, 0);
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
