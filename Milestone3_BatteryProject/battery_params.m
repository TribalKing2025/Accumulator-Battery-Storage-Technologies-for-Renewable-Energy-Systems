% battery_params.m
% Nominal battery parameters (example values) — edit to match your cell
Q_nom = 100;            % Ah
SOC_init = 0.8;         % initial SOC (0..1)
SOC_min = 0.1;
SOC_max = 0.95;

% OCV vs SOC table (example) - must be monotonic
SOC_vec = 0:0.1:1;
OCV_vec = [3.0 3.25 3.35 3.4 3.45 3.6 3.7 3.85 3.95 4.05 4.15]; % V

% Thevenin params (example)
R0 = 0.01;   % Ohm (ohmic)
R1 = 0.02;   % Ohm (polarisation)
C1 = 2000;   % Farad (polarisation capacitance)

% Simulation settings
sim_stop_time = 3600*2;  % seconds (2 hours)
sample_time = 1;         % [s] for logging and fixed-step
