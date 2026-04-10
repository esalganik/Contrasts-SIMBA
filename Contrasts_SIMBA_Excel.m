clear; close all; clc

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
xlsxDir = fullfile(scriptDir, 'Excel_export');

if ~isfolder(ncDir)
    error('Export folder not found: %s', ncDir)
end

if ~isfolder(xlsxDir)
    mkdir(xlsxDir)
end

ncFiles = dir(fullfile(ncDir, '*.nc'));

if isempty(ncFiles)
    error('No NetCDF files found in %s', ncDir)
end

for iFile = 1:numel(ncFiles)
    ncFile = fullfile(ncFiles(iFile).folder, ncFiles(iFile).name);
    fprintf('Processing %s ...\n', ncFiles(iFile).name);

    info = ncinfo(ncFile);
    buoyID = readGlobalAttributeSafe(info, 'buoy_id');

    if strlength(buoyID) == 0
        buoyID = extractBuoyIdFromFilename(ncFiles(iFile).name);
    end

    buoyID = normalizeBuoyId(buoyID);
    eventInfo = getEventInfo(buoyID);

    depth = readVarSafe(ncFile, 'depth');

    % Temperature axis
    timeT = readTimeVarSafe(ncFile, 'time_temperature');

    latT_raw = readVarSafe(ncFile, 'latitude_temperature_raw');
    lonT_raw = readVarSafe(ncFile, 'longitude_temperature_raw');

    latT = readVarSafe(ncFile, 'latitude_temperature');
    lonT = readVarSafe(ncFile, 'longitude_temperature');
    geoFlagT = readVarSafe(ncFile, 'geolocation_flag_temperature');

    airSnowT = readVarSafe(ncFile, 'air_snow_interface_temperature');
    snowIceT = readVarSafe(ncFile, 'snow_ice_interface_temperature');
    iceWaterT = readVarSafe(ncFile, 'ice_water_interface_temperature');
    snowThickT = readVarSafe(ncFile, 'snow_thickness_temperature');
    iceThickT = readVarSafe(ncFile, 'ice_thickness_temperature');
    T = readVarSafe(ncFile, 'temperature');

    % Manual measurements
    timeM = readTimeVarSafe(ncFile, 'time_manual');
    manualAirSnow = readVarSafe(ncFile, 'manual_air_snow_interface_depth');
    manualIceWater = readVarSafe(ncFile, 'manual_ice_water_interface_depth');

    % Heating 30 s
    timeH30 = readTimeVarSafe(ncFile, 'time_heating030');
    H30 = readVarSafe(ncFile, 'temperature_change_30s');

    airSnowH30 = readVarSafe(ncFile, 'air_snow_interface_heating030');
    snowIceH30 = readVarSafe(ncFile, 'snow_ice_interface_heating030');
    iceWaterH30 = readVarSafe(ncFile, 'ice_water_interface_heating030');
    snowThickH30 = readVarSafe(ncFile, 'snow_thickness_heating030');
    iceThickH30 = readVarSafe(ncFile, 'ice_thickness_heating030');

    % Heating 120 s
    timeH120 = readTimeVarSafe(ncFile, 'time_heating120');
    H120 = readVarSafe(ncFile, 'temperature_change_120s');

    airSnowH120 = readVarSafe(ncFile, 'air_snow_interface_heating120');
    snowIceH120 = readVarSafe(ncFile, 'snow_ice_interface_heating120');
    iceWaterH120 = readVarSafe(ncFile, 'ice_water_interface_heating120');
    snowThickH120 = readVarSafe(ncFile, 'snow_thickness_heating120');
    iceThickH120 = readVarSafe(ncFile, 'ice_thickness_heating120');

    % Interpolate corrected and raw GPS onto heating axes
    [latH30, lonH30, geoFlagH30] = interpolateGeo(timeT, latT, lonT, geoFlagT, timeH30);
    [latH120, lonH120, geoFlagH120] = interpolateGeo(timeT, latT, lonT, geoFlagT, timeH120);

    [latH30_raw, lonH30_raw] = interpolateRaw(timeT, latT_raw, lonT_raw, timeH30);
    [latH120_raw, lonH120_raw] = interpolateRaw(timeT, latT_raw, lonT_raw, timeH120);

    % Place manual measurements on corresponding time axes
    [manualAirSnow_T, manualIceWater_T] = mapManualToAxis(timeT, timeM, manualAirSnow, manualIceWater);
    [manualAirSnow_H30, manualIceWater_H30] = mapManualToAxis(timeH30, timeM, manualAirSnow, manualIceWater);
    [manualAirSnow_H120, manualIceWater_H120] = mapManualToAxis(timeH120, timeM, manualAirSnow, manualIceWater);

    if ~isempty(T) && ~isempty(timeT)
        outFile = fullfile(xlsxDir, sprintf('%s_temperature.xlsx', buoyID));
        writeWide( ...
            outFile, timeT, ...
            latT_raw, lonT_raw, latT, lonT, geoFlagT, ...
            airSnowT, snowIceT, iceWaterT, snowThickT, iceThickT, ...
            manualAirSnow_T, manualIceWater_T, ...
            depth, T, 'temperature');
        writeMetaSheet(outFile, buoyID, eventInfo, 'temperature');
        fprintf('Wrote %s\n', outFile);
    end

    if ~isempty(H30) && ~isempty(timeH30)
        outFile = fullfile(xlsxDir, sprintf('%s_heating030.xlsx', buoyID));
        writeWide( ...
            outFile, timeH30, ...
            latH30_raw, lonH30_raw, latH30, lonH30, geoFlagH30, ...
            airSnowH30, snowIceH30, iceWaterH30, snowThickH30, iceThickH30, ...
            manualAirSnow_H30, manualIceWater_H30, ...
            depth, H30, 'temperature_change_30s');
        writeMetaSheet(outFile, buoyID, eventInfo, 'temperature_change_30s');
        fprintf('Wrote %s\n', outFile);
    end

    if ~isempty(H120) && ~isempty(timeH120)
        outFile = fullfile(xlsxDir, sprintf('%s_heating120.xlsx', buoyID));
        writeWide( ...
            outFile, timeH120, ...
            latH120_raw, lonH120_raw, latH120, lonH120, geoFlagH120, ...
            airSnowH120, snowIceH120, iceWaterH120, snowThickH120, iceThickH120, ...
            manualAirSnow_H120, manualIceWater_H120, ...
            depth, H120, 'temperature_change_120s');
        writeMetaSheet(outFile, buoyID, eventInfo, 'temperature_change_120s');
        fprintf('Wrote %s\n', outFile);
    end
