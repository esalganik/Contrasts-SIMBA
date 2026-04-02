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

dataDir = fullfile(scriptDir, 'Data');
pickDir = fullfile(scriptDir, 'Interfaces');
outDir = fullfile(scriptDir, 'Export');

if ~isfolder(outDir)
    mkdir(outDir);
end

if ~isfolder(dataDir)
    error('Data folder not found: %s', dataDir)
end

if ~isfolder(pickDir)
    error('Interfaces folder not found: %s', pickDir)
end

dz = 0.02;

nDeep = 6;
deepTempRange = [-2.5 -0.3];
useMedianDeepQC = true;

nMid = 5;
midTempRange = [-15 2];
useMedianMidQC = true;

bottomHeatingThreshold = 0.1;

geoCfg = struct();
geoCfg.maxSpeed_km_per_hr = 2;
geoCfg.maxInterpGap_hours = 24;
geoCfg.minValidLatitude = -90;
geoCfg.maxValidLatitude = 90;
geoCfg.minValidLongitude = -180;
geoCfg.maxValidLongitude = 180;

cfg = struct([]);

cfg(1).id            = 'T143';
cfg(1).titleText     = 'Floe 1, 2025T143';
cfg(1).project_T     = fullfile(dataDir, '2025T143_data', '2025T143_300534063689460_TEMP_raw+filterflag.csv');
cfg(1).project_dT    = fullfile(dataDir, '2025T143_data', '2025T143_300534063689460_HEAT030_raw+filterflag.csv');
cfg(1).project_dT120 = fullfile(dataDir, '2025T143_data', '2025T143_300534063689460_HEAT120_raw+filterflag.csv');
cfg(1).sensor        = [22 24];
cfg(1).fb            = [0.85 NaN];
cfg(1).hi            = [2.85 NaN];
cfg(1).t_man         = [ ...
    datenum('12.07.2025','dd.mm.yyyy'), ...
    datenum('28.07.2025','dd.mm.yyyy')];
cfg(1).t_man_format  = 'datenum';
cfg(1).crop          = 79;
cfg(1).crop_heat     = 19;
cfg(1).crop_heat120  = 19;

cfg(2).id            = 'T144';
cfg(2).titleText     = 'Floe 2, 2025T144';
cfg(2).project_T     = fullfile(dataDir, '2025T144_data', '2025T144_300534063685440_TEMP_raw+filterflag.csv');
cfg(2).project_dT    = fullfile(dataDir, '2025T144_data', '2025T144_300534063685440_HEAT030_raw+filterflag.csv');
cfg(2).project_dT120 = fullfile(dataDir, '2025T144_data', '2025T144_300534063685440_HEAT120_raw+filterflag.csv');
cfg(2).sensor        = [13 42];
cfg(2).fb            = [0.80 NaN];
cfg(2).hi            = [3.40 NaN];
cfg(2).t_man         = [ ...
    datenum('16.07.2025','dd.mm.yyyy'), ...
    datenum('13.08.2025','dd.mm.yyyy')];
cfg(2).t_man_format  = 'datenum';
cfg(2).crop          = 26;
cfg(2).crop_heat     = 7;
cfg(2).crop_heat120  = 7;

cfg(3).id            = 'T145';
cfg(3).titleText     = 'Floe 3, 2025T145';
cfg(3).project_T     = fullfile(dataDir, '2025T145_data', '2025T145_300534063486580_TEMP_raw+filterflag.csv');
cfg(3).project_dT    = fullfile(dataDir, '2025T145_data', '2025T145_300534063486580_HEAT030_raw+filterflag.csv');
cfg(3).project_dT120 = fullfile(dataDir, '2025T145_data', '2025T145_300534063486580_HEAT120_raw+filterflag.csv');
cfg(3).sensor        = [4 25 23];
cfg(3).fb            = [0.82 NaN NaN];
cfg(3).hi            = [3.23 NaN NaN];
cfg(3).t_man         = [ ...
    datenum('21.07.2025','dd.mm.yyyy'), ...
    datenum('18.08.2025','dd.mm.yyyy'), ...
    datenum('27.08.2025','dd.mm.yyyy')];
cfg(3).t_man_format  = 'datenum';
cfg(3).crop          = 0;
cfg(3).crop_heat     = 1;
cfg(3).crop_heat120  = 1;

cfg(4).id            = 'T135';
cfg(4).titleText     = 'Floe 2, 2025T135';
cfg(4).project_T     = fullfile(dataDir, '2025T135_data', '2025T135_300234068705280_TEMP_raw+filterflag.csv');
cfg(4).project_dT    = fullfile(dataDir, '2025T135_data', '2025T135_300234068705280_HEAT030_raw+filterflag.csv');
cfg(4).project_dT120 = fullfile(dataDir, '2025T135_data', '2025T135_300234068705280_HEAT120_raw+filterflag.csv');
cfg(4).sensor        = [37 41 38];
cfg(4).fb            = [0.17 0.16 0.11];
cfg(4).hi            = [1.97 1.59 1.21];
cfg(4).t_man         = [1 48 76];
cfg(4).crop          = 10;
cfg(4).crop_heat     = 0;
cfg(4).crop_heat120  = 0;

cfg(5).id            = 'T136';
cfg(5).titleText     = 'Floe 3, 2025T136';
cfg(5).project_T     = fullfile(dataDir, '2025T136_data', '2025T136_300534064067300_TEMP_raw+filterflag.csv');
cfg(5).project_dT    = fullfile(dataDir, '2025T136_data', '2025T136_300534064067300_HEAT030_raw+filterflag.csv');
cfg(5).project_dT120 = fullfile(dataDir, '2025T136_data', '2025T136_300534064067300_HEAT120_raw+filterflag.csv');
cfg(5).sensor        = [31 36];
cfg(5).fb            = [0.34 0.26];
cfg(5).hi            = [2.09 1.82];
cfg(5).t_man         = [1 36];
cfg(5).crop          = 5;
cfg(5).crop_heat     = 0;
cfg(5).crop_heat120  = 0;

