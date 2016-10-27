classdef HA9 < handle
   properties
      gpib_handle
      vendor
      board_index
      primary_address
   end
   methods
      function self = HA9(primary_address, board_index, vendor)
         if nargin < 1; primary_address = 11; end
         if nargin < 2; board_index = 0; end
         if nargin < 3; vendor = 'ni'; end
         self.vendor = vendor;
         self.board_index = board_index;
         self.primary_address = primary_address;
         
         self.gpib_handle = instrfind('Type', 'gpib', 'BoardIndex', self.board_index, 'PrimaryAddress', self.primary_address, 'Tag', '');
         if ~isempty(self.gpib_handle)
            fclose(self.gpib_handle);
            delete(self.gpib_handle)
         end
         self.gpib_handle = gpib(self.vendor, self.board_index, self.primary_address);
         
         fopen(self.gpib_handle);
      end
      
      function open(self)
         fopen(self.gpib_handle);
      end
      
      function close(self)
         fclose(self.gpib_handle);
      end
      function delete(self)
         self.close();
      end
      
      function cmd = send(self, cmd)
         fprintf(self.gpib_handle, cmd);
      end
      
      function response = receive(self)
         response = fscanf(self.gpib_handle);
      end
      
      function response = ask(self, cmd)
         self.send(cmd);
         response = self.receive();
      end
      
      function response = identify(self)
         response = self.ask('IDN?');
      end
      
      function d = beam_block(self, d)
         if nargin < 2
            d = self.ask('D?'); 
         else  
            if d; d = 1; else d = 0; end
            self.send(['D ', num2str(d)]);
         end
      end
      
      function beam_block_on(self)
         self.beam_block(1);
      end
      function beam_block_off(self)
         self.beam_block(0);
      end
      
      function w = wavelength(self, w)
         if nargin < 2
            w = str2double(self.ask('WVL?'));
         else
            self.send(['WVL ', num2str(w, '%.5e')]);
         end
      end
      
      function a = attenuation(self, a)
         if nargin <2;
            a = str2double(self.ask('ATT?'));
         else
            self.send(['ATT ', num2str(a, '%.3d')]);
         end
      end
      function a_max = attenuation_max(self)
         a_max = str2double(self.ask('ATT? MAX'));
      end
      function a_min = attenuation_min(self)
         a_min = str2double(self.ask('ATT? MIN'));
      end
   end
end