%% Common Source Stage Design Sweep
% Equation: 44.4 * Kn * (W/L) = ID * Av^2
% Kn = 67.2e-6 A/V^2
% Swing constraint: CS_OUT = 1.28075 V (midpoint target)
% VDD assumed = 3.3V (adjust if different)
 
clear; clc; close all;
 
%% ---- Parameters ----
Kn      = 67.2e-6;       % NMOS process transconductance [A/V^2]
VDD     = 3.3;           % Supply voltage [V]
VTH_N   = 0.4;           % NMOS threshold [V] (adjust to your process)
VTH_P   = 0.4;           % PMOS threshold magnitude [V]
VIN     = 0.9225;        % VIN such that VIN - VTH_N = 0.5225... wait:
%   VIN - VTH_N = 0.1225 per problem, so:
VIN_VTH = 0.1225;        % VIN - VTH_N (overdrive of input transistor)
CS_OUT_target = 1.28075; % Target output DC bias [V]
Vb_PMOS = 1.639;         % PMOS bias voltage [V]
Vb_NMOS = 0.8225;        % NMOS bias voltage [V]
 
% Swing margin: allow +/- swing_margin from target
swing_tol = 0.05;        % 50 mV tolerance on DC operating point
 
%% ---- Sweep Ranges ----
ID_vec   = linspace(10e-6, 500e-6, 200);   % Drain current [A]
WL_vec   = linspace(1, 100, 200);           % W/L ratio
Av_vec   = linspace(-5, -50, 200);          % Voltage gain (negative = inverting)
 
%% ---- Main Equation: 44.4 * Kn * (W/L) = ID * Av^2 ----
% Rearranged: Av^2 = 44.4 * Kn * (W/L) / ID
% This is a 2D surface in (WL, ID) -> Av^2
 
%% ---- Swing Constraint ----
% CS_OUT = (VDD - VGS2 - VTH2 + VIN_VTH) / 2
% VGS2 of PMOS: VGS2 = VDD - Vb_PMOS (for diode-connected or biased PMOS load)
%   Typically VGS2 = VDD - Vb_PMOS (gate is at Vb_PMOS, source at VDD)
VGS2 = VDD - Vb_PMOS;   % PMOS |VGS|
CS_OUT_swing = (VDD - VGS2 - VTH_P + VIN_VTH) / 2;
fprintf('CS_OUT from swing formula: %.5f V (target: %.5f V)\n', CS_OUT_swing, CS_OUT_target);
fprintf('VGS2 (PMOS): %.4f V\n', VGS2);
fprintf('Vb_NMOS: %.4f V\n', Vb_NMOS);
fprintf('\n');
 
%% ---- Compute gm and ro expressions ----
% gm1 = sqrt(4 * Kn * (W/L) * ID)
% ro1||ro2 = (10/3) / ID  [from ro = lambda^-1/ID with lambda giving 10/3 factor]
% Av = -gm1 * (ro1||ro2)
 
fprintf('=== Design Points satisfying 44.4*Kn*(W/L) = ID*Av^2 ===\n');
fprintf('   AND CS_OUT within %.0f mV of %.5f V\n\n', swing_tol*1000, CS_OUT_target);
fprintf('%-10s %-10s %-10s %-12s %-12s %-12s\n', ...
    'ID [uA]', 'W/L', '|Av|', 'gm [mS]', 'ro_eq [kΩ]', 'CS_OUT [V]');
fprintf('%s\n', repmat('-',1,70));
 
results = [];
 
