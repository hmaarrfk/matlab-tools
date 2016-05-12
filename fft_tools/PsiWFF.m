function x = PsiWFF(y,w_type,log_length,min_scale,max_scale,shift_redundancy,freq_redundancy);
% Windowed Fourier Frame Synthesis
% x = PsiWFF(y,w_type,log_length,min_scale,max_scale,shift_redundancy,freq_redundancy);
%   w_type is the type of window.  Currently, this supports 'isine' (iterate sine)
%   and 'gaussian'.  Default: 'isine' (to use default, set this to [] ).
% written by Peter Stobbe, modified by Stephen Becker

if isempty(w_type), w_type = 'isine'; end

% w is a is a vector of with the window of the largest scale
% smaller scale windows are just this subsampled
[w, window_redundancy] = make_window(max_scale,w_type);

x = zeros(2^log_length,1);
c = ((max_scale - min_scale + 1)*window_redundancy*2.^((1:max_scale)'+freq_redundancy+shift_redundancy)).^-.5;
cur = 0;


for k = min_scale:max_scale
    M = 2^(log_length-k) +(2^(log_length-k)+1)*(2^shift_redundancy-1);
    N = 2^(k+freq_redundancy);
    z = reshape(y(cur + (1:N*M)),N,M);
    cur = cur + N*M;
    z = [z(1,:)*c(k);     z(2:N/2,:)*c(k-1);...
        z(N/2+1,:)*c(k); -1i*z(N/2+2:N,:)*c(k-1)];
    z = real(fft(z));
    z = z(1:2^k,:).*myRepMat(w(2^(max_scale-k)*(1:2^k)),M);
    z = reshape(z,[],2^shift_redundancy);
    x = x + sum(z(1:2^log_length,:),2);
end


%---------------

function B = myRepMat(A,n)
B = A(:,ones(n,1));

function [w,window_redundancy] = make_window(max_scale,w_type)
% [w,window_redundancy] = make_window(max_scale,w_type)
%   w_type can be
%       'isine' for iterated sine
%       'gaussian' for gaussian
%       'trapezoid' for trapezoidal shape (not a frame)

x = (1:2^max_scale)'/2^(max_scale-1)-1;
if isequal(w_type,'isine')
    w = sin(pi/4*(1+cos(pi*x)));
    window_redundancy = 1/2;
elseif isequal(w_type,'gaussian')
    w = exp(-x.^2*8*log(2));
    window_redundancy = mean(w.^2);
elseif isequal(w_type,'trapezoid')
    w = min(1,2*(1-abs(x)));
    window_redundancy = mean(w.^2);
else
    disp('Error in make_window: unknown window type');
    disp('Options are: isine, gaussian, trapezoid');
end

%{
Copyright (c) 2013, California Institute of Technology and CVX Research, Inc.
All rights reserved.

Contributors: Stephen Becker, Emmanuel Candes, and Michael Grant.
Based partially upon research performed under the DARPA/MTO Analog-to-
Information Receiver Development Program, AFRL contract #FA8650-08-C-7853.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

	1. Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the names of California Institute of Technology
	(Caltech), CVX Research, Inc., nor the names of its contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%}
