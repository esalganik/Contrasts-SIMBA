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

buoyIDs = {'T143','T144','T145','T135','T136'};
buoyRegime = [1 2 3 2 3];

c_reg = cell(3,1);
c_reg{1} = [1, 61, 115] / 255;    % #013D73
c_reg{2} = [58, 174, 140] / 255;  % #3AAE8C
c_reg{3} = [245, 174, 16] / 255;  % #F5AE10

nXTicks = 6;
cZero = [0.82 0.82 0.82];

figure
set(gcf, 'Units','inches','Position',[1 1 12 4.8], 'Color','w')

ax = axes;
hold(ax,'on')
grid(ax,'on')
ax.XGrid = 'off';
ax.YGrid = 'on';
ax.GridAlpha = 0.16;
ax.MinorGridAlpha = 0.08;
ax.FontSize = 9;
ax.TickDir = 'out';
ax.TickLength = [0.012 0.012];
box(ax,'off')

h = gobjects(numel(buoyIDs),1);
xAll = [];

for b = 1:numel(buoyIDs)
    buoyID = buoyIDs{b};
    regID = buoyRegime(b);
    cLine = c_reg{regID};

    ncFile = fullfile(ncDir, sprintf('2025%s.nc', buoyID));
    if ~isfile(ncFile)
        warning('Missing NetCDF file: %s', ncFile)
        continue
    end

    t = epochDaysToDatetime(ncread(ncFile, 'time_temperature'));
    x = datenum(t);

    z = double(ncread(ncFile, 'depth'));
    T = double(ncread(ncFile, 'temperature'));
    iceWater = double(ncread(ncFile, 'ice_water_interface_temperature'));

    x = x(:);
    z = z(:);
    iceWater = iceWater(:);

    nTime = numel(x);

    tBottom = nan(nTime,1);
    tOcean  = nan(nTime,1);

    for k = 1:nTime
        Tk = T(k,:).';

        good = isfinite(z) & isfinite(Tk);
        if nnz(good) < 2 || ~isfinite(iceWater(k))
            continue
        end

        zg = z(good);
        Tg = Tk(good);

        [zg, iu] = unique(zg);
        Tg = Tg(iu);

        if numel(zg) < 2
            continue
        end

        if iceWater(k) >= min(zg) && iceWater(k) <= max(zg)
            tBottom(k) = interp1(zg, Tg, iceWater(k), 'linear');
        end

        [~, iDeep] = max(zg);
        tOcean(k) = Tg(iDeep);
    end

    dT = tOcean - tBottom;

    tFull = datetime(x, 'ConvertFrom','datenum');
    [dayID, ~, idxDay] = unique(dateshift(tFull,'start','day'));

    dTDaily = accumarray(idxDay, dT, [], @mean);
    xDaily = datenum(dayID);

    goodDaily = isfinite(xDaily) & isfinite(dTDaily);
    xDaily = xDaily(goodDaily);
    dTDaily = dTDaily(goodDaily);

    if isempty(xDaily)
        continue
    end

    xAll = [xAll; xDaily(:)];

    h(b) = plot(ax, xDaily, dTDaily, '-o', ...
        'Color', cLine, ...
        'MarkerFaceColor', 'none', ...
        'MarkerSize', 4, ...
        'LineWidth', 1.5, ...
        'DisplayName', sprintf('%s (Regime %d)', buoyID, regID), ...
        'MarkerIndices', 1:5:numel(xDaily));
end

yline(ax, 0, ':', 'Color', cZero, 'LineWidth', 0.7);

ylabel(ax,'\DeltaT = T_{ocean} - T_{bottom} (^{\circ}C)')
title(ax,'Ocean-bottom temperature difference', 'FontWeight','normal')

formatDateAxis(ax, xAll, nXTicks)

hValid = h(isgraphics(h));
if ~isempty(hValid)
    lgd = legend(ax, hValid, 'Location','best');
    lgd.Box = 'off';
    lgd.FontSize = 8;
    lgd.Color = 'none';
    lgd.ItemTokenSize = [10 6];
end

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