end

fprintf('Done.\n')
fprintf('Output folder: %s\n', xlsxDir)

%% ================= HELPERS =================

function writeWide(outFile, timeVec, latRaw, lonRaw, lat, lon, geoFlag, ...
    airSnow, snowIce, iceWater, snowThick, iceThick, ...
    manualAirSnow, manualIceWater, ...
    depth, data, prefix)

n = numel(timeVec);

latRaw = fixLen(latRaw, n);
lonRaw = fixLen(lonRaw, n);
lat = fixLen(lat, n);
lon = fixLen(lon, n);
geoFlag = fixLen(geoFlag, n);
airSnow = fixLen(airSnow, n);
snowIce = fixLen(snowIce, n);
iceWater = fixLen(iceWater, n);
snowThick = fixLen(snowThick, n);
iceThick = fixLen(iceThick, n);
manualAirSnow = fixLen(manualAirSnow, n);
manualIceWater = fixLen(manualIceWater, n);

latRaw = roundN(latRaw, 4);
lonRaw = roundN(lonRaw, 4);
lat = roundN(lat, 4);
lon = roundN(lon, 4);

airSnow = roundN(airSnow, 3);
snowIce = roundN(snowIce, 3);
iceWater = roundN(iceWater, 3);
snowThick = roundN(snowThick, 3);
iceThick = roundN(iceThick, 3);
manualAirSnow = roundN(manualAirSnow, 3);
manualIceWater = roundN(manualIceWater, 3);

