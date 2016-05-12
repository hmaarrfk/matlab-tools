function x = prop_rng(x, backwards)
% This code is supposed to emulate the random number generator in the
% propeller to reduce talking the amount of communication between the
% propeller and the computer (sending the huge matrix takes a really long
% time
%
%
% The code makes no attempt at being fast but literally writes each line of
% assembly as a few lines of matlab


% Proeller source code
% :rnd                    min     x,#1                    '?var/var?
%                         mov     y,#32
%                         mov     a,#%10111
%         if_nz           ror     a,#1
% :rndlp                  test    x,a             wc
%         if_z            rcr     x,#1
%         if_nz           rcl     x,#1
%                         djnz    y,#:rndlp       wc      'c=0
%                         jmp     #:stack
  x_default = 0;
  backwards_default = 0;

  if nargin < 1
    x = x_default;
  end
  if nargin < 2
    backwards = backwards_default;
  end


  x = fi(x, 0, 32, 0);
  y = 32;
  a = fi(bin2dec('10111'), 0, 32, 0);

  if ~backwards % if_nz
    a = bitror(a, 1);
  end

  while 1
    p = bitand(x,a); % check parity
    p = sum(bitand(p, fi(2.^(0:31), 0, 32, 0) )~=0);
    p = mod(p, 2);

    if backwards % if_z
      % rotate parity left
      x = bitror(x, 1);
      x = bitset(x, 32, p);
    else         % if_nz
      % rotate parity right
      x = bitrol(x, 1);
      x = bitset(x, 1, p);
    end

    y = y-1;
    if y == 0
      break;
    end
  end

  x = uint32(x);

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