for i = 1:numel(cfg)
    C = cfg(i);

    mustExistFile(C.project_T, 'temperature file');
    mustExistFile(C.project_dT, 'HEAT030 file');
    mustExistFile(C.project_dT120, 'HEAT120 file');

    fprintf('Processing %s...\n', C.id);

    [t, latT_raw, lonT_raw, T] = readCsvWithGeo(C.project_T);
    [tH, latH, lonH, H] = readCsvWithGeo(C.project_dT);
    [tH120, latH120, lonH120, H120] = readCsvWithGeo(C.project_dT120);

    [t, latT_raw, lonT_raw, T, latT, lonT, geoFlagT] = ...
        cleanTemperatureGeoKeepRaw(t, latT_raw, lonT_raw, T, geoCfg);

    [t, latT_raw, lonT_raw, T, latT, lonT, geoFlagT] = ...
        cropSeriesWithFlagAndRaw(t, latT_raw, lonT_raw, T, latT, lonT, geoFlagT, C.crop, 'temperature', C.id);

    [tH, latH, lonH, H] = cropSeries(tH, latH, lonH, H, C.crop_heat, 'HEAT030', C.id);
    [tH120, latH120, lonH120, H120] = cropSeries(tH120, latH120, lonH120, H120, C.crop_heat120, 'HEAT120', C.id);

    if strcmp(C.id, 'T135')
        tFail = 93;
        refSensor = 99;

        if size(T,2) > refSensor && size(T,1) >= tFail
            T(tFail:end, refSensor+1:end) = repmat(T(tFail:end, refSensor), 1, size(T,2)-refSensor);
        end

        if numel(t) >= tFail
            tFailDate = t(tFail);

            if ~isempty(tH) && size(H,2) > refSensor
                [~, iFailH] = min(abs(tH - tFailDate));
                H(iFailH:end, refSensor+1:end) = repmat(H(iFailH:end, refSensor), 1, size(H,2)-refSensor);
            end

            if ~isempty(tH120) && size(H120,2) > refSensor
                [~, iFailH120] = min(abs(tH120 - tFailDate));
                H120(iFailH120:end, refSensor+1:end) = repmat(H120(iFailH120:end, refSensor), 1, size(H120,2)-refSensor);
            end
        end
    end

    badExtreme = any(T < -40, 2);
    goodProfile = true(size(T,1),1);

    for it = 1:size(T,1)
        Ti = T(it,:);
        goodIdx = find(isfinite(Ti));

        if numel(goodIdx) < max(nDeep, nMid)
            goodProfile(it) = false;
            continue
        end

        idxDeep = goodIdx(max(1, end-nDeep+1):end);
        Tdeep = Ti(idxDeep);

        if useMedianDeepQC
            TdeepMetric = median(Tdeep, 'omitnan');
            passDeep = isfinite(TdeepMetric) && ...
                TdeepMetric >= deepTempRange(1) && ...
                TdeepMetric <= deepTempRange(2);
        else
            passDeep = ~any(Tdeep < deepTempRange(1) | Tdeep > deepTempRange(2));
        end

        nGood = numel(goodIdx);
        midCenter = round((nGood + 1)/2);
        midStart = max(1, midCenter - floor(nMid/2));
        midEnd = min(nGood, midStart + nMid - 1);
        midStart = max(1, midEnd - nMid + 1);

        idxMid = goodIdx(midStart:midEnd);
        Tmid = Ti(idxMid);

        if useMedianMidQC
            TmidMetric = median(Tmid, 'omitnan');
            passMid = isfinite(TmidMetric) && ...
                TmidMetric >= midTempRange(1) && ...
                TmidMetric <= midTempRange(2);
        else
            passMid = ~any(Tmid < midTempRange(1) | Tmid > midTempRange(2));
        end

        goodProfile(it) = passDeep && passMid && ~badExtreme(it);
    end

    T = T(goodProfile,:);
    t = t(goodProfile);
    latT_raw = latT_raw(goodProfile);
    lonT_raw = lonT_raw(goodProfile);
    latT = latT(goodProfile);
    lonT = lonT(goodProfile);
    geoFlagT = geoFlagT(goodProfile);

    if isempty(t)
        warning('No valid temperature profiles remain after QC for %s. Skipping export.', C.id)
        continue
    end

    if ~isempty(H)
        Hbottom = H(:,end);
        goodH = isfinite(Hbottom) & (Hbottom >= bottomHeatingThreshold);
        H = H(goodH,:);
        tH = tH(goodH);
        latH = latH(goodH);
        lonH = lonH(goodH);
    end

    if ~isempty(H120)
        Hbottom120 = H120(:,end);
        goodH120 = isfinite(Hbottom120) & (Hbottom120 >= bottomHeatingThreshold);
        H120 = H120(goodH120,:);
        tH120 = tH120(goodH120);
        latH120 = latH120(goodH120);
        lonH120 = lonH120(goodH120);
    end

    z = 0:dz:dz*(size(T,2)-1);
    z = z - dz*C.sensor(1) - C.fb(1);
    depth = z(:);

    xT = datenum(t);
    xH = datenum(tH);
    xH120 = datenum(tH120);

    [xManual, manualSurface, manualBottom] = resolveManualInterfaces(C, xT, dz);
    manualTime = datenumToDatetime(xManual);

    bottomPickFile = findLatestPickFile(pickDir, C.id, 'bottom');
    surfacePickFile = findLatestPickFile(pickDir, C.id, 'surface');

    if isempty(bottomPickFile)
        error('No bottom pick file found for %s in %s', C.id, pickDir);
    end

    if isempty(surfacePickFile)
        error('No surface pick file found for %s in %s', C.id, pickDir);
    end

    Sbottom = load(bottomPickFile);
    Ssurface = load(surfacePickFile);

    [xBottom, yBottom] = sanitizePickedPoints(Sbottom.xClick, Sbottom.yClick);
    [xSurface, ySurface] = sanitizePickedPoints(Ssurface.xClick, Ssurface.yClick);

    if numel(xBottom) < 2
        error('Bottom picks for %s must contain at least 2 unique time points after cleaning.', C.id)
    end

    if numel(xSurface) < 2
        error('Surface picks for %s must contain at least 2 unique time points after cleaning.', C.id)
    end

    iceWater_T = interp1(xBottom, yBottom, xT, 'linear', 'extrap');
    airSnow_T = interp1(xSurface, ySurface, xT, 'linear', 'extrap');
    snowIce_T = makeSnowIceInterface(airSnow_T);

    if isempty(xH)
        iceWater_H = [];
        airSnow_H = [];
        snowIce_H = [];
    else
        iceWater_H = interp1(xBottom, yBottom, xH, 'linear', 'extrap');
        airSnow_H = interp1(xSurface, ySurface, xH, 'linear', 'extrap');
        snowIce_H = makeSnowIceInterface(airSnow_H);
    end

    if isempty(xH120)
        iceWater_H120 = [];
        airSnow_H120 = [];
        snowIce_H120 = [];
    else
        iceWater_H120 = interp1(xBottom, yBottom, xH120, 'linear', 'extrap');
        airSnow_H120 = interp1(xSurface, ySurface, xH120, 'linear', 'extrap');
        snowIce_H120 = makeSnowIceInterface(airSnow_H120);
    end

    outFile = fullfile(outDir, sprintf('%s_processed.nc', C.id));
    if isfile(outFile)
        delete(outFile);
    end

    writeBuoyNetCDF(outFile, C, ...
        t, latT_raw, lonT_raw, latT, lonT, geoFlagT, T, ...
        tH, H, ...
        tH120, H120, ...
        depth, ...
        airSnow_T, snowIce_T, iceWater_T, ...
        airSnow_H, snowIce_H, iceWater_H, ...
        airSnow_H120, snowIce_H120, iceWater_H120, ...
        manualTime, manualSurface, manualBottom);

    fprintf('Wrote %s\n', outFile);
