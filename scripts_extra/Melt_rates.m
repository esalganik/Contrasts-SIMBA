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
outDir = fullfile(scriptDir, 'Export');

if ~isfolder(outDir)
    mkdir(outDir);
end

buoyIDs = {'T143','T144','T145','T135','T136'};

seaOffsetTop_m = 0.10;
seaOffsetBottom_m = 0.60;

nXTicks = 4;

cSurf  = [0.40 0.75 0.75];
cBot   = [0.10 0.20 0.80];
cDrift = [0.60 0.60 0.60];
cSea   = [1.00 0.10 0.10];
cZero  = [0.82 0.82 0.82];

nBuoys = numel(buoyIDs);

figure
set(gcf, 'Units','inches','Position',[1 1 12 8.8], 'Color','w')

tile = tiledlayout(nBuoys, 2);
tile.TileSpacing = 'tight';
tile.Padding = 'compact';

for b = 1:nBuoys
    buoyID = buoyIDs{b};

    ncFile = fullfile(ncDir, sprintf('2025%s.nc', buoyID));
    if ~isfile(ncFile)
        warning('Missing NetCDF file: %s', ncFile)

        ax1 = nexttile;
        axis(ax1,'off')
        text(0.5,0.5,sprintf('%s missing', buoyID), ...
            'Parent', ax1, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontSize',10)

        ax2 = nexttile;
        axis(ax2,'off')
        continue
    end

    t = epochDaysToDatetime(ncread(ncFile, 'time_temperature'));
    x = datenum(t);

    z = double(ncread(ncFile, 'depth'));
    T = double(ncread(ncFile, 'temperature'));

    snowIce = double(ncread(ncFile, 'snow_ice_interface_temperature'));
    iceWater = double(ncread(ncFile, 'ice_water_interface_temperature'));

    lat = double(ncread(ncFile, 'latitude_temperature'));
    lon = double(ncread(ncFile, 'longitude_temperature'));

    x = x(:);
    snowIce = snowIce(:);
    iceWater = iceWater(:);
    lat = lat(:);
    lon = lon(:);

    dt = diff(x);
    xMid = x(1:end-1) + dt/2;

    surfMelt = diff(snowIce) ./ dt;
    botMelt  = -diff(iceWater) ./ dt;

    tMid = datetime(xMid, 'ConvertFrom','datenum');
    [dayID, ~, idxDay] = unique(dateshift(tMid,'start','day'));

    surfDaily = accumarray(idxDay, surfMelt, [], @mean);
    botDaily  = accumarray(idxDay, botMelt,  [], @mean);

    xDaily = datenum(dayID);

    seaTemp = nan(size(x));

    for k = 1:numel(x)
        if ~isfinite(iceWater(k))
            continue
        end

        z1 = iceWater(k) + seaOffsetTop_m;
        z2 = iceWater(k) + seaOffsetBottom_m;

        zTop = min(z1,z2);
        zBot = max(z1,z2);

        idx = z >= zTop & z <= zBot;
        Tk = T(k,:).';

        if any(idx)
            seaTemp(k) = mean(Tk(idx), 'omitnan');
        end
    end

    tFull = datetime(x, 'ConvertFrom','datenum');
    [dayID2, ~, idxDay2] = unique(dateshift(tFull,'start','day'));

    seaDaily = accumarray(idxDay2, seaTemp, [], @mean);
    xDailySea = datenum(dayID2);

    driftSpeed = nan(size(x));

    goodGeo = isfinite(lat) & isfinite(lon) & isfinite(x);
    ig = find(goodGeo);

    for j = 2:numel(ig)
        i1 = ig(j-1);
        i2 = ig(j);

        dtDay = x(i2) - x(i1);
        if dtDay <= 0
            continue
        end

        dkm = gcDistanceKm(lat(i1), lon(i1), lat(i2), lon(i2));
        driftSpeed(i2) = dkm / dtDay;
    end

    driftDaily = accumarray(idxDay2, driftSpeed, [], @mean);

    ax1 = nexttile;
    hold(ax1,'on')
    grid(ax1,'on')
    ax1.XGrid = 'off';
    ax1.YGrid = 'on';
    ax1.GridAlpha = 0.16;
    ax1.MinorGridAlpha = 0.08;
    ax1.FontSize = 9;
    ax1.TickDir = 'out';
    ax1.TickLength = [0.012 0.012];
    box(ax1,'off')

    hSurf = plot(ax1, xDaily, 100*surfDaily, '-o', ...
        'Color', cSurf, ...
        'MarkerFaceColor', 'none', ...
        'MarkerSize', 4.5, ...
        'LineWidth', 1.3, ...
        'MarkerIndices', 1:5:numel(xDaily));

    hBot = plot(ax1, xDaily, 100*botDaily, '-', ...
        'Color', cBot, ...
        'LineWidth', 1.6);

    hZero = yline(ax1, 0, ':', ...
        'Color', cZero, ...
        'LineWidth', 0.6);
    hZero.Annotation.LegendInformation.IconDisplayStyle = 'off';

    ylabel(ax1,'Melt (cm d^{-1})')
    title(ax1, buoyID, 'FontWeight','normal')

    formatDateAxis(ax1, xDaily, nXTicks)

    lgd1 = legend(ax1, [hSurf hBot], ...
        {'Surface melt','Basal melt'}, ...
        'Location','best');
    lgd1.Box = 'off';
    lgd1.FontSize = 8;
    lgd1.Color = 'none';
    lgd1.ItemTokenSize = [10 6];

    ax2 = nexttile;
    hold(ax2,'on')
    grid(ax2,'on')
    ax2.XGrid = 'off';
    ax2.YGrid = 'on';
    ax2.GridAlpha = 0.16;
    ax2.MinorGridAlpha = 0.08;
    ax2.FontSize = 8.5;
    ax2.TickDir = 'out';
    ax2.TickLength = [0.012 0.012];
    box(ax2,'off')

    yyaxis(ax2,'left')
    hDrift = plot(ax2, xDailySea, driftDaily, '-', ...
        'Color', cDrift, ...
        'LineWidth', 1.2);
    ylabel(ax2,'Drift (km d^{-1})')
    ax2.YColor = [0.20 0.45 0.90];

    yyaxis(ax2,'right')
    hSea = plot(ax2, xDailySea, seaDaily, '-o', ...
        'Color', cSea, ...
        'MarkerFaceColor', 'none', ...
        'MarkerSize', 4, ...
        'LineWidth', 1.2, ...
        'MarkerIndices', 1:5:numel(xDailySea));
    ylabel(ax2,'Ocean temp (°C)')
    ax2.YColor = [0.95 0.35 0.10];

    formatDateAxis(ax2, xDailySea, nXTicks)

    lgd2 = legend(ax2, [hDrift hSea], ...
        {'Drift','Ocean temp'}, ...
        'Location','best');
    lgd2.Box = 'off';
    lgd2.FontSize = 8;
    lgd2.Color = 'none';
    lgd2.ItemTokenSize = [10 6];
end

exportgraphics(gcf, fullfile(outDir, 'melt_rates.png'), 'Resolution',300)

function t = epochDaysToDatetime(timeDays)
timeDays = double(timeDays(:));
t = datetime(1970,1,1,0,0,0) + days(timeDays);
end

function formatDateAxis(ax, x, nTicks)
x = x(isfinite(x));
if isempty(x)
    return
end

xMin = min(x);
xMax = max(x);

if xMin == xMax
    ax.XTick = xMin;
    ax.XLim = [xMin-0.5 xMax+0.5];
else
    ax.XTick = linspace(xMin, xMax, nTicks);
    ax.XLim = [xMin xMax];
end

datetick(ax, 'x', 'mmm dd', 'keepticks', 'keeplimits')

lbl = string(ax.XTickLabel);
lbl = regexprep(lbl, '\b([A-Za-z]{3}) 0(\d)\b', '$1 $2');
ax.XTickLabel = cellstr(lbl);
end

function dkm = gcDistanceKm(lat1, lon1, lat2, lon2)
R = 6371;
lat1 = deg2rad(lat1); lon1 = deg2rad(lon1);
lat2 = deg2rad(lat2); lon2 = deg2rad(lon2);

dlat = lat2-lat1;
dlon = lon2-lon1;

a = sin(dlat/2).^2 + cos(lat1).*cos(lat2).*sin(dlon/2).^2;
c = 2*atan2(sqrt(a),sqrt(1-a));
dkm = R*c;
end