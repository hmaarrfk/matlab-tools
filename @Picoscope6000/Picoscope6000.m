% ps6000.m
% Copyright Mark Harfouche 2012
%
% This class wraps the functions provided by the Picoscope 6000
% For use in Matlab
%

classdef Picoscope6000 < handle
  properties (Constant)
      libname = 'ps6000';
  end
  properties
    pico_handle; % a handle for the picoscope

    channel_enabled; % holds the current state of all the channels
    channel_range;   % 2=50mV, 3=100mV, 4=200mV, 5=500mV, 6=1V, 7=2V, 8=5V, 9=10V, 10=20V


    % set these in GetTimebase2
    T_measure; % amount of time you are measuring for
    T_sample_desired; % seconds
    timebase; % weird number needed for internal calls (related to T_sample desired)

    T_sample_actual;  % seconds (computed from timebase by the scope itself)

    N_samples; % number of samples per segment (per channel)


    % defines
    CHANNELS;
    CHANNEL_COUPLINGS;
    CHANNEL_RANGE;
    CHANNEL_RANGES;
    THRESHOLD_TYPE;
    UNIT_INFO_TYPES;
    WAVE_TYPES;
    SIGGEN_TRIGGER_TYPES;
    SIGGEN_TRIGGER_SOURCES;

    AWGPhaseAccumulatorSize;
    AWGBufferAddressWidth;
    AWGMaxSamples;

    AWGDACInterval;
    AWGDACFrequency;
    AWGMaxVal;
    AWGMinVal;
  end % properties

  methods
    function self = Picoscope6000()
      % A few constants
      self.CHANNELS.A = 0;
      self.CHANNELS.B = 1;
      self.CHANNELS.C = 2;
      self.CHANNELS.D = 3;
      self.CHANNELS.EXTERNAL = 4;
      self.CHANNELS.PS6000_TRIGGER_AUX = 5;

      self.CHANNEL_COUPLINGS.AC   = 0;
      self.CHANNEL_COUPLINGS.DC   = 1;
      self.CHANNEL_COUPLINGS.DC50 = 2;

      self.CHANNEL_RANGE =  [ 10E-3, 20E-3, 50E-3, ...
                              100E-3, 200E-2 500E-3, ...
                              1, 2, 5];
      self.CHANNEL_RANGES.mV10 = 0;
      self.CHANNEL_RANGES.mV20 = 1;
      self.CHANNEL_RANGES.mV50 = 2;
      self.CHANNEL_RANGES.mV100 = 3;
      self.CHANNEL_RANGES.mV200 = 4;
      self.CHANNEL_RANGES.mV500 = 5;
      self.CHANNEL_RANGES.V1 = 6;
      self.CHANNEL_RANGES.V2 = 7;
      self.CHANNEL_RANGES.V5 = 8;
      self.CHANNEL_RANGES.V10 = 9;
      self.THRESHOLD_TYPE.Above      = 0;
      self.THRESHOLD_TYPE.Below      = 1;
      self.THRESHOLD_TYPE.Rising     = 2;
      self.THRESHOLD_TYPE.Falling    = 3;
      self.THRESHOLD_TYPE.RiseOrFall = 4;

      self.UNIT_INFO_TYPES.DriverVersion           =  0;
      self.UNIT_INFO_TYPES.USBVersion              =  1;
      self.UNIT_INFO_TYPES.HardwareVersion         =  2;
      self.UNIT_INFO_TYPES.VariantInfo             =  3;
      self.UNIT_INFO_TYPES.BatchAndSerial          =  4;
      self.UNIT_INFO_TYPES.CalDate                 =  5;
      self.UNIT_INFO_TYPES.KernelVersion           =  6;
      self.UNIT_INFO_TYPES.DigitalHardwareVersion  =  7;
      self.UNIT_INFO_TYPES.AnalogueHardwareVersion =  8;
      self.UNIT_INFO_TYPES.PicoFirmwareVersion1    =  9;
      self.UNIT_INFO_TYPES.PicoFirmwareVersion1    = 10;

      self.WAVE_TYPES.Sine       = 0;
      self.WAVE_TYPES.Square     = 1;
      self.WAVE_TYPES.Triangle   = 2;
      self.WAVE_TYPES.RampUp     = 3;
      self.WAVE_TYPES.RampDown   = 4;
      self.WAVE_TYPES.Sinc       = 5;
      self.WAVE_TYPES.Gaussian   = 6;
      self.WAVE_TYPES.HalfSine   = 7;
      self.WAVE_TYPES.DCVoltage  = 8;
      self.WAVE_TYPES.WhiteNoise = 9;

      self.SIGGEN_TRIGGER_TYPES.Rising   = 0;
      self.SIGGEN_TRIGGER_TYPES.Falling  = 1;
      self.SIGGEN_TRIGGER_TYPES.GateHigh = 2;
      self.SIGGEN_TRIGGER_TYPES.GateLow  = 3;

      self.SIGGEN_TRIGGER_SOURCES.None       = 0;
      self.SIGGEN_TRIGGER_SOURCES.ScopeTrig  = 1;
      self.SIGGEN_TRIGGER_SOURCES.AuxIn      = 2;
      self.SIGGEN_TRIGGER_SOURCES.ExtIn      = 3;
      self.SIGGEN_TRIGGER_SOURCES.SoftTrig   = 4;
      self.SIGGEN_TRIGGER_SOURCES.TriggerRaw = 5;


      % Constructor for the Picoscope6000 class
      % opens the only available Picoscope6000

      if libisloaded(self.libname) ~= 1
        loadlibrary ('ps6000.dll','ps6000Api.h');
        %if libisloaded(self.libname) ~= 1
        %  error('Could not load Picoscope Library');
        %  return;
        %end
      end
      pico_handle_ptr = libpointer('int16Ptr',0);
      r = calllib(self.libname, 'ps6000OpenUnit', pico_handle_ptr, []);
      self.pico_handle = pico_handle_ptr.value;
      if r ~= 0
        self.check_error(r);
        return;
      end
      % by default the picoscope starts with all channels enabled
      % save that as the current state
      self.channel_enabled = ones(4, 1);

    end % Constructor ps6000
    function r = close(self)
      % Destructor
      %
      r = calllib(self.libname, 'ps6000CloseUnit', self.pico_handle);
      self.check_error(r)
      self.pico_handle = 0;
    end

    function check_error(self, error_code)
      if error_code ~= 0
        dbstack;
        fprintf(2,  'Error code 0x%s -- %s \n', dec2hex(error_code), self.errorToString(error_code));
      end
    end

    function i = getInfo(self, info)
        reqSize = libpointer('int16Ptr', zeros(1, 1));
        [r, i] = calllib(self.libname, 'ps6000GetUnitInfo', self.pico_handle, ...
            blanks(100), ...
            100, ...
            reqSize, ...
            info);
    end

    function SetChannel(self, channel_num, enable, coupling, range, offset, bandwidth)
      if nargin < 2; channel_num = self.CHANNELS.A; end
      if nargin < 3; enable = 0; end
      if nargin < 4; coupling = self.CHANNEL_COUPLINGS.DC; end
      if nargin < 5; range = self.RANGE; end
      if nargin < 6; offset = 0; end
      if nargin < 7; bandwidth = 0; end

      r = calllib(self.libname, 'ps6000SetChannel', self.pico_handle, ...
        channel_num,... %0=channelA, 1=channelB, 2=channelC, 3=channelD
        enable,... %0=disable, %1=enable
        coupling,... %0=AC, 1=DC_1M, 2=DC50
        range,... %2=50mV, 3=100mV, 4=200mV, 5=500mV, 6=1V, 7=2V, 8=5V, 9=10V, 10=20V
        offset,... %analog offset
        bandwidth);    %0=Full BW, 1=20MHz

      if r ~= 0; self.check_error(r); return; end

      % if all goes well, change the state of the channel
      self.channel_enabled(channel_num+1) = enable;
      self.channel_range(channel_num+1) = range;
    end

    function n = N_channels(self)
      n = sum(self.channel_enabled);
    end

    function max_samples = GetTimebase2(self, T_sample, T_measure, oversample_bits)
      % This is actually setting the timebase, but it returns the actual
      % nearest timebase to what you desire

      T_sample_default = 1E-6; % 1 us
      T_measure_default = 1E-3; % 1 ms
      oversample_bits_default = 0;
      if nargin < 2; T_sample = T_sample_default; end
      if nargin < 3; T_measure = T_measure_default; end
      if nargin < 4; oversample_bits = oversample_bits_default; end

      self.T_sample_desired = T_sample;
      self.T_measure = T_measure;

      % Timebase: Weird number that describes the desired sampling rate, see pp. 18, section 3.7
      self.timebase        = round(self.T_sample_desired* 156250000 + 4);
      self.N_samples       = round(T_measure / T_sample);

      T_sample_actual_ptr = libpointer('singlePtr',0); % in nano seconds
      max_samples_ptr     = libpointer('uint32Ptr',0);

      r = calllib(self.libname, 'ps6000GetTimebase2', self.pico_handle, ...
       self.timebase, ...    % Timebase: Weird number that describes the desired sampling rate, see pp. 18, section 3.7
       self.N_samples * self.N_channels, ...   % The desired number of samples for all channels
       T_sample_actual_ptr, ... % The actual sampling rate in nano seconds
       oversample_bits, ...               % The number of bits of oversample to keep
       max_samples_ptr, ...     % The maximum number of samples available sampling at the actual sampling rate
       0);                  % Use the 0th segmentIndex of the memory
     if r ~= 0
       self.check_error(r);
       return;
     end

     self.T_sample_actual = double(T_sample_actual_ptr.value) / 1E9; % back in seconds
     max_samples     = double(max_samples_ptr.value);
    end

    function max_samples_per_segment = MemorySegments(self, N_segments)
      % check yourself (for now) that this is a valid value (ie. each
      % segment still has enough samples)
      % you can do this by checking that
      % max_samples_per_segment > N_channles * N_samples
      %
      %
      % max_samples_per_segment is the maximum number of samples per memory segment for
      % all channels. So if you have 4 channels enabled, you only have 1/4
      % of the max_samples
      N_segments_default = 1;
      if nargin < 2
        N_segments = N_segments_default;
      end
      max_samples_ptr         = libpointer('uint32Ptr',0);
      r = calllib(self.libname, 'ps6000MemorySegments', self.pico_handle, ...
          N_segments, ... % The number of segments, The 6403 has 1GS
          max_samples_ptr);
      if r ~= 0
        self.check_error(r);
        return;
      end
      max_samples_per_segment = double(max_samples_ptr.value);
    end

    function SetSimpleTrigger(self, enable, channel, value, condition, delay, autoTrigger_ms)
      % Warning value unused and hardcoded
      enable_default = 0; % disabled
      channel_default = 0; % channel A
      value_default = 0; %
      condition_default = 2; % Rising
      delay_default = 0; % no delay
      autoTrigger_ms_default = 1000;

      if nargin < 2; enable = enable_default; end
      if nargin < 3; channel = channel_default; end
      if nargin < 4; value = value_default; end
      if nargin < 5; condition = condition_default; end
      if nargin < 6; delay = delay_default; end
      if nargin < 7; autoTrigger_ms = autoTrigger_ms_default; end

      r = calllib(self.libname, 'ps6000SetSimpleTrigger', self.pico_handle, ...
        enable, ... % 1 = enable, 0 disable
        channel, ... % Trigger Channel: 0=channelA, 1=channelB, 2=channelC, 3=channelD
        floor(1/10 * 32512), ... % Trigger value on the ADC, the maximum value is 32512, Trigger on 1/10 of the maximum voltage of the channel
        condition, ... % Trigger condition: 0 = ABOVE, 1 = BELOW, 2 = RISING, 3 = FALLING, 4 = RISING_OR_FALLING
        delay, ... % Delay (in the Timebase) between trigger and first sample
        autoTrigger_ms); % autoTrigger_ms, number of ms the scope will wait in the event of no trigger before triggering.
      if r ~= 0; self.check_error(r); return; end
    end

    function SetSigGenBuiltIn(self, offset, peak_to_peak, wavetype, frequency)
      offset_default = 0;
      peak_to_peak_default = 1;
      wavetype_default = 1; % square wave
      frequency_default = 100000;

      if nargin < 2; offset = offset_default; end
      if nargin < 3; peak_to_peak = peak_to_peak_default; end
      if nargin < 4; wavetype = wavetype_default; end
      if nargin < 5; frequency = frequency_default; end

      r = calllib(self.libname, 'ps6000SetSigGenBuiltIn', self.pico_handle, ...
        round(offset * 1E6), ... % offset voltage in microV
        round(peak_to_peak * 1E6), ... % peak to peak voltage in microV
        wavetype, ... \% Wavetype: 0 = SINE, 1 = SQUARE, 2= TRIANGLE ...
        frequency, ... % Start Frequency (in Hz???)
        frequency, ... % Stop Frequency
        1.0,  ... % Frequency increment
        1.0,  ... % Dwell time
        0,  ... % Sweep type
        0,  ... % White noise signal operation (don't care)
        1,  ... % shots, number of signals to generate after a trigger
        1,  ... % sweeps, the number of times to sweep the frequency after a trigger
        0,  ... % Trigger type ( 0 = rising ...)
        0,  ... % Trigger source (0 = none ...)
        0); % Ext in threshold
      if r ~= 0
        self.check_error(r);
        return;
      end
    end

    function SetNoOfCaptures(self, N_captures)
      % Set the number of captures in block mode acquisition
      N_average_default = 1;
      if nargin < 2
        N_captures = N_average_default;
      end
      r = calllib(self.libname, 'ps6000SetNoOfCaptures', self.pico_handle, N_captures);
      if r ~= 0; self.check_error(r); return; end
    end

    function timeIndisposed = RunBlock(self, pre_trigger_samples)
      pre_trigger_samples_default = 0;
      if nargin < 2
        pre_trigger_samples = pre_trigger_samples_default;
      end

      timeIndisposedMS_ptr = libpointer('int32Ptr', 0);
      r = calllib(self.libname, 'ps6000RunBlock', self.pico_handle, ...
        pre_trigger_samples, ... % # Pre-trigger samples
        self.N_samples - pre_trigger_samples, ... % # Post-trigger samples
        self.timebase, ... % The timebase calculated above.
        0, ... % oversampling
        timeIndisposedMS_ptr, ... % returns the amount of time the pico scope will be busy for, we don't care because we will poll it
        0, ... % segmentIndex in the memory where to store samples
        [], ... % a function pointer for a callback function, cannot use in matlab
        []); % pointer to a void structure type for the callback function

      if r ~= 0; self.check_error(r); return; end

      timeIndisposed = double(timeIndisposedMS_ptr.value) / 1000;
    end

    function WaitReady(self)
        while ~self.IsReady()
            pause(0.1);
        end
    end
    function isready = IsReady(self)
      % make sure you pause before calling this repeatidly
      isready_ptr = libpointer ('int16Ptr',0);
      calllib (self.libname, 'ps6000IsReady', self.pico_handle, isready_ptr);
      isready = isready_ptr.value;
    end

    function Stop(self)
      r = calllib(self.libname, 'ps6000Stop', self.pico_handle);
      if r ~= 0; self.check_error(r); return; end
    end


    function [data, overflow, N_acquired] = getMyData(self, channel, segment_index)

      max_v_array = [ 10E-3, 20E-3, 50E-3, 100E-3, 200E-3, 500E-3, 1, 2, 5, 10, 20];

      channel_default = 0;
      segment_index_default = 0;
      if nargin < 2; channel = channel_default; end
      if nargin < 3; segment_index = segment_index_default; end

      data_buffer_ptr = libpointer('int16Ptr', zeros(self.N_samples, 1));
      r = calllib(self.libname, 'ps6000SetDataBuffer', self.pico_handle, ...
           channel, ... % 0 = Channel A ....
           data_buffer_ptr, ... % data buffer
           self.N_samples, ... % size of buffer
           0); % No downsampling
      if r ~= 0; self.check_error(r); return; end

      overflow_ptr = libpointer('int16Ptr',0);

      N_acquired_ptr = libpointer('uint32Ptr', self.N_samples);
      r = calllib (self.libname, 'ps6000GetValues', self.pico_handle, ...
        0, ... % Staring sample (0 indexed
        N_acquired_ptr, ...% Entry = number of samples requested, Exit actual number of samples taken
        1, ... % Downsampling ratio (1 for no downsampling
        0, ... % Downsampling mode 0 = None, 1 = aggregate, 2 = average, 4 = decimate
        segment_index, ... % Segment index (starting with 0)
        overflow_ptr);
      if r ~= 0; self.check_error(r); return; end

      % Set the buffer to null, so that the picoscope doesn't attempt to
      % write to it again
      r = calllib(self.libname, 'ps6000SetDataBuffer', self.pico_handle, ...
           channel, ... % 0 = Channel A ....
           libpointer(), ... % data buffer
           0, ... % size of buffer
           0); % No downsampling
      if r ~= 0; self.check_error(r); return; end

      overflow = double(overflow_ptr.value);
      N_acquired = double(N_acquired_ptr.value);
      data = double(data_buffer_ptr.value);

      data = max_v_array(self.channel_range(channel+1) + 1) .* data ./ 32512.0;
    end

    function SetSigGenArbitrary(self, offset, peakToPeak, arbitraryWaveform, waveformDuration)
      MAX_SIG_GEN_BUFFER_SIZE = 16384;
      MIN_SIG_GEN_BUFFER_SIZE = 10;

      offset_default = 0;
      peakToPeak_default = 1;
      arbitraryWaveform_default = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] / 10;

      if nargin < 2; offset = offset_default; end
      if nargin < 3; peakToPeak = peakToPeak_default; end
      if nargin < 4; arbitraryWaveform = arbitraryWaveform_default; end

      arbitraryWaveform_length = length(arbitraryWaveform);
      if arbitraryWaveform_length < MIN_SIG_GEN_BUFFER_SIZE
        arbitraryWaveform(arbitraryWaveform_length+1:MIN_SIG_GEN_BUFFER_SIZE) = arbitraryWaveform(end);
      elseif arbitraryWaveform_length > MAX_SIG_GEN_BUFFER_SIZE
        arbitraryWaveform(MAX_SIG_GEN_BUFFER_SIZE+1:end) = [];
      end
      arbitraryWaveform_length = length(arbitraryWaveform);
      arbitraryWaveform_ptr = libpointer('int16Ptr', floor(arbitraryWaveform * (2^15-1)));


      % The top 14 bits of the 32 bit internal counter keep track of the position
      % of the 14 bits = 16k buffer
      % It adds "startDeltaPhase" every 5ns to the phase counter
      % Therefore, if we wish to have a sweep that lasts
      startDeltaPhase = 2^(32-14+1);
      r = calllib (self.libname, 'ps6000SetSigGenArbitrary', self.pico_handle, ...
        round(offset * 1E6), ... % offset voltage in uV
        round(peakToPeak * 1E6), ... % peak to peak voltage in uV
        startDeltaPhase, 0, 0, ...% startDeltaPhase, stopDeltaPhase, deltaPhaseIncrement
        10, ... % dwellCount (minimum value of 10), the time, in 5 ns increments, that we wait between additions to delta phase
        arbitraryWaveform_ptr, ...
        arbitraryWaveform_length, ...
        0, ... % 0 = sweep start phase up to  stop delta phase, 1= down, 2= repeatidly up-down, 3=repeatidly down-up
        0, ... % operation
        0, ... % selects how the waveform is indexed, see page 72, 3.9.43.1
        1, ... % shots
        0, ... % sweeps
        0, ... % Trigger type, 0 = rising, 1 = falling, 2 = gate high, 3 = gate low
        3, ... % Trigger source, 0 = none, 1 = scope trig, 2 = aux, 3 = soft trig
        0  ... % extInThreshold, not used
        );
      if r ~= 0; self.check_error(r); return; end
    end

    function SigGenSoftwareControl(self, state)
      if state == 0
        state_to_send = 3; % 3 = SIGGEN_GATE_LOW
      else
        state_to_send = 2; % 2 = SIGGEN_GATE_HIGH
      end

      r = calllib(self.libname, 'ps6000SigGenSoftwareControl', self.pico_handle, ...
        state_to_send  ... % can only send 2 = SIGGEN_GATE_HIGH or 3 = SIGGEN_GATE_LOW
        );

      if r ~= 0; self.check_error(r); return; end
    end


    function s = errorToString(self, err_num)
        error_codes = { 'PICO_OK'; ...
          'ICO_MAX_UNITS_OPENED'; ...
          'PICO_MEMORY_FAIL'; ...
          'PICO_NOT_FOUND'; ...
          'PICO_FW_FAIL'; ...
          'PICO_OPEN_OPERATION_IN_PROGRESS'; ...
          'PICO_OPERATION_FAILED'; ...
          'PICO_NOT_RESPONDING'; ...
          'PICO_CONFIG_FAIL'; ...
          'PICO_KERNEL_DRIVER_TOO_OLD'; ...
          'PICO_EEPROM_CORRUPT'; ...
          'PICO_OS_NOT_SUPPORTED'; ...
          'PICO_INVALID_HANDLE'; ...
          'PICO_INVALID_PARAMETER'; ...
          'PICO_INVALID_TIMEBASE'; ...
          'PICO_INVALID_VOLTAGE_RANGE'; ...
          'PICO_INVALID_CHANNEL'; ...
          'PICO_INVALID_TRIGGER_CHANNEL'; ...
          'PICO_INVALID_CONDITION_CHANNEL'; ...
          'PICO_NO_SIGNAL_GENERATOR'; ...
          'PICO_STREAMING_FAILED'; ...
          'PICO_BLOCK_MODE_FAILED'; ...
          'PICO_NULL_PARAMETER'; ...
          'PICO_ETS_MODE_SET'; ...
          'PICO_DATA_NOT_AVAILABLE'; ...
          'PICO_STRING_BUFFER_TO_SMALL'; ...
          'PICO_ETS_NOT_SUPPORTED'; ...
          'PICO_AUTO_TRIGGER_TIME_TO_SHORT'; ...
          'PICO_BUFFER_STALL'; ...
          'PICO_TOO_MANY_SAMPLES'; ...
          'PICO_TOO_MANY_SEGMENTS'; ...
          'PICO_PULSE_WIDTH_QUALIFIER'; ...
          'PICO_DELAY'; ...
          'PICO_SOURCE_DETAILS'; ...
          'PICO_CONDITIONS'; ...
          'PICO_USER_CALLBACK'; ...
          'PICO_DEVICE_SAMPLING'; ...
          'PICO_NO_SAMPLES_AVAILABLE'; ...
          'PICO_SEGMENT_OUT_OF_RANGE'; ...
          'PICO_BUSY'; ...
          'PICO_STARTINDEX_INVALID'; ...
          'PICO_INVALID_INFO'; ...
          'PICO_INFO_UNAVAILABLE'; ...
          'PICO_INVALID_SAMPLE_INTERVAL'; ...
          'PICO_TRIGGER_ERROR'; ...
          'PICO_MEMORY'; ...
          'PICO_SIG_GEN_PARAM'; ...
          'PICO_SHOTS_SWEEPS_WARNING'; ...
          'PICO_SIGGEN_TRIGGER_SOURCE'; ...
          'PICO_AUX_OUTPUT_CONFLICT'; ...
          'PICO_AUX_OUTPUT_ETS_CONFLICT'; ...
          'PICO_WARNING_EXT_THRESHOLD_CONFLICT'; ...
          'PICO_WARNING_AUX_OUTPUT_CONFLICT'; ...
          'PICO_SIGGEN_OUTPUT_OVER_VOLTAGE'; ...
          'PICO_DELAY_NULL'; ...
          'PICO_INVALID_BUFFER'; ...
          'PICO_SIGGEN_OFFSET_VOLTAGE'; ...
          'PICO_SIGGEN_PK_TO_PK'; ...
          'PICO_CANCELLED'; ...
          'PICO_SEGMENT_NOT_USED'; ...
          'PICO_INVALID_CALL'; ...
          'PICO_GET_VALUES_INTERRUPTED'; ...
          'DUMMY CODE'; ... % They don't have one for 0x0000003EUL
          'PICO_NOT_USED'; ...
          'PICO_INVALID_SAMPLERATIO'; ...
          'PICO_INVALID_STATE'; ...
          'PICO_NOT_ENOUGH_SEGMENTS'; ...
          'PICO_DRIVER_FUNCTION'; ...
          'PICO_RESERVED'; ...
          'PICO_INVALID_COUPLING'; ...
          'PICO_BUFFERS_NOT_SET'; ...
          'PICO_RATIO_MODE_NOT_SUPPORTED'; ...
          'PICO_RAPID_NOT_SUPPORT_AGGREGATION'; ...
          'PICO_INVALID_TRIGGER_PROPERTY'};
      s = char(error_codes(err_num+1));
    end

  end % methods

end  % classdef
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