for i = 1:length(ID_vec)
    ID = ID_vec(i);
    for j = 1:length(WL_vec)
        WL = WL_vec(j);
        
        % Compute gm
        gm = sqrt(4 * Kn * WL * ID);
        
        % Compute ro_parallel = (10/3)/ID
        ro_par = (10/3) / ID;
        
        % Compute Av
        Av_calc = -gm * ro_par;
        
        % Check main equation: 44.4*Kn*(W/L) == ID*Av^2
        lhs = 44.4 * Kn * WL;
        rhs = ID * Av_calc^2;
        eq_err = abs(lhs - rhs) / max(abs(lhs), 1e-20);
        
        % CS_OUT swing check
        % CS_OUT should be at midpoint; here we use the given formula
        % Using DC: Vout = VDD - |VDS_PMOS| 
        % For active region: CS_OUT ≈ CS_OUT_target when properly biased
        % We verify by checking the formula directly
        cs_out_check = (VDD - VGS2 - VTH_P + VIN_VTH) / 2;
        swing_ok = abs(cs_out_check - CS_OUT_target) < swing_tol;
        
        % Saturation check for NMOS: VDS > VGS - VTH
        VGS1  = Vb_NMOS;
        VOV1  = VGS1 - VTH_N;
        VDS1  = cs_out_check;  % output node = drain of M1
        nmos_sat = VDS1 >= VOV1;
        
        % Saturation check for PMOS: |VDS| > |VGS| - VTH
        VDS2_mag = VDD - cs_out_check;
        pmos_sat = VDS2_mag >= (VGS2 - VTH_P);
        
        % Current from NMOS: ID = (Kn/2)*(W/L)*(VGS1-VTH_N)^2
        ID_nmos = (Kn/2) * WL * VOV1^2;
        id_match = abs(ID_nmos - ID) / max(ID, 1e-12) < 0.05; % within 5%
        
        if swing_ok && nmos_sat && pmos_sat && id_match
            results = [results; ID*1e6, WL, abs(Av_calc), gm*1e3, ro_par/1e3, cs_out_check];
        end
    end
end
 
%% ---- Print Results ----
if isempty(results)
    fprintf('No exact intersection points found. Relaxing ID-match constraint...\n\n');
    % Relax: just show swing-valid + saturation points across Av range
    results2 = [];
    for i = 1:length(ID_vec)
        ID = ID_vec(i);
        for j = 1:length(WL_vec)
            WL = WL_vec(j);
            gm = sqrt(4 * Kn * WL * ID);
            ro_par = (10/3) / ID;
            Av_calc = -gm * ro_par;
            cs_out_check = (VDD - VGS2 - VTH_P + VIN_VTH) / 2;
            swing_ok = abs(cs_out_check - CS_OUT_target) < swing_tol;
            VGS1 = Vb_NMOS; VOV1 = VGS1 - VTH_N;
            nmos_sat = cs_out_check >= VOV1;
            VDS2_mag = VDD - cs_out_check;
            pmos_sat = VDS2_mag >= (VGS2 - VTH_P);
            if swing_ok && nmos_sat && pmos_sat
                results2 = [results2; ID*1e6, WL, abs(Av_calc), gm*1e3, ro_par/1e3, cs_out_check];
            end
        end
    end
    if ~isempty(results2)
        % Subsample for display
        step = max(1, floor(size(results2,1)/20));
        disp_results = results2(1:step:end, :);
        for r = 1:size(disp_results,1)
            fprintf('%-10.2f %-10.1f %-10.2f %-12.3f %-12.3f %-12.5f\n', ...
                disp_results(r,1), disp_results(r,2), disp_results(r,3), ...
                disp_results(r,4), disp_results(r,5), disp_results(r,6));
        end
    end
else
    step = max(1, floor(size(results,1)/30));
    disp_results = results(1:step:end, :);
    for r = 1:size(disp_results,1)
        fprintf('%-10.2f %-10.1f %-10.2f %-12.3f %-12.3f %-12.5f\n', ...
            disp_results(r,1), disp_results(r,2), disp_results(r,3), ...
            disp_results(r,4), disp_results(r,5), disp_results(r,6));
    end
end
 
%% ---- Design Equation Surface Plot ----
[WL_grid, ID_grid] = meshgrid(WL_vec, ID_vec);
gm_grid  = sqrt(4 * Kn * WL_grid .* ID_grid);
ro_grid  = (10/3) ./ ID_grid;
Av_grid  = gm_grid .* ro_grid;  % magnitude
 
figure('Name','CS Stage Design Space','Position',[100 100 1400 500]);
 
