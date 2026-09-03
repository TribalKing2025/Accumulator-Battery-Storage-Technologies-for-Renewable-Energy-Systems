%% ============================================================
%  Milestone3_Battery_Clean.m
%  Fully working clean script to build Milestone3_Battery.slx
%  Matching your actual block names (out.Vt_out, out.SOC_out, out.I_out)
%% ============================================================

%% ----------------- User parameters -----------------
sample_time = 1;       % model step size
Q_nom      = 5;        % Ah
R0         = 0.05;     % ohm
R1         = 0.01;     % ohm
C1         = 2000;     % farad
SOC_init   = 0.9;
SOC_min    = 0;
SOC_max    = 1;

SOC_vec = [0 0.2 0.5 0.8 1];
OCV_vec = [3.00 3.40 3.60 3.80 4.20];

t = (0:sample_time:300)';
I_vals = 0.5*ones(size(t));
I_vals(t>=60 & t<120) = 5.0;
I_profile = timeseries(I_vals,t);

assignin('base','I_profile',I_profile);
assignin('base','SOC_vec',SOC_vec);
assignin('base','OCV_vec',OCV_vec);

%% ----------------- Model setup -----------------
mdl = 'Milestone3_Battery';
subsysName = 'Battery_Thevenin';
subsys = [mdl '/' subsysName];

if bdIsLoaded(mdl)
    close_system(mdl,0);
end
new_system(mdl);
open_system(mdl);

set_param(mdl,'StopTime','inf');

%% ----------------- Top-level blocks -----------------
add_block('simulink/Sources/From Workspace',[mdl '/I_profile'], ...
    'Position',[30 40 170 80], ...
    'VariableName','I_profile');

add_block('simulink/Ports & Subsystems/Subsystem',[mdl '/' subsysName], ...
    'Position',[260 30 420 200]);

add_block('simulink/Sinks/To Workspace',[mdl '/Vt_to_ws'], ...
    'Position',[520 30 620 70], ...
    'VariableName','Vt_out', ...
    'SaveFormat','StructureWithTime');

add_block('simulink/Sinks/To Workspace',[mdl '/SOC_to_ws'], ...
    'Position',[520 110 620 150], ...
    'VariableName','SOC_out', ...
    'SaveFormat','StructureWithTime');

add_block('simulink/Sinks/To Workspace',[mdl '/I_to_ws'], ...
    'Position',[520 190 620 230], ...
    'VariableName','I_out', ...
    'SaveFormat','StructureWithTime');

%% ----------------- Top-level connections (correct names!) -----------------
add_line(mdl,'I_profile/1',[subsysName '/1'],'autorouting','on');
add_line(mdl,[subsysName '/out.Vt_out'],'Vt_to_ws/1','autorouting','on');
add_line(mdl,[subsysName '/out.SOC_out'],'SOC_to_ws/1','autorouting','on');
add_line(mdl,[subsysName '/out.I_out'],'I_to_ws/1','autorouting','on');

%% ----------------- Build Battery_Thevenin subsystem -----------------
open_system(subsys);

% Clear previous content
blkList = find_system(subsys,'SearchDepth',1,'Type','Block');
for k = 1:numel(blkList)
    try delete_block(blkList{k}); catch, end
end

% Inport
add_block('simulink/Ports & Subsystems/In1',[subsys '/I'], ...
    'Position',[30 140 60 160]);

% Outports (MUST MATCH screenshot names)
add_block('simulink/Ports & Subsystems/Out1',[subsys '/out.Vt_out'], ...
    'Position',[660 40 690 60]);

add_block('simulink/Ports & Subsystems/Out1',[subsys '/out.SOC_out'], ...
    'Position',[660 120 690 140]);

add_block('simulink/Ports & Subsystems/Out1',[subsys '/out.I_out'], ...
    'Position',[660 200 690 220]);

% ----------------- SOC branch -----------------
add_block('simulink/Commonly Used Blocks/Gain',[subsys '/SOC_gain'], ...
    'Gain',sprintf('-1/(%g*3600)',Q_nom), ...
    'Position',[120 80 200 120]);

add_block('simulink/Continuous/Integrator',[subsys '/SOC_integrator'], ...
    'InitialCondition',num2str(SOC_init), ...
    'Position',[260 80 360 120]);

add_block('simulink/Discontinuities/Saturation',[subsys '/SOC_saturation'], ...
    'UpperLimit',num2str(SOC_max), ...
    'LowerLimit',num2str(SOC_min), ...
    'Position',[420 80 500 120]);

add_block('simulink/Lookup Tables/1-D Lookup Table',[subsys '/OCV_lookup'], ...
    'Breakpoints','SOC_vec', ...
    'Table','OCV_vec', ...
    'Position',[540 80 620 120]);

% ----------------- RC branch for Vp -----------------
add_block('simulink/Math Operations/Sum',[subsys '/Vp_sum'], ...
    'Inputs','++', ...
    'Position',[120 200 180 240]);

add_block('simulink/Commonly Used Blocks/Gain',[subsys '/Vp_gain1'], ...
    'Gain',sprintf('-1/(%g*%g)',R1,C1), ...
    'Position',[200 190 260 230]);

add_block('simulink/Commonly Used Blocks/Gain',[subsys '/Vp_gain2'], ...
    'Gain',sprintf('1/%g',C1), ...
    'Position',[200 230 260 270]);

add_block('simulink/Continuous/Integrator',[subsys '/Vp_integrator'], ...
    'InitialCondition','0', ...
    'Position',[320 200 420 260]);

% ----------------- R0 branch -----------------
add_block('simulink/Commonly Used Blocks/Gain',[subsys '/R0_gain'], ...
    'Gain',num2str(R0), ...
    'Position',[120 260 200 300]);

% ----------------- Terminal voltage sum -----------------
add_block('simulink/Math Operations/Sum',[subsys '/Vt_sum'], ...
    'Inputs','+--', ...
    'Position',[440 40 520 100]);

%% ----------------- Subsystem wiring -----------------
add_line(subsys,'I/1','SOC_gain/1');
add_line(subsys,'SOC_gain/1','SOC_integrator/1');
add_line(subsys,'SOC_integrator/1','SOC_saturation/1');
add_line(subsys,'SOC_saturation/1','OCV_lookup/1');
add_line(subsys,'OCV_lookup/1','Vt_sum/1');

add_line(subsys,'I/1','Vp_gain2/1');
add_line(subsys,'Vp_integrator/1','Vp_gain1/1');
add_line(subsys,'Vp_gain1/1','Vp_sum/1');
add_line(subsys,'Vp_gain2/1','Vp_sum/2');
add_line(subsys,'Vp_sum/1','Vp_integrator/1');

add_line(subsys,'Vp_integrator/1','Vt_sum/3');
add_line(subsys,'I/1','R0_gain/1');
add_line(subsys,'R0_gain/1','Vt_sum/2');

add_line(subsys,'Vt_sum/1','out.Vt_out/1');
add_line(subsys,'SOC_saturation/1','out.SOC_out/1');
add_line(subsys,'I/1','out.I_out/1');

close_system(subsys);

%% ----------------- Save model -----------------
set_param(mdl,'Solver','ode4','FixedStep',num2str(sample_time));
save_system(mdl, fullfile(pwd,[mdl '.slx']));

fprintf('Saved model: %s\n', fullfile(pwd,[mdl '.slx']));
