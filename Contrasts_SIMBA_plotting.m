clear; close all; clc

% --- Portable paths based on the saved script location ---
tmpFullPath = matlab.desktop.editor.getActiveFilename;

if ~isempty(tmpFullPath) && isfile(tmpFullPath)
    scriptDir = fileparts(tmpFullPath);
else
    tmpFullPath = mfilename('fullpath');
    if ~isempty(tmpFullPath)
        scriptDir = fileparts(tmpFullPath);
    else
        scriptDir = pwd;
    end
end

ncDir = fullfile(scriptDir, 'Export');
outDir = fullfile(scriptDir, 'Export');

if ~isfolder(outDir)
    mkdir(outDir);
end

if ~isfolder(ncDir)
    error('Export folder not found: %s', ncDir)
end

load(fullfile(scriptDir, "vik.mat"));
load(fullfile(scriptDir, "oslo.mat"));

% --- Interface colors ---
c_reg = cell(3,1);
c_reg{1} = [204, 121, 167] / 255; % air-snow (magenta)
c_reg{2} = [58, 174, 140] / 255;  % snow-ice
c_reg{3} = [245, 174, 16] / 255;  % ice-water

tempLevels = -25:0.1:2.5;
gradLevels = -10:0.1:10;
heatLevels = -1:0.02:3;
heat120Levels = -1:0.02:3;

tempCLim = [-2.5 2.5];
gradCLim = [-4 4];
heatCLim = [0 2.0];
heat120CLim = [0 2.0];

nTicks = 5;

cfg = struct([]);
cfg(1).id = 'T143'; cfg(1).titleText = 'Floe 1, 2025T143';
cfg(2).id = 'T144'; cfg(2).titleText = 'Floe 2, 2025T144';
cfg(3).id = 'T145'; cfg(3).titleText = 'Floe 3, 2025T145';
cfg(4).id = 'T135'; cfg(4).titleText = 'Floe 2, 2025T135';
cfg(5).id = 'T136'; cfg(5).titleText = 'Floe 3, 2025T136';

proc = struct([]);

for i = 1:numel(cfg)
    C = cfg(i);
    ncFile = fullfile(ncDir, sprintf('%s_processed.nc', C.id));

    if ~isfile(ncFile)
        warning('Missing NetCDF file: %s', ncFile)
        proc(i).valid = false;
        proc(i).id = C.id;
        proc(i).titleText = C.titleText;
        continue
    end

    proc(i).valid = true;
    proc(i).id = C.id;
    proc(i).titleText = C.titleText;
    proc(i).ncFile = ncFile;

    depth = ncread(ncFile, 'depth');
    proc(i).z = double(depth(:));

    proc(i).timeT = epochDaysToDatetime(ncread(ncFile, 'time_temperature'));
    proc(i).xT = datenum(proc(i).timeT);
    proc(i).T = double(ncread(ncFile, 'temperature'));

    proc(i).airSnow_T = double(ncread(ncFile, 'air_snow_interface_temperature'));
    proc(i).snowIce_T = double(ncread(ncFile, 'snow_ice_interface_temperature'));
    proc(i).iceWater_T = double(ncread(ncFile, 'ice_water_interface_temperature'));

    proc(i).timeH = epochDaysToDatetime(ncread(ncFile, 'time_heating030'));
    proc(i).xH = datenum(proc(i).timeH);
    proc(i).H = double(ncread(ncFile, 'temperature_change_30s'));

    proc(i).airSnow_H = double(ncread(ncFile, 'air_snow_interface_heating030'));
    proc(i).snowIce_H = double(ncread(ncFile, 'snow_ice_interface_heating030'));
    proc(i).iceWater_H = double(ncread(ncFile, 'ice_water_interface_heating030'));

    proc(i).timeH120 = epochDaysToDatetime(ncread(ncFile, 'time_heating120'));
    proc(i).xH120 = datenum(proc(i).timeH120);
    proc(i).H120 = double(ncread(ncFile, 'temperature_change_120s'));

    proc(i).airSnow_H120 = double(ncread(ncFile, 'air_snow_interface_heating120'));
    proc(i).snowIce_H120 = double(ncread(ncFile, 'snow_ice_interface_heating120'));
    proc(i).iceWater_H120 = double(ncread(ncFile, 'ice_water_interface_heating120'));

    proc(i).dTdz = computeVerticalGradient(proc(i).T, proc(i).z);

    proc(i).hasManual = false;
    proc(i).xManual = [];
    proc(i).manualSurface = [];
    proc(i).manualBottom = [];

    info = ncinfo(ncFile);
    varNames = {info.Variables.Name};

    if ismember('time_manual', varNames) && ...
       ismember('manual_air_snow_interface_depth', varNames) && ...
       ismember('manual_ice_water_interface_depth', varNames)

        timeManual = ncread(ncFile, 'time_manual');
        proc(i).timeManual = epochDaysToDatetime(timeManual);
        proc(i).xManual = datenum(proc(i).timeManual);
        proc(i).manualSurface = double(ncread(ncFile, 'manual_air_snow_interface_depth'));
        proc(i).manualBottom = double(ncread(ncFile, 'manual_ice_water_interface_depth'));
        proc(i).hasManual = true;
    end
