classdef DG1022
  properties
    vendor
    rsrcname
    handle
  end

  methods
    function dg1022 = DG1022(vendor, rsrcname)
      %Create an object for the DG1022
      % Call with DG1022(vendor)
      % or        DG1022(vendor, rsrcname)
      % the default value of vendor is 'ni'
      % there is no default value for rsrcname
      % warning the rsrcname is not the one that is seen on the Rigol
      % control pannel, figures they would have info that is actually
      % useful
      rsrcname_default = 'USB0::0x1AB1::0x0588::DG1D120900507::INSTR';
      vendor_default = 'ni';
      if nargin <2
        vendor = vendor_default;
      end
      if nargin < 3
        rsrcname = rsrcname_default;
      end

      search_string = regexprep(rsrcname, 'USB', 'VISA-USB-');
      search_string = regexprep(search_string, '::', '-');
      search_string = regexprep(search_string, 'INSTR', '0');

      vs = instrfind('Type', 'visa-usb', 'name', search_string);

      if isempty(vs)
          vs = visa(vendor, rsrcname);
      else
          fclose(vs);
          vs = vs(end);
      end
      dg1022.handle = vs;
      dg1022.vendor = vendor;
      dg1022.rsrcname = rsrcname;

      fopen(dg1022.handle);

      return;
    end

    function open(dg1022)
      fopen(dg1022.handle);
    end
    function close(dg1022)
      fclose(dg1022.handle);
    end
    function delete(dg1022)
      dg1022.close();
    end

    function cmd = send(dg1022, cmd)
      fprintf(dg1022.handle, cmd);
    end

    function response = receive(dg1022)
      response = fscanf(dg1022.handle);
    end

    function [response, cmd] = ask(dg1022, cmd)
      cmd = dg1022.send(cmd);
      response = dg1022.receive();
    end

    function [response, cmd] = setAndAsk(dg1022, set_cmd, ask_cmd)
      cmd = dg1022.send(set_cmd);
      % This pause is important because when things set a command
      % becuase there is lag in the application of properties since
      % the rigol needs to switch regulators
      pause(1E-1);
      response = dg1022.ask(ask_cmd);
    end

    function [response, cmd] = identify(dg1022)
      cmd = '*IDN?';
      [response, cmd] = dg1022.ask(cmd);
    end

    function [response, cmd] = functionSet(dg1022, channel, type)
      % Type can be either SINusoid, SQUare, RAMP, PULSe, NOISe, DC, USER
      channel_default = 1;
      type_default = -1;

      cmd = sprintf('FUNCtion');
      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        type = type_default;
      end

      if channel == 2
        cmd = [cmd, ':CH2'];
      elseif channel ~= 1
        response = 'Input error, Channel must be 1 or 2';
        return;
      end

      if ischar(type)
        type = strtrim(type);
      end

      ask_cmd = [cmd, '?'];

      % could possibly make this easier with cell string
      if (isnumeric(type) && type == -1) || (ischar(type) && strcmpi(type, '?'))
        set = 0;
      elseif ischar(type) && sum(strcmpi(type, {'SIN', 'SINusoid', 'SQU', 'SQUare', 'RAMP', 'PULS', 'PULSe', 'NOIS', 'NOISe', 'DC', 'USER'}))>0
        set = 1;
        set_cmd = [cmd, ' ', type];
      else
        response = 'Input error, type must be set appropriately';
        print type
        return;
      end

      if set == 1
        [response, cmd] = dg1022.setAndAsk(set_cmd, ask_cmd);
      else
        [response, cmd] = dg1022.ask(ask_cmd);
      end
    end

    function [response, cmd] = outputLoad(dg1022, channel, load)
      %
      channel_default = 1;
      load_default = -1;

      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        load = load_default;
      end

      cmd = 'OUTPut:LOAD';
      if channel == 2
        cmd = [cmd, ':CH2'];
      elseif channel ~= 1
        response = 'Input error, Channel must be 1 or 2';
        return;
      end

      ask_cmd = [cmd, '?'];

      if ischar(load)
        load = strtrim(load);
      end

      if (isnumeric(load) && load == -1) || (ischar(load) && strcmpi(load, '?') == 1)
        set = 0;
      elseif ischar(load) && sum(strcmpi(load, {'INF', 'INFINITY', 'MIN', 'MINimum', 'MAX', 'MAXimum'})) > 0
        set = 1;
        set_cmd = [cmd, ' ', load];
      elseif isnumeric(load)
        set = 1;
        set_cmd = [cmd, ' ', num2str(round(load), '%.0f')];
      else
        response = 'Input error, invalid load';
        return;
      end

      if set == 1
        [response, cmd] = dg1022.setAndAsk(set_cmd, ask_cmd);
      else
        [response, cmd] = dg1022.ask(ask_cmd);
      end
    end

    function [response, cmd] = outputPolarity(dg1022, channel, inverted)
      channel_default = 1;
      inverted_default = -1;
      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        inverted = inverted_default;
      end


      cmd = 'OUTPut:POLarity';
      if channel == 2
        cmd = [cmd, ':CH2'];
      elseif channel ~= 1
        response = 'Input error, Channel must be 1 or 2';
        return;
      end

      ask_cmd = [cmd, '?'];

      if ischar(inverted)
        inverted = strtrim(inverted);
      end

      if (isnumeric(inverted) && inverted == -1) || (ischar(inverted) && strcmpi(inverted, '?'))
        set = 0;
      elseif (isnumeric(inverted) && inverted == 1) || (ischar(inverted) && sum(strcmpi(inverted, {'INV', 'INVerted'})) > 0)
        set = 1;
        set_cmd = [cmd, ' INVerted'];
      elseif (isnumeric(inverted) && inverted == 0) || (ischar(inverted) && sum(strcmpi(inverted, {'NORM', 'NORMal'})) > 0)
        set = 1;
        set_cmd = [cmd, ' NORMal'];
      else
        response = 'Input error, inverted must be  must be (-1 or ?), (0 or NORMal) or (1 or INVerted)';
        return;
      end

      if set == 1
        [response, cmd] = dg1022.setAndAsk(set_cmd, ask_cmd);
      else
        [response, cmd] = dg1022.ask(ask_cmd);
      end
    end

    function [cmd] = data(dg1022, value, normalize)
      normalize_default = false;

      if nargin < 2 || isnumeric(value) == 0
        cmd = 'We require at least one number for value';
        return;
      end

      if nargin < 3
        normalize = normalize_default;
      end

      if normalize == true
        value = value / max(abs(value));
      end

      cmd = 'DATA VOLATILE';
      for i=1:length(value)
        % unfortunately, the behaviour of num2str is unpredictable
        % for negative numbers at least
        cmd = [cmd, ',', num2str(value(i), '%2.6f')];
      end

      dg1022.send(cmd);

      return;
    end

    function [cmd] = dataDAC(dg1022, value, normalize)
      normalize_default = false;

      if nargin < 2 || isnumeric(value) == 0
        cmd = 'We require at least one number for value';
        return;
      end

      if nargin < 3
        normalize = normalize_default;
      end

      if normalize == true
        value = value + min(value);
        value = floor(value / max(abs(value)) * 16383);
      end

      cmd = 'DATA:DAC VOLATILE';
      for i=1:length(value)
        % unfortunately, the behaviour of num2str is unpredictable
        % for negative numbers at least
        cmd = [cmd, ',', num2str(value(i), '%.0f')];
      end

      dg1022.send(cmd);
      return;
    end

    function [cmd] = dataCopy(dg1022, destination_arb_name)
      if nargin < 2 || ischar(destination_arb_name) == 0
        cmd = 'We need the name of an arbitrary wave form to save to';
        return;
      end

      cmd = ['DATA:COPY ', destination_arb_name];
      dg1022.send(cmd);
      return;
    end

    function [cmd] = dataDelete(dg1022, arb_name)
      if nargin < 2 || ischar(arb_name) == 0
        cmd = 'Error: require the name of an arbitrary waveform to delete';
        return;
      end
      cmd = ['DATA:DELete ', arb_name];
      dg1022.send(cmd);
    end

    function [response, cmd] = dataCatalog(dg1022)
      cmd = 'DATA:CATalog?';
      [response, cmd] = dg1022.ask(cmd);
      return;
    end

    function [cmd] = dataRename(dg1022, old_name, new_name)
      if nargin < 3 || ischar(old_name) == 0 || ischar(new_name) == 0
        cmd = 'Error: old_name and new_name must be strings';
        return;
      end

      cmd = ['DATA:RENAME ', old_name, ', ', new_name];
      dg1022.send(cmd);
    end

    function [response, cmd] = dataNonVolatileCatalog(dg1022)
      cmd = 'DATA:NVOLatile:CATalog?';
      [response, cmd] = dg1022.ask(cmd);
      return;
    end

    function [response, cmd] = dataNonVolatileFree(dg1022)
      cmd = 'DATA:NVOLatile:FREE?';
      [response, cmd] = dg1022.ask(cmd);
      response = str2num(response);
      return;
    end

    function [response, cmd] = dataAttributePoints(dg1022, arb_name)
      if nargin < 2 || ischar(arb_name) == 0
        cmd = 'Error: require the name of an arbitrary waveform to query';
        return;
      end
      cmd = ['DATA:ATTRibute:POINTs? ', arb_name];
      [response, cmd] = dg1022.ask(arb_name);
    end

    function [cmd] = dataLoad(dg1022, arb_name);
      if nargin < 2 || ischar(arb_name) == 0
        cmd = 'Error: require the name of an arbitrary waveform to load';
        return;
      end

      cmd = ['DATA:LOAD ', arb_name];
      dg1022.send(cmd);
    end


    function [response, cmd] = phase(dg1022, channel, phase, align)
      channel_default = 1;
      phase_default = -234;
      align_default = false;

      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        phase = phase_default;
      end
      if nargin < 4
        align = align_default;
      end

      cmd = 'PHASE';
      if channel == 2
        cmd = [cmd, ':CH2'];
      end

      ask_cmd = [cmd, '?'];

      if phase == phase_default
        set = 0;
      else
        set = 1;
        % this magically wraps it in the right range;
        phase = phase - floor((phase + 180)/360) * 360;
        set_cmd = [cmd, ' ', num2str(phase, '%.3f')];
      end

      if set == 1
        [response, cmd] = dg1022.setAndAsk(set_cmd, ask_cmd);
      else
        [response, cmd] = dg1022.ask(ask_cmd);
      end

      if align ~= false
        dg1022.phaseAlign();
      end
    end

    function [cmd] = phaseAlign(dg1022)
      cmd = 'PHASe:ALIGn';
      dg1022.send(cmd);
    end

    function [response, cmd] = apply(dg1022, channel)
      channel_default = 1;
      if nargin < 2
        channel = channel_default;
      end

      cmd = ['APPLy'];
      if channel == 2
        cmd = [cmd, ':CH2'];
      end
      cmd = [cmd, '?'];

      [response, cmd] = dg1022.ask(cmd);
    end


    function [response, cmd] = applyDC(dg1022, channel, value)
      channel_default = 1;
      value_default = 0;

      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        value = value_default;
      end

      if channel == 1
        cmd = 'APPLy:DC DEFault,DEFault,';
      else
        cmd = 'APPLy:DC:CH2 DEFault,DEFault,';
      end
      cmd = [cmd, num2str(value, '%.6g')];

      dg1022.send(cmd);
      pause(1e-1);
      response = dg1022.apply(channel);
    end


    function [response, cmd] = output(dg1022, channel, enabled)
      %
      channel_default =  1;
      enabled_default = -1;
      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        enabled = enabled_default;
      end

      cmd = 'OUTput';
      if channel == 2
        cmd = [cmd, ':CH2'];
      elseif channel ~= 1
        response = 'Input error, Channel must be 1 or 2';
        return;
      end

      ask_cmd = [cmd, '?'];

      if (isnumeric(enabled) && enabled == -1) || (ischar(enabled) && strcmpi(enabled, '?'))
        set = 0;
      elseif (islogical(enabled) && enabled == true) || (isnumeric(enabled) && enabled == 1) || (ischar(enabled) && strcmpi(enabled, 'ON'))
        set = 1;
        set_cmd = [cmd, ' ON'];
      elseif (islogical(enabled) && enabled == false) || (isnumeric(enabled) && enabled == 0) || (ischar(enabled) && strcmpi(enabled, 'OFF'))
        set = 1;
        set_cmd = [cmd, ' OFF'];
      else
        response = 'Input error, enabled must be -1, (0 or ON), or (1 or OFF)';
        return;
      end

      if set == 1
        [response, cmd] = dg1022.setAndAsk(set_cmd, ask_cmd);
      else
        [response, cmd] = dg1022.ask(ask_cmd);
      end
    end


    % Functions below here are probably badly coded


    function [response, cmd] = functionUser(dg1022, channel, name)
      channel_default = 1;
      name_default = -1;

      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        name = name_default;
      end

      cmd = 'FUNCtion:USER';
      if channdocuel == 2
        cmd = [cmd, ':CH2'];
      elseif channel ~= 1
        response = 'Input error, channel must be 1 or 2';
        return;
      end

      if name == -1 || strcmpi(name, '?')
        cmd = cmd +'?';
      elseif ~isnumeric(name)
        cmd = cmd + ' ' + name;
      else
        response = 'Input error, name must be the name of a valid arbitrary wave (not a number)';
        return;
      end

      [response, cmd] = dg1022.ask(cmd);
    end

    function [response, cmd] = squareDutyCycle(dg1022, channel, duty_cycle)
      channel_default = 1;
      duty_cycle_default = -1;

      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        duty_cycle = duty_cycle_default;
      end

      cmd = 'FUNCtion:SQUare:DCYCle';

      if channel == 2
        cmd = [cmd, ':CH2'];
      elseif channel ~= 1
        response = 'Input error, channel must be 1 or 2';
        return;
      end

      %TODO: find out how to print this properly
      % Desired format: 50.000000.
      if duty_cycle == -1
        cmd = cmd + '?';
      elseif isnumeric(duty_cycle)
        temp = sprintf('%f', duty_cycle');
        cmd = cmd + ' ' + temp;
      elseif strcmpi(duty_cycle, 'MIN') || strcmpi(duty_cycle, 'MINimum')
        cmd = cmd + ' MINimum';
      elseif strcmpi(duty_cycle, 'MAX') || strcmpi(duty_cycle, 'MAXimum')
        cmd = cmd + ' MAXimum';
      else
        response = 'Input error, wrong format for duty_cucle, must be numeric, MINimum, or MAXimum';
        return;
      end

      [response, cmd] = dg1022.ask(cmd);
    end

    function [response, cmd] = rampSymmetry(dg1022, channel, symmetry)
      channel_default = 1;
      symmetry_default = -1;

      if nargin < 2
        channel = channel_default;
      end
      if nargin < 3
        symmetry = symmetry_default;
      end

      cmd = 'FUNCtion:RAMP:SYMMetry';

      if channel == 2
        cmd = [cmd, ':CH2'];
      elseif channel ~= 1
        response = 'Input error, channel must be 1 or 2';
        return;
      end

      if symmetry == -1
        cmd = cmd + '?';
      elseif isnumeric(symmetry)
        %TODO format correctly 50.000000
        cmd = cmd + ' ' + num2str(symmetry);
      elseif strcmpi(symmetry, 'MIN') || strcmpi(symmetry, 'MINimum')
        cmd = cmd + ' MINimum';
      elseif strcmpi(symmetry, 'MAX') || strcmpi(symmetry, 'MAXimum')
        cmd = cmd + ' MAXimum';
      else
        response = 'Input error, wrong format for symmetry, must be numeric, MINimum, or MAXimum';
        return;
      end

      [response, cmd] = dg1022.ask(cmd);
    end

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