end

function mustExistFile(fp, labelText)
if ~isfile(fp)
    error('Missing %s: %s', labelText, fp)
end
end

function [t, lat, lon, data] = readCsvWithGeo(filePath)
tbl = readtable(filePath, 'NumHeaderLines', 1);

t = table2array(tbl(:,1));
lat = table2array(tbl(:,2));
lon = table2array(tbl(:,3));
data = table2array(tbl(:,5:end));

if iscell(t)
    t = string(t);
end
if isstring(t) || ischar(t)
    t = datetime(t);
end

t = t(:);
t.TimeZone = 'UTC';

lat = double(lat(:));
lon = double(lon(:));
end
%%
function [tOut, latRawOut, lonRawOut, dataOut, latCorrOut, lonCorrOut, geoFlag] = ...
    cleanTemperatureGeoKeepRaw(tIn, latIn, lonIn, dataIn, geoCfg)

tOut = tIn(:);
latRawOut = double(latIn(:));
lonRawOut = double(lonIn(:));
dataOut = dataIn;

if isempty(tOut)
    latCorrOut = latRawOut;
    lonCorrOut = lonRawOut;
    geoFlag = zeros(0,1,'int8');
    return
end

if isempty(tOut.TimeZone)
    tOut.TimeZone = 'UTC';
end

% -------------------------------------------------------------------------
% 1) Drop invalid time rows
% -------------------------------------------------------------------------
goodTime = ~isnat(tOut);
tOut = tOut(goodTime);
latRawOut = latRawOut(goodTime);
lonRawOut = lonRawOut(goodTime);
dataOut = dataOut(goodTime,:);

if isempty(tOut)
    latCorrOut = [];
    lonCorrOut = [];
    geoFlag = zeros(0,1,'int8');
    return
end

% -------------------------------------------------------------------------
% 2) Sort by time
% -------------------------------------------------------------------------
[tOut, isrt] = sort(tOut);
latRawOut = latRawOut(isrt);
lonRawOut = lonRawOut(isrt);
dataOut = dataOut(isrt,:);

% -------------------------------------------------------------------------
% 3) Merge duplicate times by keeping the median position
% -------------------------------------------------------------------------
[xu, ~, iu] = unique(posixtime(tOut), 'stable');
nU = numel(xu);

tKeep = NaT(nU,1,'TimeZone','UTC');
latKeep = nan(nU,1);
lonKeep = nan(nU,1);
rowKeep = nan(nU,1);

for k = 1:nU
    idx = find(iu == k);
    tKeep(k) = tOut(idx(1));

    latBlock = latRawOut(idx);
    lonBlock = wrapTo180Local(lonRawOut(idx));

    latKeep(k) = median(latBlock, 'omitnan');

    lonRad = deg2rad(lonBlock);
    lonKeep(k) = wrapTo180Local(rad2deg(angle(mean(exp(1i * lonRad), 'omitnan'))));

    rowKeep(k) = idx(1);
end

tOut = tKeep;
latRawOut = latKeep;
lonRawOut = lonKeep;
dataOut = dataOut(rowKeep,:);

% Keep raw longitude consistent for export/plotting
lonRawOut = wrapTo180Local(lonRawOut);

latCorrOut = latRawOut;
lonCorrOut = lonRawOut;

n = numel(tOut);
geoFlag = ones(n,1,'int8');  % 1 = observed QC-passed, 2 = interpolated, 3 = invalid/removed

% -------------------------------------------------------------------------
% 4) Hard validity screening
% -------------------------------------------------------------------------
validGeo = isfinite(latCorrOut) & isfinite(lonCorrOut) & ...
           latCorrOut >= geoCfg.minValidLatitude & latCorrOut <= geoCfg.maxValidLatitude & ...
           lonCorrOut >= geoCfg.minValidLongitude & lonCorrOut <= geoCfg.maxValidLongitude;

latCorrOut(~validGeo) = NaN;
lonCorrOut(~validGeo) = NaN;
geoFlag(~validGeo) = int8(3);

% -------------------------------------------------------------------------
% 5) Point-to-point speed filter
% Remove points involved in implausible motion
% -------------------------------------------------------------------------
good = isfinite(latCorrOut) & isfinite(lonCorrOut);

if nnz(good) >= 2
    idx = find(good);

    for j = 2:numel(idx)
        i1 = idx(j-1);
        i2 = idx(j);

        dtHr = hours(tOut(i2) - tOut(i1));
        if dtHr <= 0
            latCorrOut(i2) = NaN;
            lonCorrOut(i2) = NaN;
            geoFlag(i2) = int8(3);
            continue
        end

        dKm = gcDistanceKm(latCorrOut(i1), lonCorrOut(i1), latCorrOut(i2), lonCorrOut(i2));
        v = dKm / dtHr;

        if v > geoCfg.maxSpeed_km_per_hr
            latCorrOut(i2) = NaN;
            lonCorrOut(i2) = NaN;
            geoFlag(i2) = int8(3);
        end
    end
end

% -------------------------------------------------------------------------
% 6) Isolated 3-point spike filter
% -------------------------------------------------------------------------
for k = 2:n-1
    if ~isfinite(latCorrOut(k-1)) || ~isfinite(lonCorrOut(k-1)) || ...
       ~isfinite(latCorrOut(k))   || ~isfinite(lonCorrOut(k))   || ...
       ~isfinite(latCorrOut(k+1)) || ~isfinite(lonCorrOut(k+1))
        continue
    end

    dt1 = hours(tOut(k) - tOut(k-1));
    dt2 = hours(tOut(k+1) - tOut(k));

    if dt1 <= 0 || dt2 <= 0
        latCorrOut(k) = NaN;
        lonCorrOut(k) = NaN;
        geoFlag(k) = int8(3);
        continue
    end

    d1 = gcDistanceKm(latCorrOut(k-1), lonCorrOut(k-1), latCorrOut(k),   lonCorrOut(k));
    d2 = gcDistanceKm(latCorrOut(k),   lonCorrOut(k),   latCorrOut(k+1), lonCorrOut(k+1));
    d13 = gcDistanceKm(latCorrOut(k-1), lonCorrOut(k-1), latCorrOut(k+1), lonCorrOut(k+1));

    v1 = d1 / dt1;
    v2 = d2 / dt2;
    v13 = d13 / hours(tOut(k+1) - tOut(k-1));

    if v1 > geoCfg.maxSpeed_km_per_hr && ...
       v2 > geoCfg.maxSpeed_km_per_hr && ...
       v13 < geoCfg.maxSpeed_km_per_hr
        latCorrOut(k) = NaN;
        lonCorrOut(k) = NaN;
        geoFlag(k) = int8(3);
    end
