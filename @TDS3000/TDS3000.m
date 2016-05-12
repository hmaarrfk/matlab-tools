classdef TDS3000
  properties
    vendor;
    board_address;
    primary_address;
    interface_obj;
  end

  methods
    function self = TDS3000(vendor, board_index, primary_address)
      vendor_default = 'ni';
      board_index_default = 0;
      primary_address_default = 18;
      if nargin < 1; vendor = vendor_default; end
      if nargin < 2; board_index = board_index_default; end
      if nargin < 3; primary_address = primary_address_default; end

      self.vendor = vendor;
      self.board_index = board_index;
      self.primary_address = primary_address;

      self.interface_obj = instrfind('Type', 'gpib', 'BoardIndex', self.board_index, 'PrimaryAddress', self.primary_address, 'Tag', '';
      if ~isempty(self.interface_obj)
        fclose(self.interface_obj);
        delete(self.interface_obj)
      end

      self.interface_obj = gpib(self.vendor, self.board_index, self.primary_address);
      self.interface_obj.InputBufferSize = 100000; % make it large so that when we get a trace, it can all be read at once.


      self.open();
    end
    function open(self)
      fopen(self.interface_obj);
    end
    function close(self)
      if interface_obj ~= 0
        fclose(self.interface_obj);
        self.interface_obj = 0;
      end
    end
    function delete(self)
      self.close();
    end

    function get_data(channels_cell)

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
