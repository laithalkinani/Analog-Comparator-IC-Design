
%hand calcs for the comparator

clear; clc;
kn       = 67.2e-6;
lambda_n = 0.1;
lambda_p = 0.2;
Vov      = 0.1;        % fixed overdrive
L        = 180e-9;


Av = 2 / (Vov * (lambda_n + lambda_p));
fprintf('Av = %.4f\n', Av)


wl1 = linspace(1, 1000, 1000);

% Id = kn * (W/L) * Vov^2
Id = kn * wl1 * Vov^2;

% gm = 2*Id/Vov = sqrt(2*kn*(W/L)*Id)
gm = 2 * Id / Vov;


W_nm   = wl1 * L * 1e9;
mask   = mod(W_nm, 180) == 0;
WL_int = wl1(mask);
Id_int = Id(mask);
gm_int = gm(mask);


fprintf('\nW (nm) | W/L  | Id (uA)  | gm (uA/V)\n')
fprintf('------------------------------------------\n')
for i = 1:10   % print first 10 cause that's all we need rly
    fprintf('%6.0f nm | %4.0f | %8.4f uA | %8.4f uA/V\n', ...
        WL_int(i)*180, WL_int(i), Id_int(i)*1e6, gm_int(i)*1e6)
end


figure;
subplot(2,1,1)
plot(wl1, Id*1e6, 'b-', 'LineWidth', 1.5)
xlabel('W/L'); ylabel('I_D (\muA)')
title(sprintf('I_D vs W/L | V_{ov}=0.2V, A_v=%.1f', Av))
grid on; box on;

subplot(2,1,2)
plot(wl1, gm*1e6, 'r-', 'LineWidth', 1.5)
xlabel('W/L'); ylabel('g_m (\muA/V)')
title(sprintf('g_m vs W/L | V_{ov}=0.2V, A_v=%.1f', Av))
grid on; box on;

sgtitle('5T OTA: V_{ov}=0.2V Fixed Design', 'FontSize', 13)