depth = double(depth(:));
data = double(data);

if size(data,1) ~= n
    error('Row mismatch between time vector and data matrix.')
end

if size(data,2) ~= numel(depth)
    error('Column mismatch between depth vector and data matrix.')
end

headers = { ...
    'DATE/TIME (UTC)', ...
    'LATITUDE, raw GPS [deg]', ...
    'LONGITUDE, raw GPS [deg]', ...
    'LATITUDE, quality-controlled [deg]', ...
    'LONGITUDE, quality-controlled [deg]', ...
    'Flag, geolocation quality', ...
    'Depth, air-snow interface [m]', ...
    'Depth, snow-ice interface [m]', ...
    'Depth, ice-water interface [m]', ...
    'Thickness, snow [m]', ...
    'Thickness, ice [m]', ...
    'Depth, manual air-snow interface [m]', ...
    'Depth, manual ice-water interface [m]'};

for k = 1:numel(depth)
    headers{end+1} = makePangaeaDepthHeader(prefix, depth(k));
end

C = cell(n+1, numel(headers));
C(1,:) = headers;

C(2:end,1) = cellstr(datestr(timeVec, 'yyyy-mm-ddTHH:MM:SS'));
C(2:end,2) = num2cell(latRaw);
C(2:end,3) = num2cell(lonRaw);
C(2:end,4) = num2cell(lat);
C(2:end,5) = num2cell(lon);
C(2:end,6) = num2cell(geoFlag);
C(2:end,7) = num2cell(airSnow);
C(2:end,8) = num2cell(snowIce);
C(2:end,9) = num2cell(iceWater);
C(2:end,10) = num2cell(snowThick);
C(2:end,11) = num2cell(iceThick);
C(2:end,12) = num2cell(manualAirSnow);
C(2:end,13) = num2cell(manualIceWater);

for k = 1:numel(depth)
    C(2:end,13+k) = num2cell(data(:,k));
end

if isfile(outFile)
    delete(outFile)
end

writecell(C, outFile, 'Sheet', 'data', 'Range', 'A1');

infoTable = buildColumnInfoTable(prefix, depth);
writecell(infoTable, outFile, 'Sheet', 'column_info', 'Range', 'A1');
end

function writeMetaSheet(outFile, buoyID, eventInfo, prefix)

switch string(prefix)
    case "temperature"
        datasetType = 'Temperature time series';
    case "temperature_change_30s"
        datasetType = 'Temperature change after 30 s heating time series';
    case "temperature_change_120s"
        datasetType = 'Temperature change after 120 s heating time series';
    otherwise
        datasetType = char(prefix);
end

meta = {
    'Field', 'Value';
    'Event ID', eventInfo.id;
    'Event label', eventInfo.label;
    'Event type', eventInfo.type;
    'Expedition', 'PS149';
    'Platform', 'RV Polarstern / sea ice buoy deployment';
    'Device', 'SIMBA';
    'Buoy ID', char(buoyID);
    'Dataset type', datasetType;
    'Time zone', 'UTC';
    'Depth reference', 'Below water level';
    'Depth positive direction', 'Down';
    'Notes', 'Manual interface columns are populated only at matching manual observation times; other rows are empty.'
    };

writecell(meta, outFile, 'Sheet', 'metadata', 'Range', 'A1');
end

function evt = getEventInfo(buoyID)

evt = struct('id', '', 'type', 'deployment', 'label', '');

