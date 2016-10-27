classdef LDC3700 < handle
  properties
    gpib_handle
    vendor
    board_index
    primary_address
  end

  methods
    function self = LDC3700(vendor, board_index, primary_address)
      if nargin < 1; vendor = 'ni'; end
      if nargin < 2; board_index = 0; end
      if nargin < 3; primary_address = 2; end
      
      self.vendor = vendor;
      self.board_index = board_index;
      self.primary_address = primary_address;

      self.gpib_handle = instrfind('Type', 'gpib', 'BoardIndex', self.board_index, 'PrimaryAddress', self.primary_address, 'Tag', '');
      if ~isempty(self.gpib_handle)
        fclose(self.gpib_handle);
        delete(self.gpib_handle)
      end
      self.gpib_handle = gpib(self.vendor, self.board_index, self.primary_address);
      self.gpib_handle.InputBufferSize = 10000; % make it large so that when we get a trace, it can all be read at once.

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

    function [response, cmd] = ask(self, cmd)
      self.send(cmd);
      response = self.receive();
    end
    
    function [response, cmd] = identify(self)
      [response, cmd] = self.ask('*IDN?');
    end
    
    function current = laser_current(self, current)
       if nargin < 2;
          current = str2double(self.ask('LAS:LDI?')) * 1E-3;
       else
          self.send(['LAS:LDI ', num2str(current*1E3)]);
       end
    end
    
    function voltage = laser_voltage(self, voltage)
       if nargin < 2;
          voltage = str2double(self.ask('LAS:LDV?'));
       else
          self.send(['LAS:LDV ', num2str(voltage)]);
       end
    end
    
    function mode = laser_mode(self, mode)
       % acceptable values are
       % IHBW : current high bandwidth
       % ILBW : current low bandwidth
       % MDP  : constant power
       if nargin < 2
          mode = self.ask('LAS:MODE?');
       else
          self.send(['LAS:MODE:', mode]);
       end
    end
    
    function output = laser_output(self, output)
       if nargin < 2
          output = str2double(self.ask('LAS:OUT?'));
       else
          if output
             self.send('LAS:OUT 1');
          else
             self.send('LAS:OUT 0');
          end
       end
    end
    
    function laser_enable_output(self)
       self.laser_output(1);
    end
    function laser_disable_output(self)
       self.laser_output(0);
    end
    
    function temperature = tec_mode(self, temperature)
       % Correct values for t are
       % R resistance
       % T temperature
       % ITE current for the TE
       if nargin < 2
         temperature = self.ask('TEC:MODE?');
       else
          self.send(['TEC:MODE:', temperature]);
       end
    end
    
    function output = tec_output(self, output)
       if nargin < 2 
         output = str2double(self.ask('TEC:OUT?'));
       else
          if output
             self.send('TEC:OUT 1');
          else
             self.send('TEC:OUT 0');
          end
       end
    end
    function tec_enable_output(self)
       self.tec_output(1);
    end
    function tec_disable_output(self)
       self.tec_output(0);
    end
    
    % Setting the T/R/ITE setupoints is a little weird
    % you can query the actual values through TEC:T?
    % You can query the setpoint value through TEC:SET:T?
    % you set the setpoint value through TEC:T VAL
    function temperature = tec_t_setpoint(self, temperature)
       if nargin < 2;
          temperature = str2double(self.ask('TEC:SET:T?'));
       else
          self.send(['TEC:T ', num2str(temperature)]);
       end
    end
    
    function resistor = tec_r_setpoint(self, resistor)
       if nargin < 2;
          resistor = str2double(self.ask('TEC:SET:R?'));
       else
          self.send(['TEC:R ', num2str(resistor)]);
       end
    end
    
    function current = tec_ite_setpoint(self, current)
       if nargin < 2;
          current = str2double(self.ask('TEC:SET:ITE?'));
       else
          self.send(['TEC:R ', num2str(current)]);
       end
    end
    
    function temperature = tec_t_actual(self)
       temperature = str2double(self.ask('TEC:T?'));
    end
    
    function resitance = tec_r_actual(self)
       resitance = str2double(self.ask('TEC:R?'));
    end
    
    function current = tec_i_actual(self)
       current = str2double(self.ask('TEC:ITE?'));
    end
  end
end