end

zTopCommon = inf;
for i = 1:numel(proc)
    if isfield(proc(i), 'valid') && proc(i).valid
        zTopCommon = min(zTopCommon, min(proc(i).z));
    end
end
ylimsCommon = [zTopCommon 3.0];

makeSummaryFigureFromNetCDF(proc, ...
    'temperature', tempLevels, tempCLim, vik, ylimsCommon, nTicks, c_reg);
exportgraphics(gcf, fullfile(outDir, "SIMBA_temperature_summary.png"), "Resolution", 300);

makeSummaryFigureFromNetCDF(proc, ...
    'gradient', gradLevels, gradCLim, vik, ylimsCommon, nTicks, c_reg);
exportgraphics(gcf, fullfile(outDir, "SIMBA_gradient_summary.png"), "Resolution", 300);

makeSummaryFigureFromNetCDF(proc, ...
    'heating', heatLevels, heatCLim, flipud(oslo), ylimsCommon, nTicks, c_reg);
exportgraphics(gcf, fullfile(outDir, "SIMBA_heating030_summary.png"), "Resolution", 300);

makeSummaryFigureFromNetCDF(proc, ...
    'heating120', heat120Levels, heat120CLim, flipud(oslo), ylimsCommon, nTicks, c_reg);
exportgraphics(gcf, fullfile(outDir, "SIMBA_heating120_summary.png"), "Resolution", 300);

%% NetCDF description
close all; clc; clear;
scriptDir = fileparts(matlab.desktop.editor.getActiveFilename);
filename = fullfile(scriptDir, 'Export', 'T143_processed.nc');
ncdisp(filename)

%% Helpers
function makeSummaryFigureFromNetCDF(proc, plotType, levels, cLimVals, cmapVals, ylimsCommon, nTicks, c_reg)

figure
set(gcf,'Units','inches','Position',[1 4 12 5])

tile = tiledlayout(2,3);
tile.TileSpacing = 'compact';
tile.Padding = 'compact';

cAirSnow = c_reg{1};
cSnowIce = c_reg{2};
cIceWater = c_reg{3};

