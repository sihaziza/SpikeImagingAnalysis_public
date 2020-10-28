%CONVERTUNITS Convert energy, frequency and wavelength units
%
% Description
%
%     Using fundamental physical constants, there is a unique way of
%     converting an energy into different units. For example, we often want
%     to know the energy, wavelength or frequency of a photon. This function converts between these representations easily, threading over
%     vectors automatically.
%
%     This function uses the INDEX OF REFRACTION OF AIR as 1.000268746.
%     To use a different index of refraction, modify the speed of light in
%     the code.
%
%     Frequency units are in cycles per second.
% 
% Example:
% 
%     convertUnits(820,'nm','eV') converts 820 nm into 1.512 eV.
% 
% Available choices of units:
% 
%     'nm' (nanometers),'m' (meters), 'eV' (electron Volts),
%     'cm-1' (inverse centimeters),
%     'Hz' (Hertz), 'KHz', 'MHz', 'GHz', 'THz', 
%     'K' (kelvin), 'J' (Joules)
% 
%     Todd Karin
%     06/29/2012

function output = convertUnits(input,inUnits,outUnits)

% Need all the sig figs we can get!

% Electron charge
e = 1.602176463e-19;
% planck's constant
h = 6.62606957e-34;
% speed of light in air for 820 nm light, 70 F, 1 atm
c = 299792458/1.000268746; 
% Boltzman constant
kB = 1.3806503e-23;

% convert input to joules
if     strcmpi(inUnits,'nm')
    energy = h*c./(input*1e-9);
elseif     strcmpi(inUnits,'m')
    energy = h*c./input;
elseif strcmpi(inUnits,'eV')
    energy = input*e;
elseif strcmpi(inUnits,'Hz')
    energy = h*input;
elseif strcmpi(inUnits,'KHz')
    energy = h*input*1e3;
elseif strcmpi(inUnits,'MHz')
    energy = h*input*1e6;
elseif strcmpi(inUnits,'GHz')
    energy = h*input*1e9;
elseif strcmpi(inUnits,'THz')
    energy = h*input*1e12;
elseif strcmpi(inUnits,'cm-1')
    energy = h*c*input*100;
elseif strcmpi(inUnits,'J')
    energy = input;
elseif strcmpi(inUnits,'K')
    energy = kB*input;
else
    error('Input units not recognized')
end

% Convert Joules to output
if strcmpi(outUnits,'GHz')
    output = energy/h/1e9;
elseif strcmpi(outUnits,'eV')
    output = energy/e;
elseif strcmpi(outUnits,'Hz')
    output = energy/h;
elseif strcmpi(outUnits,'KHz')
    output = energy/h/1e3;
elseif strcmpi(outUnits,'MHz')
    output = energy/h/1e6;
elseif strcmpi(outUnits,'THz')
    output = energy/h/1e12;
elseif strcmpi(outUnits,'m')
    output = h*c./energy;
elseif strcmpi(outUnits,'nm')
    output = h*c./energy*1e9;
elseif strcmpi(outUnits,'cm-1')
    output = (h*c./energy*100).^(-1);
elseif strcmpi(outUnits,'K')
    output = energy/kB;
elseif strcmpi(outUnits,'J')
    output = energy;
else
    error('Output units not recognized')
end