function [bits_array, next_seed] = ...
    prop_rng_new(the_seed, Nbits, Nsweeps, lfsr_mask)
    % the_seed  The seed you gave the propeller
    % Nbits     The number of bits per modulation you requestion
    % Nsweeps   The number of DIFFERENT sweeps you wanted
    % lfsr_mask The LFSR_mask you supplied
    %
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

    if nargin < 1; the_seed = 1; end
    if nargin < 2; Nbits = 32; end
    if nargin < 3 ; Nsweeps = 1; end
    if nargin < 4; lfsr_mask = '8000000B'; end


    lfsr_mask_bin = hex2dec(lfsr_mask);

    the_seed = uint32(the_seed);

    bits_array = zeros(32 + (Nbits*Nsweeps), 1);

    bits_array(1:32) = (dec2bin(the_seed, 32) == '1');

    locations_look = find(dec2bin(lfsr_mask_bin) == '1');
    for i = 1:(Nbits*Nsweeps)
      bits_array(i+32) = ...
        mod(sum(bits_array(locations_look+i-1)), 2);
    end

    bits_array(1:32) = [];

    next_seed = char(bits_array(end-31:end) + '0')';
    next_seed = bin2dec(next_seed);
    bits_array = reshape(bits_array, Nbits, []);


    %{
    a = dec2bin(lfsr_mask);
    a(:) = '0';
    a(bits_array(1:32, 1) == 1) = '1';
    disp(['First 32 bits are = 0x', dec2hex(bin2dec(a))])
    %}
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