end

% -------------------------------------------------------------------------
% 7) Moving-median deviation filter
% Removes local GPS wander/jitter that survives speed QC
% -------------------------------------------------------------------------
good = isfinite(latCorrOut) & isfinite(lonCorrOut);

if nnz(good) >= 5
    latMed = latCorrOut;
    lonMed = lonCorrOut;

    latMed(good) = movmedian(latCorrOut(good), 5, 'omitnan');

    lonUnw = rad2deg(unwrap(deg2rad(lonCorrOut(good))));
    lonMedUnw = movmedian(lonUnw, 5, 'omitnan');
    lonMed(good) = wrapTo180Local(lonMedUnw);

    devKm = nan(n,1);
    gidx = find(good);

    for j = 1:numel(gidx)
        k = gidx(j);
        devKm(k) = gcDistanceKm(latCorrOut(k), lonCorrOut(k), latMed(k), lonMed(k));
    end

    % Tune this threshold if needed
    maxDevKm = 1.5;

    badDev = devKm > maxDevKm;
    latCorrOut(badDev) = NaN;
    lonCorrOut(badDev) = NaN;
    geoFlag(badDev) = int8(3);
end

% -------------------------------------------------------------------------
% 8) Interpolate only short gaps
% -------------------------------------------------------------------------
good = isfinite(latCorrOut) & isfinite(lonCorrOut);

if nnz(good) >= 2 && geoCfg.maxInterpGap_hours > 0
    xAll = posixtime(tOut);
    xGood = xAll(good);

    latInterp = interp1(xGood, latCorrOut(good), xAll, 'linear', NaN);

    lonUnw = rad2deg(unwrap(deg2rad(lonCorrOut(good))));
    lonInterpUnw = interp1(xGood, lonUnw, xAll, 'linear', NaN);
    lonInterp = wrapTo180Local(lonInterpUnw);

    gidx = find(good);

    prevGood = nan(n,1);
    nextGood = nan(n,1);

    last = NaN;
    for k = 1:n
        if ismember(k, gidx)
            last = k;
        end
        prevGood(k) = last;
    end

    last = NaN;
    for k = n:-1:1
        if ismember(k, gidx)
            last = k;
        end
        nextGood(k) = last;
    end

    for k = 1:n
        if good(k)
            continue
        end

        ip = prevGood(k);
        in = nextGood(k);

        if isfinite(ip) && isfinite(in) && ip ~= in
            gapHours = hours(tOut(in) - tOut(ip));

            if gapHours <= geoCfg.maxInterpGap_hours
                latCorrOut(k) = latInterp(k);
                lonCorrOut(k) = lonInterp(k);
                geoFlag(k) = int8(2);
            end
        end
    end
end

% -------------------------------------------------------------------------
% 9) Optional light smoothing on final accepted/interpolated track
% Only smooth finite points, keep gaps as NaN
% -------------------------------------------------------------------------
good = isfinite(latCorrOut) & isfinite(lonCorrOut);

if nnz(good) >= 3
    latSmooth = latCorrOut;
    lonSmooth = lonCorrOut;

    latSmooth(good) = movmean(latCorrOut(good), 3, 'omitnan');

    lonUnw = rad2deg(unwrap(deg2rad(lonCorrOut(good))));
    lonSmoothUnw = movmean(lonUnw, 3, 'omitnan');
    lonSmooth(good) = wrapTo180Local(lonSmoothUnw);

    latCorrOut = latSmooth;
    lonCorrOut = lonSmooth;
end

% -------------------------------------------------------------------------
% 10) Edge completion to guarantee corrected position at all timestamps
% Fill leading/trailing missing corrected positions by linear extrapolation
% from the nearest valid corrected points. Do not refill internal gaps.
% -------------------------------------------------------------------------
goodCorr = isfinite(latCorrOut) & isfinite(lonCorrOut);

if any(goodCorr)
    iGood = find(goodCorr);
    iFirst = iGood(1);
    iLast  = iGood(end);

    xAll = posixtime(tOut);

    % --- Leading gap: extrapolate backward from first valid corrected points
    if iFirst > 1
        if numel(iGood) >= 2
            j1 = iGood(1);
            j2 = iGood(2);

            if xAll(j2) ~= xAll(j1)
                latLead = interp1(xAll([j1 j2]), latCorrOut([j1 j2]), xAll(1:j1-1), 'linear', 'extrap');

                lon12 = rad2deg(unwrap(deg2rad(lonCorrOut([j1 j2]))));
                lonLeadUnw = interp1(xAll([j1 j2]), lon12, xAll(1:j1-1), 'linear', 'extrap');
                lonLead = wrapTo180Local(lonLeadUnw);
            else
                latLead = repmat(latCorrOut(j1), j1-1, 1);
                lonLead = repmat(lonCorrOut(j1), j1-1, 1);
            end
        else
            latLead = repmat(latCorrOut(iFirst), iFirst-1, 1);
            lonLead = repmat(lonCorrOut(iFirst), iFirst-1, 1);
        end

        latCorrOut(1:iFirst-1) = latLead(:);
        lonCorrOut(1:iFirst-1) = lonLead(:);
        geoFlag(1:iFirst-1) = int8(4);
    end

    % --- Trailing gap: extrapolate forward from last valid corrected points
    if iLast < n
        if numel(iGood) >= 2
            j1 = iGood(end-1);
            j2 = iGood(end);

            if xAll(j2) ~= xAll(j1)
                latTail = interp1(xAll([j1 j2]), latCorrOut([j1 j2]), xAll(j2+1:end), 'linear', 'extrap');

                lon12 = rad2deg(unwrap(deg2rad(lonCorrOut([j1 j2]))));
                lonTailUnw = interp1(xAll([j1 j2]), lon12, xAll(j2+1:end), 'linear', 'extrap');
                lonTail = wrapTo180Local(lonTailUnw);
            else
                latTail = repmat(latCorrOut(j2), n-j2, 1);
                lonTail = repmat(lonCorrOut(j2), n-j2, 1);
            end
        else
            latTail = repmat(latCorrOut(iLast), n-iLast, 1);
            lonTail = repmat(lonCorrOut(iLast), n-iLast, 1);
        end

        latCorrOut(iLast+1:end) = latTail(:);
        lonCorrOut(iLast+1:end) = lonTail(:);
        geoFlag(iLast+1:end) = int8(4);
    end