switch char(string(buoyID))
    case '2025T135'
        evt.id = '62709';
        evt.label = 'PS149_25-1-2025T135';
    case '2025T136'
        evt.id = '62864';
        evt.label = 'PS149_30-1-2025T136';
    case '2025T143'
        evt.id = '62646';
        evt.label = 'PS149_13-1-2025T143';
    case '2025T144'
        evt.id = '62665';
        evt.label = 'PS149_16-1-2025T144';
    case '2025T145'
        evt.id = '62708';
        evt.label = 'PS149_18-1-2025T145';
    otherwise
        evt.id = '';
        evt.label = '';
end
end

function hdr = makePangaeaDepthHeader(prefix, depthValue)
depthValue = round(depthValue, 2);

switch string(prefix)
    case "temperature"
        hdr = sprintf('Temperature [deg C] @ depth=%.2f m below water level', depthValue);
    case "temperature_change_30s"
        hdr = sprintf('Temperature change after 30 s heating [deg C] @ depth=%.2f m below water level', depthValue);
    case "temperature_change_120s"
        hdr = sprintf('Temperature change after 120 s heating [deg C] @ depth=%.2f m below water level', depthValue);
    otherwise
        hdr = sprintf('%s [1] @ depth=%.2f m below water level', char(prefix), depthValue);
end
end

function T = buildColumnInfoTable(prefix, depth)
baseRows = {
    'DATE/TIME (UTC)', '', 'UTC timestamp in ISO 8601 format';
    'LATITUDE, raw GPS [deg]', 'deg', 'Raw GPS latitude from NetCDF temperature axis; interpolated to heating axes when needed';
    'LONGITUDE, raw GPS [deg]', 'deg', 'Raw GPS longitude from NetCDF temperature axis; interpolated to heating axes when needed';
    'LATITUDE, quality-controlled [deg]', 'deg', 'Quality-controlled latitude; interpolated to heating axes when needed';
    'LONGITUDE, quality-controlled [deg]', 'deg', 'Quality-controlled longitude; interpolated to heating axes when needed';
    'Flag, geolocation quality', '', '1=original; 2=interpolated; 3=invalid; 4=edge extrapolated; 5=long-gap filled';
    'Depth, air-snow interface [m]', 'm', 'Interpolated air-snow interface depth below water level';
    'Depth, snow-ice interface [m]', 'm', 'Interpolated snow-ice interface depth below water level';
    'Depth, ice-water interface [m]', 'm', 'Interpolated ice-water interface depth below water level';
    'Thickness, snow [m]', 'm', 'Snow thickness';
    'Thickness, ice [m]', 'm', 'Ice thickness';
    'Depth, manual air-snow interface [m]', 'm', 'Manual air-snow interface measurement placed only at matching observation times';
    'Depth, manual ice-water interface [m]', 'm', 'Manual ice-water interface measurement placed only at matching observation times'
    };

rows = baseRows;

for k = 1:numel(depth)
    depthRounded = round(depth(k), 2);

    switch string(prefix)
        case "temperature"
            pname = sprintf('Temperature [deg C] @ depth=%.2f m below water level', depthRounded);
            pcomment = 'SIMBA thermistor temperature at fixed sensor depth';
        case "temperature_change_30s"
            pname = sprintf('Temperature change after 30 s heating [deg C] @ depth=%.2f m below water level', depthRounded);
            pcomment = 'Temperature change measured during 30 s heating cycle at fixed sensor depth';
        case "temperature_change_120s"
            pname = sprintf('Temperature change after 120 s heating [deg C] @ depth=%.2f m below water level', depthRounded);
            pcomment = 'Temperature change measured during 120 s heating cycle at fixed sensor depth';
        otherwise
            pname = sprintf('%s @ depth=%.2f m below water level', char(prefix), depthRounded);
            pcomment = 'Measurement at fixed sensor depth';
    end

    rows(end+1,:) = {pname, 'deg C', pcomment}; %#ok<AGROW>
end

