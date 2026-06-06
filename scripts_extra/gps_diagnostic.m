clear; close all; clc

% --- SETTINGS ---
saveFigs = false;   % set to false if you do not want to save figures

% --- FIX PATH ---
if usejava('desktop')
    scriptDir = fileparts(matlab.desktop.editor.getActiveFilename);
else
    scriptDir = pwd;
end

outDir = fullfile(scriptDir, 'Export');

if ~exist(outDir, 'dir')
    mkdir(outDir)
end

buoys = {'2025T143','2025T144','2025T145','2025T135','2025T136'};

for i = 1:numel(buoys)

    id = buoys{i};
    file = fullfile(outDir, sprintf('%s.nc', id));

    if ~isfile(file)
        warning('Missing file: %s', file)
        continue
    end

    % --- READ DATA ---
    t = ncread(file, 'time_temperature');
    t = datetime(t * 86400, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');

    lat_raw = ncread(file, 'latitude_temperature_raw');
    lon_raw = ncread(file, 'longitude_temperature_raw');

    lat = ncread(file, 'latitude_temperature');
    lon = ncread(file, 'longitude_temperature');

    geoFlag = ncread(file, 'geolocation_flag_temperature');

    % --- PLOT ---
    fig = figure('Name', id);

    % LATITUDE
    subplot(2,1,1)
    plot(t, lat_raw, '.', 'DisplayName', 'raw')
    hold on
    plot(t, lat, '-', 'LineWidth', 1.5, 'DisplayName', 'corrected')
    plot(t(geoFlag == 3), lat_raw(geoFlag == 3), 'ro', 'DisplayName', 'invalid/rejected')
    plot(t(geoFlag == 2), lat(geoFlag == 2), 'kx', 'DisplayName', 'interpolated')
    legend('Location', 'best')
    grid on
    title([id ' latitude QC'])
    ylabel('latitude')

    % LONGITUDE
    subplot(2,1,2)
    plot(t, lon_raw, '.', 'DisplayName', 'raw')
    hold on
    plot(t, lon, '-', 'LineWidth', 1.5, 'DisplayName', 'corrected')
    plot(t(geoFlag == 3), lon_raw(geoFlag == 3), 'ro', 'DisplayName', 'invalid/rejected')
    plot(t(geoFlag == 2), lon(geoFlag == 2), 'kx', 'DisplayName', 'interpolated')
    legend('Location', 'best')
    grid on
    title([id ' longitude QC'])
    ylabel('longitude')

    % --- SAVE FIGURE IF REQUESTED ---
    if saveFigs
        saveName = fullfile(outDir, sprintf('%s_QC.png', id));
        exportgraphics(fig, saveName, 'Resolution', 300)
    end

end