else
    % Fallback only if no corrected point exists at all
    rawUsable = isfinite(latRawOut) & isfinite(lonRawOut) & ...
                latRawOut >= geoCfg.minValidLatitude & latRawOut <= geoCfg.maxValidLatitude & ...
                lonRawOut >= geoCfg.minValidLongitude & lonRawOut <= geoCfg.maxValidLongitude;

    i0 = find(rawUsable, 1, 'first');
    if ~isempty(i0)
        latCorrOut(:) = latRawOut(i0);
        lonCorrOut(:) = lonRawOut(i0);
        geoFlag(:) = int8(4);
    end
end

lonCorrOut = wrapTo180Local(lonCorrOut);

end

function dkm = gcDistanceKm(lat1, lon1, lat2, lon2)
R = 6371.0;

lat1 = deg2rad(lat1);
lon1 = deg2rad(lon1);
lat2 = deg2rad(lat2);
lon2 = deg2rad(lon2);

dlat = lat2 - lat1;
dlon = lon2 - lon1;

a = sin(dlat./2).^2 + cos(lat1).*cos(lat2).*sin(dlon./2).^2;
c = 2 .* atan2(sqrt(a), sqrt(max(0, 1-a)));
dkm = R .* c;
end

function lon = wrapTo180Local(lon)
lon = mod(lon + 180, 360) - 180;
end

function [t, latRaw, lonRaw, data, latCorr, lonCorr, geoFlag] = ...
    cropSeriesWithFlagAndRaw(t, latRaw, lonRaw, data, latCorr, lonCorr, geoFlag, cropCount, labelText, buoyID)

if nargin < 9
    labelText = 'data';
end
if nargin < 10
    buoyID = '';
end

if isempty(cropCount) || cropCount <= 0
    return
end

if cropCount >= size(data,1)
    error('%s: crop value %d is too large for %s (%d rows).', buoyID, cropCount, labelText, size(data,1));
end

keep = 1:(numel(t) - cropCount);

t = t(keep);
latRaw = latRaw(keep);
lonRaw = lonRaw(keep);
data = data(keep,:);
latCorr = latCorr(keep);
lonCorr = lonCorr(keep);
geoFlag = geoFlag(keep);
end

function [t, lat, lon, data] = cropSeries(t, lat, lon, data, cropCount, labelText, buoyID)
if nargin < 6
    labelText = 'data';
end
if nargin < 7
    buoyID = '';
end

if isempty(cropCount) || cropCount <= 0
    return
end

if cropCount >= size(data,1)
    error('%s: crop value %d is too large for %s (%d rows).', buoyID, cropCount, labelText, size(data,1));
end

data = data(1:end-cropCount,:);
t = t(1:end-cropCount);
lat = lat(1:end-cropCount);
lon = lon(1:end-cropCount);
end

function [xClean, yClean] = sanitizePickedPoints(xIn, yIn)
xIn = xIn(:);
yIn = yIn(:);

good = isfinite(xIn) & isfinite(yIn);
xIn = xIn(good);
yIn = yIn(good);

if isempty(xIn)
    xClean = xIn;
    yClean = yIn;
    return
end

[xSorted, order] = sort(xIn);
ySorted = yIn(order);

[xClean, ~, groupIdx] = unique(xSorted, 'stable');
yClean = accumarray(groupIdx, ySorted, [], @mean);
end

function latestFile = findLatestPickFile(pickDir, buoyID, interfaceName)
files = dir(fullfile(pickDir, sprintf('%s_*_%s_points.mat', buoyID, interfaceName)));

if isempty(files)
    latestFile = '';
    return
end

bestScore = -inf;
latestFile = '';

for k = 1:numel(files)
    thisFile = fullfile(files(k).folder, files(k).name);
    score = files(k).datenum;

    try
        S = load(thisFile, 'pickedOn');
        if isfield(S, 'pickedOn') && ~isempty(S.pickedOn)
            tPicked = datenum(S.pickedOn);
            if isfinite(tPicked)
                score = tPicked;
            end
        end
    catch
    end

    if score > bestScore
        bestScore = score;
        latestFile = thisFile;
    end
end
end

function snowIce = makeSnowIceInterface(airSnow)
snowIce = airSnow(:);

good = find(isfinite(snowIce));
if isempty(good)
    return
end

[~, relIdx] = max(snowIce(good));
iMax = good(relIdx);

for k = iMax+1:numel(snowIce)
    if ~isfinite(snowIce(k))
        snowIce(k) = snowIce(k-1);
    else
        snowIce(k) = max(snowIce(k), snowIce(k-1));
    end
end
end

function outDays = timeToEpochDays(t)
t = t(:);
if isempty(t)
    outDays = [];
    return
end

if isempty(t.TimeZone)
    t.TimeZone = 'UTC';
end

outDays = posixtime(t) ./ 86400;
outDays = double(outDays(:));
end

function [xManual, manualSurface, manualBottom] = resolveManualInterfaces(C, xT, dz)
xManual = resolveManualTimes(C, xT);
manualSurface = nan(size(xManual));
manualBottom = nan(size(xManual));

hasSensor = isfield(C, 'sensor') && ~isempty(C.sensor);
hasFb0 = isfield(C, 'fb') && ~isempty(C.fb) && isfinite(C.fb(1));
hasHi = isfield(C, 'hi') && ~isempty(C.hi);

if ~hasSensor || ~hasFb0 || isempty(xManual)
    return
end

n = min([numel(C.sensor), numel(xManual)]);

for k = 1:n
    if ~isfinite(xManual(k))
        continue
    end

    yUpper = (C.sensor(k) - C.sensor(1)) * dz - C.fb(1);
    manualSurface(k) = yUpper;

    if hasHi && k <= numel(C.hi) && isfinite(C.hi(k))
        manualBottom(k) = yUpper + C.hi(k);
    end
end
end

function xManual = resolveManualTimes(C, xT)
if ~isfield(C, 't_man') || isempty(C.t_man)
    xManual = [];
    return
end

tMan = C.t_man;

fmt = "index";
if isfield(C, 't_man_format') && ~isempty(C.t_man_format)
    fmt = lower(string(C.t_man_format));
end