T = [{'Column name', 'Unit', 'Comment'}; rows];
end

function [manual1Out, manual2Out] = mapManualToAxis(targetTime, manualTime, manual1, manual2)
n = numel(targetTime);
manual1Out = nan(n,1);
manual2Out = nan(n,1);

if isempty(targetTime) || isempty(manualTime)
    return
end

manualTime = manualTime(:);
manual1 = forceColumnOrNaN(manual1, numel(manualTime));
manual2 = forceColumnOrNaN(manual2, numel(manualTime));

targetPosix = posixtime(targetTime(:));
manualPosix = posixtime(manualTime);

for k = 1:numel(manualPosix)
    idx = find(targetPosix == manualPosix(k), 1, 'first');
    if ~isempty(idx)
        manual1Out(idx) = manual1(k);
        manual2Out(idx) = manual2(k);
    end
end
end

function x = forceColumnOrNaN(x, n)
if isempty(x)
    x = nan(n,1);
else
    x = x(:);
    if numel(x) ~= n
        error('Manual vector length mismatch: expected %d values, got %d.', n, numel(x))
    end
end
end

function x = roundN(x, n)
x = double(x);
m = isfinite(x);
s = 10^n;
x(m) = round(x(m) * s) / s;
end

function x = fixLen(x, n)
if isempty(x)
    x = nan(n,1);
    return
end

x = x(:);

if numel(x) ~= n
    error('Vector length mismatch: expected %d values, got %d.', n, numel(x))
end
end

function v = readVarSafe(f, n)
try
    v = squeeze(ncread(f, n));
catch
    v = [];
end
end

function t = readTimeVarSafe(f, n)
x = readVarSafe(f, n);
if isempty(x)
    t = datetime.empty(0,1);
    return
end

t = datetime(1970,1,1,0,0,0,'TimeZone','UTC') + days(double(x(:)));
end

function val = readGlobalAttributeSafe(info, name)
val = "";

for k = 1:numel(info.Attributes)
    if strcmp(info.Attributes(k).Name, name)
        raw = info.Attributes(k).Value;
        if isstring(raw)
            val = raw;
        elseif ischar(raw)
            val = string(raw);
        else
            val = string(raw);
        end
        return
    end
end
end

function id = extractBuoyIdFromFilename(f)
tokens = regexp(f, '([A-Za-z0-9]+)_processed\.nc$', 'tokens', 'once');
if isempty(tokens)
    [~, n] = fileparts(f);
    id = string(n);
else
    id = string(tokens{1});
end
end

function id = normalizeBuoyId(id)
id = string(id);
if startsWith(id, "2025")
    return
end
if startsWith(id, "T")
    id = "2025" + id;
end
end

function [lat, lon, flag] = interpolateGeo(t, lat0, lon0, flag0, t2)
lat = interpTimeSeries(t, lat0, t2, 'linear');
lon = interpTimeSeries(t, lon0, t2, 'linear');
flag = interpTimeSeries(t, flag0, t2, 'nearest');
end

function [lat, lon] = interpolateRaw(t, lat0, lon0, t2)
lat = interpTimeSeries(t, lat0, t2, 'linear');
lon = interpTimeSeries(t, lon0, t2, 'linear');
end

function y = interpTimeSeries(t, x, t2, mode)
if nargin < 4
    mode = 'linear';
end

if isempty(t2)
    y = nan(0,1);
    return
end

if isempty(t) || isempty(x)
    y = nan(numel(t2),1);
    return
end

t = t(:);
x = double(x(:));
t2 = t2(:);

good = ~isnat(t) & isfinite(x);

if nnz(good) == 0
    y = nan(numel(t2),1);
    return
elseif nnz(good) == 1
    y = repmat(x(good), numel(t2), 1);
    return
end

y = interp1(posixtime(t(good)), x(good), posixtime(t2), mode, 'extrap');
y = y(:);
end