for i = 1:numel(proc)
    ax = nexttile;

    if ~isfield(proc(i), 'valid') || ~proc(i).valid
        axis(ax, 'off')
        title(ax, sprintf('%s (missing file)', proc(i).titleText), ...
            'FontSize', 9, 'FontWeight', 'normal')
        continue
    end

    P = proc(i);

    switch lower(plotType)
        case 'temperature'
            x = P.xT;
            data = P.T;
            contourf(ax, x, P.z, data', levels, 'LineColor', 'none');
            hold(ax, 'on')

            plot(ax, x, P.airSnow_T, ':', 'Color', cAirSnow, 'LineWidth', 2.2)
            plot(ax, x, P.snowIce_T, ':', 'Color', cSnowIce, 'LineWidth', 2.2)
            plot(ax, x, P.iceWater_T, ':', 'Color', cIceWater, 'LineWidth', 2.2)

            if P.hasManual
                plot(ax, P.xManual, P.manualSurface, 'o', ...
                    'Color', cAirSnow, 'MarkerFaceColor', cAirSnow, ...
                    'MarkerSize', 6, 'LineWidth', 1.1);
                plot(ax, P.xManual, P.manualBottom, 'o', ...
                    'Color', cIceWater, 'MarkerFaceColor', cIceWater, ...
                    'MarkerSize', 6, 'LineWidth', 1.1);
            end

            addInterfaceChangeLabel(ax, x, P.airSnow_T, cAirSnow, 'air-snow');
            addInterfaceChangeLabel(ax, x, P.iceWater_T, cIceWater, 'ice-water');

            colormap(ax, cmapVals)
            clim(ax, cLimVals)
            cb = colorbar(ax);
            ylabel(cb, 'Temperature (°C)', 'FontSize', 8)
            title(ax, P.titleText, 'FontSize', 9, 'FontWeight', 'normal')

        case 'gradient'
            x = P.xT;
            data = P.dTdz;
            contourf(ax, x, P.z, data', levels, 'LineColor', 'none');
            hold(ax, 'on')

            plot(ax, x, P.airSnow_T, ':', 'Color', cAirSnow, 'LineWidth', 2.2)
            plot(ax, x, P.snowIce_T, ':', 'Color', cSnowIce, 'LineWidth', 2.2)
            plot(ax, x, P.iceWater_T, ':', 'Color', cIceWater, 'LineWidth', 2.2)

            if P.hasManual
                plot(ax, P.xManual, P.manualSurface, 'o', ...
                    'Color', cAirSnow, 'MarkerFaceColor', cAirSnow, ...
                    'MarkerSize', 6, 'LineWidth', 1.1);
                plot(ax, P.xManual, P.manualBottom, 'o', ...
                    'Color', cIceWater, 'MarkerFaceColor', cIceWater, ...
                    'MarkerSize', 6, 'LineWidth', 1.1);
            end

            addInterfaceChangeLabel(ax, x, P.airSnow_T, cAirSnow, 'air-snow');
            addInterfaceChangeLabel(ax, x, P.iceWater_T, cIceWater, 'ice-water');

            colormap(ax, cmapVals)
            clim(ax, cLimVals)
            cb = colorbar(ax);
            ylabel(cb, 'Vertical temperature gradient dT/dz (°C m^{-1})', 'FontSize', 8)
            title(ax, P.titleText, 'FontSize', 9, 'FontWeight', 'normal')

        case 'heating'
            x = P.xH;
            data = P.H;
            contourf(ax, x, P.z, data', levels, 'LineColor', 'none');
            hold(ax, 'on')

            plot(ax, x, P.airSnow_H, ':', 'Color', cAirSnow, 'LineWidth', 2.2)
            plot(ax, x, P.snowIce_H, ':', 'Color', cSnowIce, 'LineWidth', 2.2)
            plot(ax, x, P.iceWater_H, ':', 'Color', cIceWater, 'LineWidth', 2.2)

            if P.hasManual
                plot(ax, P.xManual, P.manualSurface, 'o', ...
                    'Color', cAirSnow, 'MarkerFaceColor', cAirSnow, ...
                    'MarkerSize', 6, 'LineWidth', 1.1);
                plot(ax, P.xManual, P.manualBottom, 'o', ...
                    'Color', cIceWater, 'MarkerFaceColor', cIceWater, ...
                    'MarkerSize', 6, 'LineWidth', 1.1);
            end

            addInterfaceChangeLabel(ax, x, P.airSnow_H, cAirSnow, 'air-snow');
            addInterfaceChangeLabel(ax, x, P.iceWater_H, cIceWater, 'ice-water');

            colormap(ax, cmapVals)
            clim(ax, cLimVals)
            cb = colorbar(ax);
            ylabel(cb, 'Temperature change (°C)', 'FontSize', 8)
            title(ax, [P.titleText ' (30 s heating)'], 'FontSize', 9, 'FontWeight', 'normal')

        case 'heating120'
            x = P.xH120;
            data = P.H120;
            contourf(ax, x, P.z, data', levels, 'LineColor', 'none');
            hold(ax, 'on')

            plot(ax, x, P.airSnow_H120, ':', 'Color', cAirSnow, 'LineWidth', 2.2)
            plot(ax, x, P.snowIce_H120, ':', 'Color', cSnowIce, 'LineWidth', 2.2)
            plot(ax, x, P.iceWater_H120, ':', 'Color', cIceWater, 'LineWidth', 2.2)

            if P.hasManual
                plot(ax, P.xManual, P.manualSurface, 'o', ...
                    'Color', cAirSnow, 'MarkerFaceColor', cAirSnow, ...
                    'MarkerSize', 6, 'LineWidth', 1.1);
                plot(ax, P.xManual, P.manualBottom, 'o', ...
                    'Color', cIceWater, 'MarkerFaceColor', cIceWater, ...
                    'MarkerSize', 6, 'LineWidth', 1.1);
            end

            addInterfaceChangeLabel(ax, x, P.airSnow_H120, cAirSnow, 'air-snow');
            addInterfaceChangeLabel(ax, x, P.iceWater_H120, cIceWater, 'ice-water');

            colormap(ax, cmapVals)
            clim(ax, cLimVals)
            cb = colorbar(ax);
            ylabel(cb, 'Temperature change (°C)', 'FontSize', 8)
            title(ax, [P.titleText ' (120 s heating)'], 'FontSize', 9, 'FontWeight', 'normal')
    end

    formatAxis(ax, x, ylimsCommon, nTicks, getManualX(P))

    if i == 1 || i == 4
        ylabel(ax, 'Depth (m)', 'FontSize', 8)
    end
end

nexttile(6)
axis off
hold on

hManualSurface = plot(nan, nan, 'o', ...
    'Color', cAirSnow, 'MarkerFaceColor', cAirSnow, ...
    'MarkerSize', 7, 'LineWidth', 1.2);

hManualBottom = plot(nan, nan, 'o', ...
    'Color', cIceWater, 'MarkerFaceColor', cIceWater, ...
    'MarkerSize', 7, 'LineWidth', 1.2);

hAirSnow = plot(nan, nan, ':', 'Color', cAirSnow, 'LineWidth', 2.2);
hSnowIce = plot(nan, nan, ':', 'Color', cSnowIce, 'LineWidth', 2.2);
hIceWater = plot(nan, nan, ':', 'Color', cIceWater, 'LineWidth', 2.2);

lgd = legend([hManualSurface, hManualBottom, hAirSnow, hSnowIce, hIceWater], ...
    {'manual surface', 'manual bottom', 'air-snow interface', 'snow-ice interface', 'ice-water interface'}, ...
    'Location', 'northwest');

lgd.Box = 'off';
lgd.FontSize = 10;

switch lower(plotType)
    case 'temperature'
        title('Legend - temperature', 'FontSize', 11, 'FontWeight', 'normal')
    case 'gradient'
        title('Legend - gradient', 'FontSize', 11, 'FontWeight', 'normal')
    case 'heating'
        title('Legend - heating 30 s', 'FontSize', 11, 'FontWeight', 'normal')
    case 'heating120'
        title('Legend - heating 120 s', 'FontSize', 11, 'FontWeight', 'normal')
end
end

function xExtra = getManualX(P)
if isfield(P, 'hasManual') && P.hasManual && isfield(P, 'xManual')
    xExtra = P.xManual;
else
    xExtra = [];
end
end

function formatAxis(ax, x, ylimsCommon, nTicks, xExtra)

if nargin < 5 || isempty(xExtra)
    xExtra = [];
end

xAll = [x(:); xExtra(:)];
xAll = xAll(isfinite(xAll));

if isempty(xAll)
    xMin = min(x);
    xMax = max(x);
else
    xMin = min(xAll);
    xMax = max(xAll);
end

if xMax > xMin
    xPad = 0.02 * (xMax - xMin);
else
    xPad = 0.5;
end

xlim(ax, [xMin - xPad, xMax + xPad]);
ax.XTick = linspace(xMin, xMax, nTicks);
datetick(ax, 'x', 'mmm dd', 'keepticks', 'keeplimits');
xtickangle(ax, 0);
set(ax, 'YDir', 'reverse');
ylim(ax, ylimsCommon);
set(ax, 'FontSize', 8, 'FontWeight', 'normal');
end

function dTdz = computeVerticalGradient(T, z)
nWin = 7;
halfWin = floor(nWin/2);
dTdz = nan(size(T));

z = z(:);

for it = 1:size(T,1)
    for iz = 1:size(T,2)
        i1 = max(1, iz-halfWin);
        i2 = min(size(T,2), iz+halfWin);

        zloc = z(i1:i2);
        Tloc = T(it,i1:i2).';

        good = isfinite(zloc) & isfinite(Tloc);

        zloc = zloc(good);
        Tloc = Tloc(good);

        if numel(zloc) >= 3
            pfit = polyfit(zloc, Tloc, 1);
            dTdz(it,iz) = pfit(1);
        end
    end
end
end

function t = epochDaysToDatetime(timeDays)
timeDays = double(timeDays(:));
t = datetime(1970,1,1,0,0,0) + days(timeDays);
end

function addInterfaceChangeLabel(ax, x, y, txtColor, interfaceType)

x = x(:);
y = y(:);

good = isfinite(x) & isfinite(y);
x = x(good);
y = y(good);

if numel(x) < 2
    return
end

switch lower(interfaceType)
    case 'air-snow'
        dy = -y(end) + y(1);
    case 'ice-water'
        dy = y(end) - y(1);
    otherwise
        dy = y(end) - y(1);
end

midIdx = round(numel(x)/2);
xMid = x(midIdx);
yMid = y(midIdx) + 0.3;
labelStr = sprintf('\\Delta = %.2f m', dy);

text(ax, xMid, yMid, labelStr, ...
    'Color', txtColor, ...
    'FontSize', 8, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'Clipping', 'on');
end