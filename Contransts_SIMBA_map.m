close all; clc

% -------------------------------------------------------------------------
% Configuration
% -------------------------------------------------------------------------
scriptDir = fileparts(matlab.desktop.editor.getActiveFilename);
if isempty(scriptDir)
    scriptDir = pwd;
end
outDir = fullfile(scriptDir, 'Export');

% Colors per buoy
buoyColors = [ ...
    1,  61, 115;
   58, 174, 140;
  245, 174,  16;
  220,  50,  47;
  108,  76, 203;
] / 255;

markerSize        = 5;
trackLineWidCorr  = 1.4;
trackLineWidRaw   = 0.8;
fs                = 7.2;
c_txt             = [0.45 0.45 0.45];
rawColor          = [0.60 0.60 0.60];

% -------------------------------------------------------------------------
% Discover NetCDF files
% -------------------------------------------------------------------------
ncFiles = dir(fullfile(outDir, '*_processed.nc'));
if isempty(ncFiles)
    error('No *_processed.nc files found in: %s', outDir);
end

% -------------------------------------------------------------------------
% Read data
% -------------------------------------------------------------------------
buoys = struct('id', {}, 'lat_raw', {}, 'lon_raw', {}, ...
               'lat_corr', {}, 'lon_corr', {}, 'time', {});

for k = 1:numel(ncFiles)
    fp = fullfile(ncFiles(k).folder, ncFiles(k).name);

    bid   = string(ncreadatt(fp, '/', 'buoy_id'));
    tDays = double(ncread(fp, 'time_temperature'));

    latCorr = double(ncread(fp, 'latitude_temperature'));
    lonCorr = double(ncread(fp, 'longitude_temperature'));

    % Raw (fallback safe)
    if hasVariable(fp, 'latitude_temperature_raw')
        latRaw = double(ncread(fp, 'latitude_temperature_raw'));
        lonRaw = double(ncread(fp, 'longitude_temperature_raw'));
    else
        latRaw = latCorr;
        lonRaw = lonCorr;
    end

    t = datetime(tDays * 86400, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');

    buoys(k).id       = char(bid);
    buoys(k).lat_raw  = latRaw(:);
    buoys(k).lon_raw  = lonRaw(:);
    buoys(k).lat_corr = latCorr(:);
    buoys(k).lon_corr = lonCorr(:);
    buoys(k).time     = t(:);

    fprintf('Loaded %s (%d points)\n', buoys(k).id, numel(t));
end

% -------------------------------------------------------------------------
% Map bounds
% -------------------------------------------------------------------------
allLat = [];
allLon = [];

for k = 1:numel(buoys)
    allLat = [allLat; buoys(k).lat_raw; buoys(k).lat_corr];
    allLon = [allLon; buoys(k).lon_raw; buoys(k).lon_corr];
end

allLat = allLat(isfinite(allLat));
allLon = allLon(isfinite(allLon));

latPad = 1.5;
lonPad = 5.0;

latLims = [max(-90, min(allLat) - latPad), min(90, max(allLat) + latPad)];
lonLims = [min(allLon) - lonPad, max(allLon) + lonPad];

% -------------------------------------------------------------------------
% Figure
% -------------------------------------------------------------------------
figure('Color','w')
tile = tiledlayout(1,1);
tile.TileSpacing = 'compact';
tile.Padding     = 'compact';
nexttile

m_proj('lambert', 'lons', lonLims, 'lat', latLims);

m_grid('linewi', 0.7, 'linestyle', ':', 'layer', 'top', ...
       'fontsize', fs, 'backcolor', 'w');

m_gshhs_i('patch', [0.7 0.7 0.7], 'edgecolor', 'none');

hold on

% -------------------------------------------------------------------------
% Plot
% -------------------------------------------------------------------------
hLeg = gobjects(numel(buoys),1);

for k = 1:numel(buoys)

    col = buoyColors(min(k, size(buoyColors,1)), :);

    latRaw  = buoys(k).lat_raw;
    lonRaw  = buoys(k).lon_raw;
    latCorr = buoys(k).lat_corr;
    lonCorr = buoys(k).lon_corr;

    goodRaw  = isfinite(latRaw)  & isfinite(lonRaw);
    goodCorr = isfinite(latCorr) & isfinite(lonCorr);

    if sum(goodCorr) < 2
        warning('Skipping %s (not enough valid points)', buoys(k).id);
        continue
    end

    % --- RAW TRACK (gray dashed)
    if sum(goodRaw) >= 2
        m_line(lonRaw(goodRaw), latRaw(goodRaw), ...
            'Color', rawColor, ...
            'LineStyle', '--', ...
            'LineWidth', trackLineWidRaw);
    end

    % --- CORRECTED TRACK (main)
    hLeg(k) = m_line(lonCorr(goodCorr), latCorr(goodCorr), ...
        'Color', col, ...
        'LineWidth', trackLineWidCorr, ...
        'DisplayName', buoys(k).id);

    % --- START marker
    iFirst = find(goodCorr, 1, 'first');
    m_line(lonCorr(iFirst), latCorr(iFirst), ...
        'marker', 'o', ...
        'color', 'k', ...
        'markerfacecolor', col, ...
        'linestyle', 'none', ...
        'linewi', 0.8, ...
        'markersize', markerSize + 1);

    % --- END marker
    iLast = find(goodCorr, 1, 'last');
    m_line(lonCorr(iLast), latCorr(iLast), ...
        'marker', 's', ...
        'color', 'k', ...
        'markerfacecolor', col, ...
        'linestyle', 'none', ...
        'linewi', 0.8, ...
        'markersize', markerSize + 1);

    % --- LABEL
    m_text(lonCorr(iLast) + 0.5, latCorr(iLast), buoys(k).id, ...
        'FontSize', fs, ...
        'Color', col, ...
        'FontWeight', 'bold', ...
        'VerticalAlignment', 'middle');
end

% -------------------------------------------------------------------------
% Legend
% -------------------------------------------------------------------------
validIdx = isgraphics(hLeg);
if any(validIdx)
    legend(hLeg(validIdx), {buoys(validIdx).id}, ...
        'Location', 'southwest', ...
        'FontSize', fs, ...
        'Box', 'on');
end

% -------------------------------------------------------------------------
% Annotation
% -------------------------------------------------------------------------
annotation('textbox', [0.01 0.01 0.30 0.05], ...
    'String', 'Gray dashed = raw   Solid = corrected   ○ start   □ end', ...
    'FontSize', fs-0.5, ...
    'EdgeColor', 'none', ...
    'Color', c_txt, ...
    'FitBoxToText', 'on');

% -------------------------------------------------------------------------
% Export
% -------------------------------------------------------------------------
set(gcf, 'Units','inches','Position',[1 1 5.6 4.4]);

outPng = fullfile(outDir, 'buoy_geolocation_map_clean.png');
exportgraphics(gcf, outPng, 'Resolution', 600);

fprintf('Saved map to: %s\n', outPng);

% -------------------------------------------------------------------------
% Helper
% -------------------------------------------------------------------------
function tf = hasVariable(ncFile, varName)
info = ncinfo(ncFile);
tf = any(strcmp({info.Variables.Name}, varName));
end