switch fmt
    case "index"
        idx = round(tMan);
        if any(idx < 1 | idx > numel(xT))
            error('t_man index out of range for %s.', C.id)
        end
        xManual = xT(idx);

    case "datenum"
        tMan = tMan(:).';
        xManual = nan(size(tMan));

        for k = 1:numel(tMan)
            [dtMin, idx] = min(abs(xT - tMan(k)));

            if isempty(idx) || ~isfinite(dtMin)
                xManual(k) = NaN;
            else
                xManual(k) = xT(idx);
            end
        end

    otherwise
        error('Unsupported t_man_format for %s. Use ''index'' or ''datenum''.', C.id)
end
end

function t = datenumToDatetime(x)
if isempty(x)
    t = datetime.empty(0,1);
else
    t = datetime(x, 'ConvertFrom', 'datenum', 'TimeZone', 'UTC');
end
end

function writeBuoyNetCDF(outFile, C, ...
    t, latT_raw, lonT_raw, latT, lonT, geoFlagT, T, ...
    tH, H, ...
    tH120, H120, ...
    depth, ...
    airSnow_T, snowIce_T, iceWater_T, ...
    airSnow_H, snowIce_H, iceWater_H, ...
    airSnow_H120, snowIce_H120, iceWater_H120, ...
    manualTime, manualSurface, manualBottom)

nT = numel(t);
nH = numel(tH);
nH120 = numel(tH120);
nZ = numel(depth);
nM = numel(manualTime);

timeT = timeToEpochDays(t);
timeH = timeToEpochDays(tH);
timeH120 = timeToEpochDays(tH120);
timeM = timeToEpochDays(manualTime);

nccreate(outFile, 'depth', 'Dimensions', {'depth', nZ}, 'Datatype', 'double');
ncwrite(outFile, 'depth', double(depth(:)));
ncwriteatt(outFile, 'depth', 'standard_name', 'depth');
ncwriteatt(outFile, 'depth', 'long_name', 'sensor depth below water level');
ncwriteatt(outFile, 'depth', 'units', 'm');
ncwriteatt(outFile, 'depth', 'positive', 'down');
ncwriteatt(outFile, 'depth', 'axis', 'Z');

nccreate(outFile, 'time_temperature', 'Dimensions', {'time_temperature', nT}, 'Datatype', 'double');
ncwrite(outFile, 'time_temperature', timeT);
ncwriteatt(outFile, 'time_temperature', 'standard_name', 'time');
ncwriteatt(outFile, 'time_temperature', 'long_name', 'time for temperature data');
ncwriteatt(outFile, 'time_temperature', 'units', 'days since 1970-01-01 00:00:00 UTC');
ncwriteatt(outFile, 'time_temperature', 'calendar', 'standard');
ncwriteatt(outFile, 'time_temperature', 'axis', 'T');

nccreate(outFile, 'latitude_temperature_raw', 'Dimensions', {'time_temperature', nT}, 'Datatype', 'double');
ncwrite(outFile, 'latitude_temperature_raw', double(latT_raw(:)));
ncwriteatt(outFile, 'latitude_temperature_raw', 'standard_name', 'latitude');
ncwriteatt(outFile, 'latitude_temperature_raw', 'long_name', 'raw latitude of buoy on temperature time axis');
ncwriteatt(outFile, 'latitude_temperature_raw', 'units', 'degrees_north');

nccreate(outFile, 'longitude_temperature_raw', 'Dimensions', {'time_temperature', nT}, 'Datatype', 'double');
ncwrite(outFile, 'longitude_temperature_raw', double(lonT_raw(:)));
ncwriteatt(outFile, 'longitude_temperature_raw', 'standard_name', 'longitude');
ncwriteatt(outFile, 'longitude_temperature_raw', 'long_name', 'raw longitude of buoy on temperature time axis');
ncwriteatt(outFile, 'longitude_temperature_raw', 'units', 'degrees_east');

nccreate(outFile, 'latitude_temperature', 'Dimensions', {'time_temperature', nT}, 'Datatype', 'double');
ncwrite(outFile, 'latitude_temperature', double(latT(:)));
ncwriteatt(outFile, 'latitude_temperature', 'standard_name', 'latitude');
ncwriteatt(outFile, 'latitude_temperature', 'long_name', 'quality-controlled latitude of buoy on temperature time axis');
ncwriteatt(outFile, 'latitude_temperature', 'units', 'degrees_north');

nccreate(outFile, 'longitude_temperature', 'Dimensions', {'time_temperature', nT}, 'Datatype', 'double');
ncwrite(outFile, 'longitude_temperature', double(lonT(:)));
ncwriteatt(outFile, 'longitude_temperature', 'standard_name', 'longitude');
ncwriteatt(outFile, 'longitude_temperature', 'long_name', 'quality-controlled longitude of buoy on temperature time axis');
ncwriteatt(outFile, 'longitude_temperature', 'units', 'degrees_east');

nccreate(outFile, 'geolocation_flag_temperature', ...
    'Dimensions', {'time_temperature', nT}, ...
    'Datatype', 'int8');
ncwrite(outFile, 'geolocation_flag_temperature', int8(geoFlagT(:)));
ncwriteatt(outFile, 'geolocation_flag_temperature', 'long_name', 'geolocation source flag on temperature time axis');
ncwriteatt(outFile, 'geolocation_flag_temperature', 'flag_values', int8([1 2 3 4]));
ncwriteatt(outFile, 'geolocation_flag_temperature', 'flag_meanings', 'original interpolated invalid edge_extrapolated');
ncwriteatt(outFile, 'geolocation_flag_temperature', 'coordinates', 'time_temperature latitude_temperature longitude_temperature');

ncwriteatt(outFile, 'latitude_temperature', 'ancillary_variables', 'geolocation_flag_temperature');
ncwriteatt(outFile, 'longitude_temperature', 'ancillary_variables', 'geolocation_flag_temperature');

nccreate(outFile, 'temperature', ...
    'Dimensions', {'time_temperature', nT, 'depth', nZ}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'temperature', double(T));
ncwriteatt(outFile, 'temperature', 'long_name', 'SIMBA thermistor temperature');
ncwriteatt(outFile, 'temperature', 'units', 'degree_Celsius');
ncwriteatt(outFile, 'temperature', 'coordinates', 'time_temperature depth latitude_temperature longitude_temperature');

nccreate(outFile, 'air_snow_interface_temperature', ...
    'Dimensions', {'time_temperature', nT}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'air_snow_interface_temperature', double(airSnow_T(:)));
