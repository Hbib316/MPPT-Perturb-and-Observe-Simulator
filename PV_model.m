function I = PV_model(V, Suns, Tcell)
% =============================================================
% PV_model(V, Suns, Tcell)
% Returns the PV output current for a given voltage V,
% irradiance (Suns) and cell temperature (°C).
% 
% Model used : Single-diode equivalent PV model.
% =============================================================

%% === Panel Parameters (Example — change for your solar panel) ===
Isc_ref = 8.21;      % Short circuit current at STC (A)
Voc_ref = 32.9;      % Open circuit voltage at STC (V)
Imp_ref = 7.61;      % Maximum power current (A)
Vmp_ref = 26.3;      % Maximum power voltage (V)
Ns = 60;             % Number of cells in series
Tref = 25;           % Reference temperature (°C)
Ki = 0.0032;         % Temp coefficient of Isc (A/°C)
Kv = -0.123;         % Temp coefficient of Voc (V/°C)

%% === Constants ===
k = 1.3806e-23;      % Boltzmann constant
q = 1.6022e-19;      % electron charge
A = 1.3;             % diode ideality factor

T = Tcell + 273.15;  % Convert to Kelvin

%% === Temperature & Irradiance Scaling ===
Isc = (Isc_ref + Ki*(Tcell - Tref)) * Suns;     % New Isc
Voc = Voc_ref + Kv*(Tcell - Tref);              % New Voc

%% === Diode reverse saturation current ===
I0 = Isc_ref / (exp((q*Voc_ref)/(A*Ns*k*(Tref+273.15))) - 1);

%% === Photocurrent ===
Iph = Isc;

%% === Output Current Calculation ===
I = zeros(size(V)); % supports vector input

for j = 1:length(V)
    fun = @(I) I - Iph + I0*(exp((q*(V(j) + I*0.001))/(A*Ns*k*T)) - 1); % Rs = 0.001 ohm
    I(j) = fzero(fun, Iph); % solve non-linear relation
end

end
