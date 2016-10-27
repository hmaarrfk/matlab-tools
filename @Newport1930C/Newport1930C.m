%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Device function to control the Newport 1930C powermeter
% Original code by Dongwan and Mark 
% Modified by Mark Harfouche to enable usage of Instrument Control toolbox.
% 2016/05/17
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Newport1930C < handle
   properties (SetAccess = private)
      % Various GPIB parameters used to find the device and determine the
      % communication standard used (end-of-string, etc.)
      gpibBoardIndex = 0;
      gpibPrimaryAddress = 18;
      gpibSecondaryAddress = 0;
      gpibTimeout = 1; % Was 12 before
      gpibwriteEOI = 1;
      gpibEOS = 0;
            
      % Matlab instrument control toolbox handle
      dev_handle;
   end

   methods
      function obj = Newport1930C()
         obj.dev_handle = instrfind('Type', 'gpib', ...
            'BoardIndex', obj.gpibBoardIndex, ...
            'PrimaryAddress', obj.gpibPrimaryAddress, 'Tag', '');
         if isempty(obj.dev_handle)
            obj.dev_handle = gpib('NI', obj.gpibBoardIndex, obj.gpibPrimaryAddress);
         else
            fclose(obj.dev_handle);
            obj.dev_handle = obj.dev_handle(1);
         end
         obj.dev_handle.Timeout = obj.gpibTimeout;
         obj.dev_handle.EOIMode = 'on';
         obj.dev_handle.EOSMode = 'none';
         fopen(obj.dev_handle);
      end

      function delete(obj)
         fclose(obj.dev_handle);
      end

      function write(obj, command)
         fwrite(obj.dev_handle, command);
      end

      function response = read(obj)
         response = fscanf(obj.dev_handle, '%s');
      end

      function response = ask(obj, command)
         obj.write(command);
         response = obj.read();
      end
      
      function r = identify(obj)
         r = obj.ask('*IDN?');
      end
      
      % Read the power
      function response = power(obj)
         response = str2double(obj.ask('R?'));
      end
      
      function u = units(obj, u)
         % <units> is of type <string>.
         % All possible values of units are listed below:
         % “A” specifies amps
         % “W” specifies watts
         % “dBm” specifies dBm
         % “dB” specifies dB
         % “REL” specifies linear ratio
         if nargin < 2
            u = obj.ask('UNITS?');
         else
            obj.write(['UNITS ' u]);
         end
      end
        
      function a = auto(obj, a)
          if nargin < 2
            a = str2double(obj.ask('AUTO?'));
          else
             if a; obj.write('AUTO 1');
             else  obj.write('AUTO 0'); end
          end
       end
       
       function f = filter(obj, f)
         % The parameter <filter> is an integer in the range 0 to 3 inclusive.
         % 0 corresponds to no filtering,
         % 1 to analog filter only,
         % 2 to digital averaging filter only, and 
         % 3 to analog and digital filters combined
         if nargin < 2 
            f = str2double(obj.ask('FILTER?'));
         else
            obj.write(['FILTER ', num2str(f)]);
         end
       end
       function i = filter_interval(obj, i)
          % MATLAB FUNCTION UNITS: seconds (not milliseconds)
          % Parameters:
          % The parameter <interval>is of type <number>
          % which is an integer and must be: 1, 10, 20, 50, 100, or 1000. 
          % The parameter represents the interval in milliseconds for storing one measurement in the digital filter buffer.
          % Function:
          % This command sets the interval in milliseconds to be used 
          % for digital filtering. For example if FILTINT = 100 ms, 
          % it will take 100ms x 16 = 1600 ms to fill the filter buffer the 
          % first time. After that the filter will recalculate the 
          % moving average every 100ms (as set by FILTINT).
          if nargin < 2
             i = str2double(obj.ask('FILTINTerval?'))*1E-3;
          else
             obj.write(['FILTINTerval ', num2str(i*1E3)])
          end
       end
       
       function filter_digital_and_analog(obj, interval)
          obj.filter(3);
          if nargin >= 2
             obj.filter_interval(interval);
          end
       end
      
       function l = lambda(obj, l)
          % units : nm
          if nargin < 2
             l = str2double(obj.ask('LAMBDA?')) * 1E-9;
          else
             obj.write(['LAMBDA ', num2str(l * 1E9, '%.0f')]);
          end
       end
      
       function m = mode(obj, m)
          % “DCSNGL” specifies DC single mode
          % “DCCONT” specifies DC continuous mode
          if nargin < 2
             m = obj.ask('MODE?');
          else
             obj.write(['MODE ', m]);
          end
       end
       
       function acquisition_continuous(obj)
          obj.mode('DCCONT');
       end
       
       function acquisition_single(obj)
          obj.mode('DCSNGL');
       end
      
       function response = range(obj)
         % Too complicated. Use autoranging
       end
       
             
       function v = reference_value(obj, v)
          if nargin < 2
             v = str2double(obj.ask('USRREF?'));
          else
             obj.send(['USRREF ', num2str(v, '%.6e')]);
          end
       end
   end
end