ncwriteatt(outFile, 'air_snow_interface_temperature', 'long_name', 'air-snow interface depth below water level on temperature time axis');
ncwriteatt(outFile, 'air_snow_interface_temperature', 'units', 'm');
ncwriteatt(outFile, 'air_snow_interface_temperature', 'positive', 'down');

nccreate(outFile, 'snow_ice_interface_temperature', ...
    'Dimensions', {'time_temperature', nT}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'snow_ice_interface_temperature', double(snowIce_T(:)));
ncwriteatt(outFile, 'snow_ice_interface_temperature', 'long_name', 'snow-ice interface depth below water level on temperature time axis');
ncwriteatt(outFile, 'snow_ice_interface_temperature', 'units', 'm');
ncwriteatt(outFile, 'snow_ice_interface_temperature', 'positive', 'down');

nccreate(outFile, 'ice_water_interface_temperature', ...
    'Dimensions', {'time_temperature', nT}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'ice_water_interface_temperature', double(iceWater_T(:)));
ncwriteatt(outFile, 'ice_water_interface_temperature', 'long_name', 'ice-water interface depth below water level on temperature time axis');
ncwriteatt(outFile, 'ice_water_interface_temperature', 'units', 'm');
ncwriteatt(outFile, 'ice_water_interface_temperature', 'positive', 'down');

snowThickness_T = double(snowIce_T(:) - airSnow_T(:));
iceThickness_T = double(iceWater_T(:) - snowIce_T(:));

nccreate(outFile, 'snow_thickness_temperature', ...
    'Dimensions', {'time_temperature', nT}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'snow_thickness_temperature', snowThickness_T);
ncwriteatt(outFile, 'snow_thickness_temperature', 'standard_name', 'surface_snow_thickness');
ncwriteatt(outFile, 'snow_thickness_temperature', 'long_name', 'snow thickness on temperature time axis');
ncwriteatt(outFile, 'snow_thickness_temperature', 'units', 'm');

nccreate(outFile, 'ice_thickness_temperature', ...
    'Dimensions', {'time_temperature', nT}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'ice_thickness_temperature', iceThickness_T);
ncwriteatt(outFile, 'ice_thickness_temperature', 'standard_name', 'sea_ice_thickness');
ncwriteatt(outFile, 'ice_thickness_temperature', 'long_name', 'ice thickness on temperature time axis');
ncwriteatt(outFile, 'ice_thickness_temperature', 'units', 'm');

if nM > 0
    nccreate(outFile, 'time_manual', 'Dimensions', {'time_manual', nM}, 'Datatype', 'double');
    ncwrite(outFile, 'time_manual', timeM);
    ncwriteatt(outFile, 'time_manual', 'standard_name', 'time');
    ncwriteatt(outFile, 'time_manual', 'long_name', 'time of manual interface measurements');
    ncwriteatt(outFile, 'time_manual', 'units', 'days since 1970-01-01 00:00:00 UTC');
    ncwriteatt(outFile, 'time_manual', 'calendar', 'standard');
    ncwriteatt(outFile, 'time_manual', 'axis', 'T');

    nccreate(outFile, 'manual_air_snow_interface_depth', ...
        'Dimensions', {'time_manual', nM}, ...
        'Datatype', 'double', ...
        'FillValue', NaN);
    ncwrite(outFile, 'manual_air_snow_interface_depth', double(manualSurface(:)));
    ncwriteatt(outFile, 'manual_air_snow_interface_depth', 'long_name', 'manual air-snow interface depth below water level');
    ncwriteatt(outFile, 'manual_air_snow_interface_depth', 'units', 'm');
    ncwriteatt(outFile, 'manual_air_snow_interface_depth', 'positive', 'down');

    nccreate(outFile, 'manual_ice_water_interface_depth', ...
        'Dimensions', {'time_manual', nM}, ...
        'Datatype', 'double', ...
        'FillValue', NaN);
    ncwrite(outFile, 'manual_ice_water_interface_depth', double(manualBottom(:)));
    ncwriteatt(outFile, 'manual_ice_water_interface_depth', 'long_name', 'manual ice-water interface depth below water level');
    ncwriteatt(outFile, 'manual_ice_water_interface_depth', 'units', 'm');
    ncwriteatt(outFile, 'manual_ice_water_interface_depth', 'positive', 'down');
end

nccreate(outFile, 'time_heating030', 'Dimensions', {'time_heating030', nH}, 'Datatype', 'double');
ncwrite(outFile, 'time_heating030', timeH);
ncwriteatt(outFile, 'time_heating030', 'standard_name', 'time');
ncwriteatt(outFile, 'time_heating030', 'long_name', 'time for 30 s heating data');
ncwriteatt(outFile, 'time_heating030', 'units', 'days since 1970-01-01 00:00:00 UTC');
ncwriteatt(outFile, 'time_heating030', 'calendar', 'standard');
ncwriteatt(outFile, 'time_heating030', 'axis', 'T');

nccreate(outFile, 'temperature_change_30s', ...
    'Dimensions', {'time_heating030', nH, 'depth', nZ}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'temperature_change_30s', double(H));
ncwriteatt(outFile, 'temperature_change_30s', 'long_name', 'temperature change measured by SIMBA 30 s heating cycle');
ncwriteatt(outFile, 'temperature_change_30s', 'units', 'degree_Celsius');
ncwriteatt(outFile, 'temperature_change_30s', 'coordinates', 'time_heating030 depth');

nccreate(outFile, 'air_snow_interface_heating030', ...
    'Dimensions', {'time_heating030', nH}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'air_snow_interface_heating030', double(airSnow_H(:)));
ncwriteatt(outFile, 'air_snow_interface_heating030', 'long_name', 'air-snow interface depth below water level on 30 s heating time axis');
ncwriteatt(outFile, 'air_snow_interface_heating030', 'units', 'm');
ncwriteatt(outFile, 'air_snow_interface_heating030', 'positive', 'down');

nccreate(outFile, 'snow_ice_interface_heating030', ...
    'Dimensions', {'time_heating030', nH}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'snow_ice_interface_heating030', double(snowIce_H(:)));
ncwriteatt(outFile, 'snow_ice_interface_heating030', 'long_name', 'snow-ice interface depth below water level on 30 s heating time axis');
ncwriteatt(outFile, 'snow_ice_interface_heating030', 'units', 'm');
ncwriteatt(outFile, 'snow_ice_interface_heating030', 'positive', 'down');

nccreate(outFile, 'ice_water_interface_heating030', ...
    'Dimensions', {'time_heating030', nH}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'ice_water_interface_heating030', double(iceWater_H(:)));
