% run_milestone3.m
clear; close all; clc;
addpath(pwd);

battery_params; % loads parameters
run('make_current_profiles.m'); % creates I_const_ts, I_pulse_ts

% choose profile
I_profile = I_pulse_ts; % or I_const_ts

% assign variable in workspace to point to signal source used in model
assignin('base','I_profile',I_profile); % top model should use From Workspace variable I_profile

% set stop time from params
set_param('Milestone3_Battery','StopTime',num2str(sim_stop_time));

% Run
simOut = sim('Milestone3_Battery');

% Retrieve outputs (assuming To Workspace names Vt_out, SOC_out, I_out)
Vt = simOut.get('Vt_out'); % timeseries or matrix based on config
SOC = simOut.get('SOC_out');
I   = simOut.get('I_out');

% Save results
save('sim_results.mat','Vt','SOC','I','battery_params','I_profile');