subplot(1,3,1);
contourf(WL_grid, ID_grid*1e6, Av_grid, 20, 'LineColor','none');
colorbar; colormap(parula);
xlabel('W/L'); ylabel('I_D [\muA]');
title('|Av| contours (W/L vs I_D)');
hold on;
% Overlay constraint: |Av|^2 * ID = 44.4*Kn*WL  ->  Av = sqrt(44.4*Kn*WL/ID)
Av_constraint = sqrt(44.4 * Kn * WL_grid ./ ID_grid);
contour(WL_grid, ID_grid*1e6, Av_constraint, [5 10 15 20 30 40 50], 'r--', 'LineWidth', 1.5);
legend('|Av| from gm*ro','Design eq. contours','Location','best');
 
subplot(1,3,2);
% Fix W/L, sweep ID to find Av
WL_fixed_vals = [5, 10, 20, 40, 80];
colors = lines(length(WL_fixed_vals));
hold on;
for k = 1:length(WL_fixed_vals)
    WL_f = WL_fixed_vals(k);
    gm_line = sqrt(4 * Kn * WL_f * ID_vec);
    ro_line = (10/3) ./ ID_vec;
    Av_line = gm_line .* ro_line;
    plot(ID_vec*1e6, Av_line, 'Color', colors(k,:), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('W/L=%d', WL_f));
end
xlabel('I_D [\muA]'); ylabel('|Av|');
title('|Av| vs I_D for fixed W/L');
legend('Location','best'); grid on;
% Mark swing-valid zone (CS_OUT is fixed by bias, so just show saturation limit)
VOV1 = (Vb_NMOS - VTH_N);
yline(0, 'k--');
 
subplot(1,3,3);
% Av vs W/L for fixed ID
ID_fixed_vals = [20, 50, 100, 200, 400] * 1e-6;
colors2 = lines(length(ID_fixed_vals));
hold on;
for k = 1:length(ID_fixed_vals)
    ID_f = ID_fixed_vals(k);
    gm_line = sqrt(4 * Kn * WL_vec * ID_f);
    ro_f    = (10/3) / ID_f;
    Av_line = gm_line * ro_f;
    plot(WL_vec, Av_line, 'Color', colors2(k,:), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('I_D=%d\\muA', ID_f*1e6));
end
xlabel('W/L'); ylabel('|Av|');
title('|Av| vs W/L for fixed I_D');
legend('Location','best'); grid on;
 
sgtitle('Common Source Stage: 3-Variable Sweep');
 
%% ---- Summary ----
fprintf('\n=== Swing Verification ===\n');
fprintf('CS_OUT formula result : %.5f V\n', CS_OUT_swing);
fprintf('CS_OUT target         : %.5f V\n', CS_OUT_target);
fprintf('Difference            : %.2f mV\n', (CS_OUT_swing - CS_OUT_target)*1000);
fprintf('\nSaturation headroom check:\n');
fprintf('  NMOS: VDS_min needed = VOV1 = %.4f V, VDS actual = CS_OUT = %.4f V -> %s\n', ...
    VIN_VTH, CS_OUT_target, ...
    ternary(CS_OUT_target >= VIN_VTH, 'SAT OK', 'TRIODE WARNING'));
fprintf('  PMOS: |VDS_min| needed = |VOV2| = %.4f V, |VDS| = VDD-CS_OUT = %.4f V -> %s\n', ...
    VGS2-VTH_P, VDD-CS_OUT_target, ...
    ternary((VDD-CS_OUT_target) >= (VGS2-VTH_P), 'SAT OK', 'TRIODE WARNING'));
 
fprintf('\nDesign equation coefficient check:\n');
fprintf('  44.4 * Kn = %.4e\n', 44.4 * Kn);
fprintf('  For a given ID and W/L, |Av| = sqrt(44.4*Kn*(W/L)/ID)\n');
fprintf('  Example: ID=100uA, W/L=10 -> |Av| = %.2f\n', ...
    sqrt(44.4 * Kn * 10 / 100e-6));
 
%% Helper
function s = ternary(cond, a, b)
    if cond; s = a; else; s = b; end
end