ncwriteatt(outFile, 'ice_water_interface_heating030', 'long_name', 'ice-water interface depth below water level on 30 s heating time axis');
ncwriteatt(outFile, 'ice_water_interface_heating030', 'units', 'm');
ncwriteatt(outFile, 'ice_water_interface_heating030', 'positive', 'down');

snowThickness_H = double(snowIce_H(:) - airSnow_H(:));
iceThickness_H = double(iceWater_H(:) - snowIce_H(:));

nccreate(outFile, 'snow_thickness_heating030', ...
    'Dimensions', {'time_heating030', nH}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'snow_thickness_heating030', snowThickness_H);
ncwriteatt(outFile, 'snow_thickness_heating030', 'standard_name', 'surface_snow_thickness');
ncwriteatt(outFile, 'snow_thickness_heating030', 'long_name', 'snow thickness on 30 s heating time axis');
ncwriteatt(outFile, 'snow_thickness_heating030', 'units', 'm');

nccreate(outFile, 'ice_thickness_heating030', ...
    'Dimensions', {'time_heating030', nH}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'ice_thickness_heating030', iceThickness_H);
ncwriteatt(outFile, 'ice_thickness_heating030', 'standard_name', 'sea_ice_thickness');
ncwriteatt(outFile, 'ice_thickness_heating030', 'long_name', 'ice thickness on 30 s heating time axis');
ncwriteatt(outFile, 'ice_thickness_heating030', 'units', 'm');

nccreate(outFile, 'time_heating120', 'Dimensions', {'time_heating120', nH120}, 'Datatype', 'double');
ncwrite(outFile, 'time_heating120', timeH120);
ncwriteatt(outFile, 'time_heating120', 'standard_name', 'time');
ncwriteatt(outFile, 'time_heating120', 'long_name', 'time for 120 s heating data');
ncwriteatt(outFile, 'time_heating120', 'units', 'days since 1970-01-01 00:00:00 UTC');
ncwriteatt(outFile, 'time_heating120', 'calendar', 'standard');
ncwriteatt(outFile, 'time_heating120', 'axis', 'T');

nccreate(outFile, 'temperature_change_120s', ...
    'Dimensions', {'time_heating120', nH120, 'depth', nZ}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'temperature_change_120s', double(H120));
ncwriteatt(outFile, 'temperature_change_120s', 'long_name', 'temperature change measured by SIMBA 120 s heating cycle');
ncwriteatt(outFile, 'temperature_change_120s', 'units', 'degree_Celsius');
ncwriteatt(outFile, 'temperature_change_120s', 'coordinates', 'time_heating120 depth');

nccreate(outFile, 'air_snow_interface_heating120', ...
    'Dimensions', {'time_heating120', nH120}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'air_snow_interface_heating120', double(airSnow_H120(:)));
ncwriteatt(outFile, 'air_snow_interface_heating120', 'long_name', 'air-snow interface depth below water level on 120 s heating time axis');
ncwriteatt(outFile, 'air_snow_interface_heating120', 'units', 'm');
ncwriteatt(outFile, 'air_snow_interface_heating120', 'positive', 'down');

nccreate(outFile, 'snow_ice_interface_heating120', ...
    'Dimensions', {'time_heating120', nH120}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'snow_ice_interface_heating120', double(snowIce_H120(:)));
ncwriteatt(outFile, 'snow_ice_interface_heating120', 'long_name', 'snow-ice interface depth below water level on 120 s heating time axis');
ncwriteatt(outFile, 'snow_ice_interface_heating120', 'units', 'm');
ncwriteatt(outFile, 'snow_ice_interface_heating120', 'positive', 'down');

nccreate(outFile, 'ice_water_interface_heating120', ...
    'Dimensions', {'time_heating120', nH120}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'ice_water_interface_heating120', double(iceWater_H120(:)));
ncwriteatt(outFile, 'ice_water_interface_heating120', 'long_name', 'ice-water interface depth below water level on 120 s heating time axis');
ncwriteatt(outFile, 'ice_water_interface_heating120', 'units', 'm');
ncwriteatt(outFile, 'ice_water_interface_heating120', 'positive', 'down');

snowThickness_H120 = double(snowIce_H120(:) - airSnow_H120(:));
iceThickness_H120 = double(iceWater_H120(:) - snowIce_H120(:));

nccreate(outFile, 'snow_thickness_heating120', ...
    'Dimensions', {'time_heating120', nH120}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'snow_thickness_heating120', snowThickness_H120);
ncwriteatt(outFile, 'snow_thickness_heating120', 'standard_name', 'surface_snow_thickness');
ncwriteatt(outFile, 'snow_thickness_heating120', 'long_name', 'snow thickness on 120 s heating time axis');
ncwriteatt(outFile, 'snow_thickness_heating120', 'units', 'm');

nccreate(outFile, 'ice_thickness_heating120', ...
    'Dimensions', {'time_heating120', nH120}, ...
    'Datatype', 'double', ...
    'FillValue', NaN);
ncwrite(outFile, 'ice_thickness_heating120', iceThickness_H120);
ncwriteatt(outFile, 'ice_thickness_heating120', 'standard_name', 'sea_ice_thickness');
ncwriteatt(outFile, 'ice_thickness_heating120', 'long_name', 'ice thickness on 120 s heating time axis');
ncwriteatt(outFile, 'ice_thickness_heating120', 'units', 'm');

ncwriteatt(outFile, '/', 'title', sprintf('Snow depth and sea ice thickness derived from a SIMBA buoy %s', C.id));
ncwriteatt(outFile, '/', 'buoy_id', C.id);
ncwriteatt(outFile, '/', 'summary', 'Temperature, heating temperature, depth, raw and quality-controlled temperature-axis geographic position, geolocation quality flag, interfaces, manual interface measurements, snow thickness, and ice thickness exported from processed SIMBA data.');
ncwriteatt(outFile, '/', 'depth_reference', 'relative to water level');
ncwriteatt(outFile, '/', 'depth_positive_direction', 'down');
ncwriteatt(outFile, '/', 'Conventions', 'CF-1.7');
ncwriteatt(outFile, '/', 'contributor_name', 'Evgenii Salganik, Dmitry Divine, Marcel Nicolaus');
ncwriteatt(outFile, '/', 'contributor_email', 'evgenii.salganik@awi.de');
ncwriteatt(outFile, '/', 'institution', 'Alfred Wegener Institute for Polar and Marine Research');
ncwriteatt(outFile, '/', 'creator_name', 'Evgenii Salganik');
ncwriteatt(outFile, '/', 'creator_email', 'evgenii.salganik@awi.de');
ncwriteatt(outFile, '/', 'project', 'Arctic PASSION');
ncwriteatt(outFile, '/', 'license', 'CC-0');
end