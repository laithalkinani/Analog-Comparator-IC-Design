
%hand calcs for the comparator

clear; clc;
kn       = 67.2e-6;
lambda_n = 0.1;
lambda_p = 0.2;
Vov      = 0.1;        % fixed overdrive
L        = 5e-6;


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


fprintf('\nW (um) | W/L  | Id (uA)  | gm (uA/V)\n')
fprintf('------------------------------------------\n')
for i = 1:10   % print first 10 cause that's all we need rly
    fprintf('%6.0f um | %4.0f | %8.4f uA | %8.4f uA/V\n', ...
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




%% part 2 - finding m3 bias points / sizing

kp       = 19.2e-6;
Id3      = 6.048e-6;   % = Iss/2
Vtp      = 0.8;
VDD      = 3;

Vov3_sweep = linspace(0.1, 1.5, 10000);   % sweep Vov3

% W/L3 from Id = kp*(W/L)*Vov^2
WL3 = Id3 ./ (kp * Vov3_sweep.^2);

% Corresponding Vsg3 = Vov3 + |Vtp|
Vsg3 = Vov3_sweep + Vtp;

% Corresponding Vout_DC = VDD - Vsg3 (diode connected => Vsd3 = Vsg3)
Vout_DC = VDD - Vsg3;

% --- Find exact Vov3 and W/L3 where Vout_DC = 1.5V ---
% Vout = VDD - Vov3 - Vtp = 1.5  =>  Vov3 = VDD - Vtp - 1.5
Vov3_target = VDD - Vtp - 1.5;                    % = 0.7 V
WL3_target  = Id3 / (kp * Vov3_target^2);

fprintf('\n--- M3 Operating Point for Vout_DC = 1.5V ---\n')
fprintf('Vov3       = %.4f V\n',   Vov3_target)
fprintf('Vsg3       = %.4f V\n',   Vov3_target + Vtp)
fprintf('W/L_3      = %.4f\n',     WL3_target)
fprintf('Vout_DC    = %.4f V\n',   VDD - (Vov3_target + Vtp))

% Plot
figure;
subplot(2,1,1)
plot(Vov3_sweep, WL3, 'b-', 'LineWidth', 1.5)
yline(1,          'r--', 'W/L = 1 (min)',        'LineWidth', 1.2)
yline(WL3_target, 'g--', sprintf('W/L = %.3f @ V_{out}=1.5V', WL3_target), 'LineWidth', 1.2)
xline(Vov3_target,'k--', sprintf('V_{ov3} = %.2f V', Vov3_target),          'LineWidth', 1.2)
scatter(Vov3_target, WL3_target, 80, 'g', 'filled')
xlabel('V_{ov3} (V)'); ylabel('W/L_3')
title('W/L_3 vs V_{ov3}')
grid on; box on;

subplot(2,1,2)
plot(Vov3_sweep, Vout_DC, 'r-', 'LineWidth', 1.5)
yline(VDD/2, 'b--', 'VDD/2 = 1.5V', 'LineWidth', 1.2)
xline(Vov3_target, 'k--', sprintf('V_{ov3} = %.2f V', Vov3_target), 'LineWidth', 1.2)
scatter(Vov3_target, 1.5, 80, 'g', 'filled', 'DisplayName', 'Target: V_{out}=1.5V')
xlabel('V_{ov3} (V)'); ylabel('V_{out DC} (V)')
title('V_{out DC} vs V_{ov3}')
legend('V_{out DC}', 'VDD/2', '', 'Target', 'Location', 'southwest')
grid on; box on;

sgtitle('M3/M4 Sizing Sweep — Target V_{out,DC} = 1.5V', 'FontSize', 13)

%% Part 3b - CS Stage Bias Point Options
fprintf('\n===== Part 3b: CS_OUT_bias Sensitivity =====\n')

VDD  = 3;
VtHn = 0.7;
VtHp = 0.8;
Vx   = 0.8225;
Vov3_target = 0.7;
Vtp         = 0.8;
lambda_n = 0.1;
lambda_p = 0.2;

diff_out    = VDD - (Vov3_target + Vtp);
VSG7        = VDD - diff_out;
Vov7        = VSG7 - VtHp;
CS_OUT_high = VDD - Vov7;
CS_OUT_low  = Vx - VtHn;

fprintf('CS_OUT_high = %.4f V\n', CS_OUT_high)
fprintf('CS_OUT_low  = %.4f V\n', CS_OUT_low)

% -------------------------------------------------------
% Option 1: CS_OUT_bias = VDD/2
% -------------------------------------------------------
CS_OUT_opt1 = VDD / 2;
Vov8_opt1   = CS_OUT_opt1 - VtHn;
Av_opt1     = 2 / (Vov8_opt1 * (lambda_n + lambda_p));
headroom_top_opt1 = CS_OUT_high - CS_OUT_opt1;
headroom_bot_opt1 = CS_OUT_opt1 - CS_OUT_low;

fprintf('\n--- Option 1: CS_OUT_bias = VDD/2 = %.4f V ---\n', CS_OUT_opt1)
fprintf('Vov8         = %.4f V\n', Vov8_opt1)
fprintf('Av_CS        = %.4f\n',   Av_opt1)
fprintf('Headroom top = %.4f V\n', headroom_top_opt1)
fprintf('Headroom bot = %.4f V\n', headroom_bot_opt1)

% -------------------------------------------------------
% Option 2: CS_OUT_bias = CS_OUT_low + 0.3V margin
% -------------------------------------------------------
CS_OUT_opt2 = CS_OUT_low + 0.3;
Vov8_opt2   = CS_OUT_opt2 - VtHn;
Av_opt2     = 2 / (Vov8_opt2 * (lambda_n + lambda_p));
headroom_top_opt2 = CS_OUT_high - CS_OUT_opt2;
headroom_bot_opt2 = CS_OUT_opt2 - CS_OUT_low;

fprintf('\n--- Option 2: CS_OUT_bias = CS_OUT_low + 0.3V = %.4f V ---\n', CS_OUT_opt2)
fprintf('Vov8         = %.4f V\n', Vov8_opt2)
fprintf('Av_CS        = %.4f\n',   Av_opt2)
fprintf('Headroom top = %.4f V\n', headroom_top_opt2)
fprintf('Headroom bot = %.4f V\n', headroom_bot_opt2)

% -------------------------------------------------------
% Option 3: Sweep CS_OUT_bias, plot headroom and Av
% -------------------------------------------------------
CS_OUT_sweep      = linspace(CS_OUT_low + 0.05, CS_OUT_high - 0.05, 1000);
Vov8_sweep        = CS_OUT_sweep - VtHn;
Av_sweep          = 2 ./ (Vov8_sweep * (lambda_n + lambda_p));
headroom_top_sweep = CS_OUT_high - CS_OUT_sweep;
headroom_bot_sweep = CS_OUT_sweep - CS_OUT_low;
% symmetric swing = min of top and bottom headroom
sym_swing_sweep   = min(headroom_top_sweep, headroom_bot_sweep);

% find max symmetric swing point
[~, idx_best] = max(sym_swing_sweep);
CS_OUT_best   = CS_OUT_sweep(idx_best);
Vov8_best     = Vov8_sweep(idx_best);
Av_best       = Av_sweep(idx_best);

fprintf('\n--- Option 3: Max Symmetric Swing Point ---\n')
fprintf('CS_OUT_bias  = %.4f V\n', CS_OUT_best)
fprintf('Vov8         = %.4f V\n', Vov8_best)
fprintf('Av_CS        = %.4f\n',   Av_best)
fprintf('Headroom top = %.4f V\n', headroom_top_sweep(idx_best))
fprintf('Headroom bot = %.4f V\n', headroom_bot_sweep(idx_best))

% -------------------------------------------------------
% Sizing table for each option
% -------------------------------------------------------
options       = {CS_OUT_opt1, CS_OUT_opt2, CS_OUT_best};
option_labels = {'VDD/2', 'CS\_low+0.3V', 'Max Sym Swing'};

fprintf('\n--- W/L Sizing for Each Option (first valid W/L_7) ---\n')
fprintf('Option         | CS_OUT | Vov8  | W/L_7 | Id (uA) | W/L_8 | Av\n')
fprintf('------------------------------------------------------------------------\n')
for o = 1:3
    CS_b  = options{o};
    Vov8  = CS_b - VtHn;
    for WL7 = 1:50
        Id7  = kp * WL7 * Vov7^2;
        WL8  = Id7 / (kn * Vov8^2);
        W8nm = WL8 * L * 1e9;
        Av   = 2 / (Vov8 * (lambda_n + lambda_p));
        if WL8 >= 1 && mod(round(W8nm), 180) == 0
            fprintf('%-15s| %.4f | %.4f | %5d | %7.4f | %5.2f | %.2f\n', ...
                option_labels{o}, CS_b, Vov8, WL7, Id7*1e6, WL8, Av)
            break
        end
    end
end

% -------------------------------------------------------
% Plots
% -------------------------------------------------------
figure;
subplot(3,1,1)
plot(CS_OUT_sweep, Av_sweep, 'b-', 'LineWidth', 1.5); hold on
xline(CS_OUT_opt1, 'r--', 'Opt1: VDD/2',        'LineWidth', 1.2)
xline(CS_OUT_opt2, 'g--', 'Opt2: low+0.3V',     'LineWidth', 1.2)
xline(CS_OUT_best, 'm--', 'Opt3: max sym swing', 'LineWidth', 1.2)
xlabel('CS\_OUT bias (V)'); ylabel('|A_{v,CS}|')
title('CS Stage Gain vs Output Bias Point')
grid on; box on;

subplot(3,1,2)
plot(CS_OUT_sweep, headroom_top_sweep, 'b-',  'LineWidth', 1.5); hold on
plot(CS_OUT_sweep, headroom_bot_sweep, 'r-',  'LineWidth', 1.5)
plot(CS_OUT_sweep, sym_swing_sweep,    'k--', 'LineWidth', 1.5)
xline(CS_OUT_opt1, 'r--', 'LineWidth', 1)
xline(CS_OUT_opt2, 'g--', 'LineWidth', 1)
xline(CS_OUT_best, 'm--', 'LineWidth', 1)
legend('Headroom top (M7)', 'Headroom bot (M8)', 'Min (sym swing)', ...
    'Location', 'northeast')
xlabel('CS\_OUT bias (V)'); ylabel('Headroom (V)')
title('Output Swing Headroom vs Bias Point')
grid on; box on;

subplot(3,1,3)
plot(CS_OUT_sweep, Vov8_sweep, 'g-', 'LineWidth', 1.5); hold on
xline(CS_OUT_opt1, 'r--', 'LineWidth', 1)
xline(CS_OUT_opt2, 'g--', 'LineWidth', 1)
xline(CS_OUT_best, 'm--', 'LineWidth', 1)
xlabel('CS\_OUT bias (V)'); ylabel('V_{ov8} (V)')
title('V_{ov8} vs CS\_OUT Bias Point')
grid on; box on;

sgtitle('CS Stage: Bias Point Options 1, 2, 3', 'FontSize', 13)