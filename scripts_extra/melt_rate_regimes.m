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

% Regimes:
% T143 -> regime 1
% T144, T135 -> regime 2
% T145, T136 -> regime 3
regimeMap = containers.Map( ...
    {'T143','T144','T145','T135','T136'}, ...
    [1      2      3      2      3]);

c_reg = cell(1,3);
c_reg{1} = [1, 61, 115] / 255;    % #013D73
c_reg{2} = [58, 174, 140] / 255;  % #3AAE8C
c_reg{3} = [245, 174, 16] / 255;  % #F5AE10

% Distinguish buoys within same regime
lineStyleMap = containers.Map( ...
    {'T143','T144','T145','T135','T136'}, ...
    {'-','-','-','--','--'});

seaOffsetTop_m = 0.10;
seaOffsetBottom_m = 0.60;

nXTicks = 6;

% Trim last N daily ocean-temp points for selected buoys
trimLastOceanDays = containers.Map( ...
    {'T143','T144','T145','T135','T136'}, ...
    [0      0      0      0      0]);   % e.g. trim last 3 days for T136

figure
set(gcf, 'Units','inches','Position',[1 1 11 7], 'Color','w')

tile = tiledlayout(2,1);
tile.TileSpacing = 'compact';
tile.Padding = 'compact';

ax1 = nexttile;
hold(ax1,'on')
grid(ax1,'on')
box(ax1,'off')
ax1.XGrid = 'off';
ax1.YGrid = 'on';
ax1.GridAlpha = 0.16;
ax1.FontSize = 10;
ax1.TickDir = 'out';

ax2 = nexttile;
hold(ax2,'on')
grid(ax2,'on')
box(ax2,'off')
ax2.XGrid = 'off';
ax2.YGrid = 'on';
ax2.GridAlpha = 0.16;
ax2.FontSize = 10;
ax2.TickDir = 'out';

hBasal = gobjects(numel(buoyIDs),1);
hOcean = gobjects(numel(buoyIDs),1);
legendNames = cell(numel(buoyIDs),1);

for b = 1:numel(buoyIDs)
    buoyID = buoyIDs{b};
    legendNames{b} = buoyID;

    ncFile = fullfile(ncDir, sprintf('2025%s.nc', buoyID));
    if ~isfile(ncFile)
        warning('Missing NetCDF file: %s', ncFile)
        continue
    end

    regimeID = regimeMap(buoyID);
    thisColor = c_reg{regimeID};
    thisLineStyle = lineStyleMap(buoyID);

    t = epochDaysToDatetime(ncread(ncFile, 'time_temperature'));
    x = datenum(t);

    z = double(ncread(ncFile, 'depth'));
    T = double(ncread(ncFile, 'temperature'));
    iceWater = double(ncread(ncFile, 'ice_water_interface_temperature'));

    x = x(:);
    iceWater = iceWater(:);

    % -------------------------
    % Basal melt: daily average
    % -------------------------
    dt = diff(x);
    xMid = x(1:end-1) + dt/2;
    botMelt = -diff(iceWater) ./ dt;   % m/day

    tMid = datetime(xMid, 'ConvertFrom','datenum');
    [dayID, ~, idxDay] = unique(dateshift(tMid,'start','day'));

    botDaily = accumarray(idxDay, botMelt, [], @mean);
    xDaily = datenum(dayID);

    % -------------------------
    % Ocean temp: daily average
    % -------------------------
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

    % Trim bad warm tail if needed
    nTrim = trimLastOceanDays(buoyID);
    if nTrim > 0 && numel(seaDaily) >= nTrim
        seaDaily(end-nTrim+1:end) = NaN;
    end

    % -------------------------
    % Plot with straight lines between daily means
    % -------------------------
    hBasal(b) = plot(ax1, xDaily, 100*botDaily, ...
        'LineStyle', thisLineStyle, ...
        'Color', thisColor, ...
        'LineWidth', 2.0, ...
        'DisplayName', buoyID);

    plot(ax1, xDaily, 100*botDaily, 'o', ...
        'Color', thisColor, ...
        'MarkerFaceColor', 'none', ...
        'MarkerSize', 5.5, ...
        'LineWidth', 1.2, ...
        'HandleVisibility', 'off', ...
        'MarkerIndices', 1:4:numel(xDaily));

    hOcean(b) = plot(ax2, xDailySea, seaDaily, ...
        'LineStyle', thisLineStyle, ...
        'Color', thisColor, ...
        'LineWidth', 2.0, ...
        'DisplayName', buoyID);

    plot(ax2, xDailySea, seaDaily, 'o', ...
        'Color', thisColor, ...
        'MarkerFaceColor', 'none', ...
        'MarkerSize', 5.5, ...
        'LineWidth', 1.2, ...
        'HandleVisibility', 'off', ...
        'MarkerIndices', 1:4:numel(xDailySea));
end

yline(ax1, 0, ':', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.7);

ylabel(ax1,'Basal melt (cm d^{-1})')
title(ax1,'Basal melt rates','FontWeight','normal')

ylabel(ax2,'Ocean temp (°C)')
title(ax2,'Ocean temperature','FontWeight','normal')
xlabel(ax2,'Date')

formatDateAxis(ax1, nXTicks)
formatDateAxis(ax2, nXTicks)

goodBasal = isgraphics(hBasal);
goodOcean = isgraphics(hOcean);

lgd1 = legend(ax1, hBasal(goodBasal), legendNames(goodBasal), ...
    'Location','best', 'Box','off');
lgd1.FontSize = 9;

lgd2 = legend(ax2, hOcean(goodOcean), legendNames(goodOcean), ...
    'Location','best', 'Box','off');
lgd2.FontSize = 9;

% exportgraphics(gcf, fullfile(outDir, 'basal_melt_ocean_temp_dailymean.png'), 'Resolution',300)

function t = epochDaysToDatetime(timeDays)
timeDays = double(timeDays(:));
t = datetime(1970,1,1,0,0,0) + days(timeDays);
end

function formatDateAxis(ax, nTicks)
xLim = ax.XLim;

if xLim(1) == xLim(2)
    ax.XTick = xLim(1);
else
    ax.XTick = linspace(xLim(1), xLim(2), nTicks);
end

datetick(ax, 'x', 'mmm dd', 'keepticks', 'keeplimits')

lbl = string(ax.XTickLabel);
lbl = regexprep(lbl, '\b([A-Za-z]{3}) 0(\d)\b', '$1 $2');
ax.XTickLabel = cellstr(lbl);
end