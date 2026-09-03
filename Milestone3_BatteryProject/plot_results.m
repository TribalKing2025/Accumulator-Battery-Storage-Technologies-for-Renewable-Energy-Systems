% plot_results.m
load('sim_results.mat','Vt','SOC','I','I_profile');

t = Vt.Time; % assuming timeseries
figure; plot(t/3600, I.Data); xlabel('Time [h]'); ylabel('Current [A]'); title('Current profile'); grid on; 
saveas(gcf,'fig_current_profile.png');

figure; plot(t/3600, Vt.Data); xlabel('Time [h]'); ylabel('Voltage [V]'); title('Terminal Voltage'); grid on;
saveas(gcf,'fig_terminal_voltage.png');

figure; plot(t/3600, SOC.Data); xlabel('Time [h]'); ylabel('SOC [-]'); title('State of Charge'); grid on;
saveas(gcf,'fig_SOC.png');

% Energy throughput (approx)
power = Vt.Data .* I.Data; % W (positive discharge)
energy_Wh = trapz(t, power)/3600; % Wh
fprintf('Net energy (Wh): %.2f\n', energy_Wh);
