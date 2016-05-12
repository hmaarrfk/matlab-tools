# Matlab Tools

These are some of the tools that I developed over the duration of PhD.
They mostly include device interfaces that are common between the different
projects. I also have limited tools for easily creating figures and subfigures
with titles and larger fonts.

If you want examples of how to use any of this, post an issue on Github.


# Code organization

Most code is written to control instruments in a programatic way.
I think Matlab also allows you to control a few basic instrumetns but
I like to have full control over my instruments and didn't want
to deal with Matlab's simulink.

Most instruments are controlled via a class object. Classes in Matlab
can be included in a folder starting with an `@`. That is why
most files `DEVICE.m` are included in a folder `@DEVICE` allowing the
inclusion of the manual.

Personally, I added this repository in my directory:

  * Windows: `C:\Users\User\Documents\MATLAB\matlab-tools`
  * Linux: `/home/mark/Documents/MATLAB/matlab-tools`

To include the library in your matlab path, you probably want to add the
following lines in your `startup.m` file.

```Matlab
if ispc
    my_user_path = strrep(userpath, ';', '');
else
    my_user_path = strrep(userpath, ':', '');
end

% Includes all the instrument control tools
addpath([my_user_path, filesep, 'matlab-tools']);

% Includes other tools that are dispersed in subfolders

addpath([my_user_path, filesep, 'matlab-tools', filesep, 'fft_tools']);
addpath([my_user_path, filesep, 'matlab-tools', filesep, 'figure_tools']);
addpath([my_user_path, filesep, 'matlab-tools', filesep, 'propeller_tools']);
```

# License

## My code
All my source code is licensed under the
[BSD 3 Clause license (New BSD License or Modified BSD License)](https://en.wikipedia.org/wiki/BSD_licenses#3-clause_license_.28.22Revised_BSD_License.22.2C_.22New_BSD_License.22.2C_or_.22Modified_BSD_License.22.29).

I found it time consuming to find the license of the software that I used after
I had included it in my own directory. To make this easier for you, I added the
license to each individual file at the bottom. Hopefully it should make it
easier for you to integrate this code into your own library while keeping
everything legal.

That said, any file that does not include a license is still licensed under the
[LICENSE](LICENSE) file included in this repository.

### Device manuals

The device manuals, included for reference purposes, are not mine and are
simply distributed for reference purposes.

### Other included software.

I've also included software I have found useful from other's:
  * [figureFullScreen.m](figure_tools/figureFullScreen.m) was written by Nikolay S. His code can be found [here](http://www.mathworks.com/matlabcentral/fileexchange/31793-minimize-maximize-figure-window).
  * I've also included some functions from [TFOCS](http://cvxr.com/tfocs/) with their license included in their respective source files.
    * Relevant files are in [PsiTransposeWFF.m](fft_tools/PsiTransposeWFF.m) and [PsiWFF.m](fft_tools/PsiWFF.m).


## My software's license

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
