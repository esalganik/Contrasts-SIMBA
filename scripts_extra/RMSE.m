clear; close all; clc

if usejava('desktop')
    scriptDir = fileparts(matlab.desktop.editor.getActiveFilename);
    if isempty(scriptDir)
        scriptDir = pwd;
    end
else
    scriptDir = pwd;
end

outDir = fullfile(scriptDir, 'Export');
buoys = {'2025T143','2025T144','2025T145','2025T135','2025T136'};

maxTimeOffsetHours = 24;

allSurfManual = [];
allSurfAuto   = [];
allBottManual = [];
allBottAuto   = [];

for i = 1:numel(buoys)
    buoyID = buoys{i};
    ncFile = fullfile(outDir, sprintf('%s.nc', buoyID));

    if ~isfile(ncFile)
        warning('Missing file: %s', ncFile)
        continue
    end

    try
        tAuto = readNcTime(ncFile, 'time_temperature');
        tManual = readNcTime(ncFile, 'time_manual');

        surfAuto = double(ncread(ncFile, 'air_snow_interface_temperature'));
        bottAuto = double(ncread(ncFile, 'ice_water_interface_temperature'));

        surfManual = double(ncread(ncFile, 'manual_air_snow_interface_depth'));
        bottManual = double(ncread(ncFile, 'manual_ice_water_interface_depth'));
    catch ME
        warning('Problem reading %s: %s', buoyID, ME.message)
        continue
    end

    if isempty(tManual) || isempty(tAuto)
        continue
    end

    for k = 1:numel(tManual)
        [dtMin, idx] = min(abs(tAuto - tManual(k)));
        dtHours = hours(dtMin);

        if isempty(idx) || ~isfinite(dtHours) || dtHours > maxTimeOffsetHours
            continue
        end

        if isfinite(surfManual(k)) && isfinite(surfAuto(idx))
            allSurfManual(end+1,1) = surfManual(k); %#ok<SAGROW>
            allSurfAuto(end+1,1)   = surfAuto(idx); %#ok<SAGROW>
        end

        if isfinite(bottManual(k)) && isfinite(bottAuto(idx))
            allBottManual(end+1,1) = bottManual(k); %#ok<SAGROW>
            allBottAuto(end+1,1)   = bottAuto(idx); %#ok<SAGROW>
        end
    end
end

surfRMSE = calcRMSE(allSurfAuto - allSurfManual);
bottRMSE = calcRMSE(allBottAuto - allBottManual);

fprintf('\n')
fprintf('Option A text for abstract:\n')
fprintf('The accuracy of the automatically detected air-snow and ice-water interfaces, evaluated against manual measurements, is +/- %.2f m and +/- %.2f m (RMSE), respectively.\n', ...
    surfRMSE, bottRMSE)

figure('Color', 'w')

subplot(1,2,1)
scatter(allSurfManual, allSurfAuto, 40, 'filled')
hold on
plotIdentityLine(allSurfManual, allSurfAuto)
grid on
axis equal
xlabel('Manual air-snow interface depth (m)')
ylabel('Automatic air-snow interface depth (m)')
title(sprintf('Surface interface (RMSE = %.2f m)', surfRMSE))

subplot(1,2,2)
scatter(allBottManual, allBottAuto, 40, 'filled')
hold on
plotIdentityLine(allBottManual, allBottAuto)
grid on
axis equal
xlabel('Manual ice-water interface depth (m)')
ylabel('Automatic ice-water interface depth (m)')
title(sprintf('Bottom interface (RMSE = %.2f m)', bottRMSE))

function t = readNcTime(ncFile, varName)
x = double(ncread(ncFile, varName));
t = datetime(x * 86400, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
t = t(:);
end

function rmse = calcRMSE(err)
err = err(isfinite(err));
if isempty(err)
    rmse = NaN;
else
    rmse = sqrt(mean(err.^2));
end
end

function plotIdentityLine(x, y)
v = [x(:); y(:)];
v = v(isfinite(v));

if isempty(v)
    return
end

lo = min(v);
hi = max(v);

if lo == hi
    lo = lo - 0.1;
    hi = hi + 0.1;
end

plot([lo hi], [lo hi], 'k--', 'LineWidth', 1)
xlim([lo hi])
ylim([lo hi])
end