% ================= REAL-TIME MPPT WITH P&O TABLE METHOD ================== %
clear; clc;

% === MPPT Parameters ===
TaC = 25;                 % Temperature (°C)
C   = 0.5;                % P&O step size
Va  = 31;                 % Initial PV voltage
Suns = 0.2;               % Initial irradiance

Ia = PV_model(Va, Suns, TaC);
Pa = Ia * Va;
Vref_new = Va + C;

% ================== ARRAYS FOR ANALYSIS ==================== %
Va_array = [];
Pa_array = [];
Suns_array = [];

dV_array = [];
dP_array = [];
ratio_array = [];
case_array = [];

% === Irradiance profile ===
Suns_curve = [0 0.1; 1 0.3; 2 0.7; 3 1.0; 4 0.9; 5 0.6; 6 1.2; 7 1.4];
xi = 1:200;
yi = interp1(Suns_curve(:,1), Suns_curve(:,2), xi, 'pchip');

% === Pre-computed P-V curve range ===
Vline = 0:0.5:40;

% ==================== REAL-TIME FIGURE ======================= %
figure('Name','Real-Time MPPT Animation');
hold on; grid on;

% Initial P-V curve
Iline = PV_model(Vline, yi(1), TaC);
Pline = Vline .* Iline;
pv_curve = plot(Vline, Pline, 'b-', 'LineWidth', 2);

xlabel('Voltage (V)','FontSize',14)
ylabel('Power (W)','FontSize',14)
title('Real-Time MPPT Tracking (P&O Table Method)','FontSize',15)

% MPPT point marker
mppt_point = plot(Va, Pa, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
legend('P-V Curve','MPPT Point','Location','best');

% ===================== MPPT LOOP ANIMATION =================== %
for i = 1:length(yi)

    Suns = yi(i);

    % Update P-V curve
    Iline = PV_model(Vline, Suns, TaC);
    Pline = Vline .* Iline;
    set(pv_curve, 'YData', Pline);

    % ======================================================
    %            TABLE-BASED P&O MPPT ALGORITHM
    % ======================================================
    Va_new = Vref_new;
    Ia_new = PV_model(Va_new, Suns, TaC);
    Pa_new = Va_new * Ia_new;

    % Compute variations
    dV = Va_new - Va;
    dP = Pa_new - Pa;

    dV_array = [dV_array dV];
    dP_array = [dP_array dP];
    ratio_array = [ratio_array (dP / dV) * (dV ~= 0)];

    % === TABLE LOGIC ===
    if dV > 0 && dP > 0
        case_id = 1;  % GOOD – INCREASE V
        Vref_new = Va_new + C;

    elseif dV < 0 && dP < 0
        case_id = 2;  % BAD – INCREASE V
        Vref_new = Va_new + C;

    elseif dV < 0 && dP > 0
        case_id = 3;  % GOOD – DECREASE V
        Vref_new = Va_new - C;

    elseif dV > 0 && dP < 0
        case_id = 4;  % BAD – DECREASE V
        Vref_new = Va_new - C;

    else
        case_id = 0;  % Undefined
    end

    case_array = [case_array case_id];

    % Update state
    Va = Va_new;
    Pa = Pa_new;

    Va_array = [Va_array Va];
    Pa_array = [Pa_array Pa];
    Suns_array = [Suns_array Suns];

    % Update MPPT marker
    set(mppt_point, 'XData', Va, 'YData', Pa);
    drawnow;
    pause(0.05);
end

% ===================== FIGURE 2 : V, P, Irradiance ======================= %
figure('Name','MPPT Performance');

subplot(3,1,1)
plot(Suns_array,'LineWidth',1.4,'Color',[0.9 0.6 0]), grid on
title('Solar Irradiance Profile')
ylabel('Irradiance (Suns)')

subplot(3,1,2)
plot(Va_array,'LineWidth',1.4), grid on
title('PV Voltage Tracking')
ylabel('Voltage (V)')

subplot(3,1,3)
plot(Pa_array,'LineWidth',1.4), grid on
title('PV Power Tracking')
ylabel('Power (W)')
xlabel('Iteration')

% ===================== FIGURE 3 : P(V) Trajectory ======================= %
figure('Name','P(V) Trajectory');
plot(Va_array, Pa_array, 'LineWidth', 2, 'Color', [0.1 0.6 0.8]);
grid on;
xlabel('Voltage (V)');
ylabel('Power (W)');
title('P(V) Trajectory From P&O Table Method');

hold on;
[Pmax, idx] = max(Pa_array);
plot(Va_array(idx), Pmax, 'ro', 'MarkerSize',10,'MarkerFaceColor','r');
text(Va_array(idx), Pmax, sprintf(' Peak %.2fW @ %.2fV ', Pmax, Va_array(idx)));

% ================== FIGURE 4 : ?V, ?P, ?P/?V, Case ====================== %
figure('Name','P&O Decision Variables');

subplot(4,1,1)
plot(dV_array,'LineWidth',1.4), grid on
ylabel('\DeltaV')
title('Voltage Variation')

subplot(4,1,2)
plot(dP_array,'LineWidth',1.4), grid on
ylabel('\DeltaP')
title('Power Variation')

subplot(4,1,3)
plot(ratio_array,'LineWidth',1.4), grid on
ylabel('\DeltaP/\DeltaV')
title('Slope (Decision Factor)')

subplot(4,1,4)
stairs(case_array,'LineWidth',1.4), grid on
ylabel('Case #')
xlabel('Iteration')
title('Selected Case Based on Table')

% ================== TABLE P&O (NO ERROR VERSION) ======================= %

disp('=== P&O Decision Table ===');

T = table( ...
    {'1'; '2'; '3'; '4'}, ...               % Case numbers
    {'+'; '-'; '-'; '+'}, ...               % dV sign
    {'+'; '-'; '+'; '-'}, ...               % dP sign
    {'+'; '+'; '-'; '-'}, ...               % dP/dV sign
    {'Good'; 'Bad'; 'Good'; 'Bad'}, ...     % Direction
    {'Increase V'; 'Increase V'; 'Decrease V'; 'Decrease V'}, ... % Action
    'VariableNames', {'Case','dV','dP','dP_over_dV','Direction','Action'});

disp(T);

% === Show table in figure ===
figure('Name','P&O Decision Table');
uit = uitable;
uit.Data = T{:,:};
uit.ColumnName = T.Properties.VariableNames;
uit.RowName = {};
uit.FontSize = 14;
uit.Position = [20 20 700 180];
