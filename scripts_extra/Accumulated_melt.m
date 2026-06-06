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

if ~isfolder(ncDir)
    error('Export folder not found: %s', ncDir)
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
c_reg{1} = [1, 61, 115] / 255;    % regime 1
c_reg{2} = [58, 174, 140] / 255;  % regime 2
c_reg{3} = [245, 174, 16] / 255;  % regime 3

lineStyleMap = containers.Map( ...
    {'T143','T144','T145','T135','T136'}, ...
    {'-','-','-','--','--'});

nXTicks = 6;
daysAfterLastVisit = 4;

% A, B, C, D markers
visitMarkerMap = {'o','s','^','d'};

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

hSurf = gobjects(numel(buoyIDs),1);
hBot = gobjects(numel(buoyIDs),1);
legendNames = cell(numel(buoyIDs),1);

visitDefs = getVisitDefinitions();

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
    x = x(:);

    airSnow = double(ncread(ncFile, 'air_snow_interface_temperature'));
    iceWater = double(ncread(ncFile, 'ice_water_interface_temperature'));

    airSnow = airSnow(:);
    iceWater = iceWater(:);

    nMin = min([numel(x), numel(airSnow), numel(iceWater)]);
    x = x(1:nMin);
    airSnow = airSnow(1:nMin);
    iceWater = iceWater(1:nMin);

    good = isfinite(x) & isfinite(airSnow) & isfinite(iceWater);
    x = x(good);
    airSnow = airSnow(good);
    iceWater = iceWater(good);

    if numel(x) < 2
        warning('Not enough valid interface points in %s', ncFile)
        continue
    end

    % Surface melt from air-snow interface:
    % melt => interface becomes less negative => +diff(airSnow)
    surfStep = diff(airSnow);          % m per timestep
    surfStep(surfStep < 0) = 0;        % keep melt only
    surfAccum = cumsum(surfStep);      % m

    % Bottom melt from ice-water interface:
    % melt => interface moves upward => -diff(iceWater)
    botStep = -diff(iceWater);         % m per timestep
    botStep(botStep < 0) = 0;          % keep melt only
    botAccum = cumsum(botStep);        % m

    xAccum = x(2:end);

    hSurf(b) = plot(ax1, xAccum, 100*surfAccum, ...
        'LineStyle', thisLineStyle, ...
        'Color', thisColor, ...
        'LineWidth', 2.0, ...
        'DisplayName', buoyID);

    hBot(b) = plot(ax2, xAccum, 100*botAccum, ...
        'LineStyle', thisLineStyle, ...
        'Color', thisColor, ...
        'LineWidth', 2.0, ...
        'DisplayName', buoyID);

    thisVisits = visitDefs(regimeID);

    for k = 1:numel(thisVisits.mid)
        xVisit = datenum(thisVisits.mid(k));
        thisMarker = visitMarkerMap{k};

        [xMarkSurf, yMarkSurf, okSurf] = interpCurveAtVisit(xAccum, 100*surfAccum, xVisit);
        if okSurf
            plot(ax1, xMarkSurf, yMarkSurf, ...
                'LineStyle', 'none', ...
                'Marker', thisMarker, ...
                'MarkerSize', 7.5, ...
                'MarkerFaceColor', 'w', ...
                'MarkerEdgeColor', thisColor, ...
                'LineWidth', 1.6, ...
                'HandleVisibility', 'off');
        end

        [xMarkBot, yMarkBot, okBot] = interpCurveAtVisit(xAccum, 100*botAccum, xVisit);
        if okBot
            plot(ax2, xMarkBot, yMarkBot, ...
                'LineStyle', 'none', ...
                'Marker', thisMarker, ...
                'MarkerSize', 7.5, ...
                'MarkerFaceColor', 'w', ...
                'MarkerEdgeColor', thisColor, ...
                'LineWidth', 1.6, ...
                'HandleVisibility', 'off');
        end
    end
end

ylabel(ax1,'Accumulated surface melt (cm)')
title(ax1,'Accumulated surface melt','FontWeight','normal')

ylabel(ax2,'Accumulated bottom melt (cm)')
title(ax2,'Accumulated bottom melt','FontWeight','normal')
xlabel(ax2,'Date')

addVisitLines(ax1, true, c_reg)
addVisitLines(ax2, false, c_reg)

goodSurf = isgraphics(hSurf);
goodBot = isgraphics(hBot);

lgd1 = legend(ax1, hSurf(goodSurf), legendNames(goodSurf), ...
    'Location','best', 'Box','off');
lgd1.FontSize = 9;

lgd2 = legend(ax2, hBot(goodBot), legendNames(goodBot), ...
    'Location','best', 'Box','off');
lgd2.FontSize = 9;

linkaxes([ax1 ax2], 'x')

lastVisitMid = max([visitDefs.mid]);
xMaxCrop = datenum(lastVisitMid + days(daysAfterLastVisit));

ax1.XLim(2) = min(ax1.XLim(2), xMaxCrop);
ax2.XLim(2) = min(ax2.XLim(2), xMaxCrop);

formatDateAxis(ax1, nXTicks)
formatDateAxis(ax2, nXTicks)

% exportgraphics(gcf, fullfile(outDir, 'accumulated_surface_bottom_melt_visits.png'), 'Resolution',300)

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

function addVisitLines(ax, addLabels, c_reg)
visitDefs = getVisitDefinitions();

for r = 1:numel(visitDefs)
    for k = 1:numel(visitDefs(r).mid)
        xPos = datenum(visitDefs(r).mid(k));

        if addLabels
            xline(ax, xPos, '--', visitDefs(r).labels{k}, ...
                'Color', c_reg{r}, ...
                'LineWidth', 2.0, ...
                'Alpha', 0.9, ...
                'LabelOrientation', 'horizontal', ...
                'LabelVerticalAlignment', 'middle', ...
                'LabelHorizontalAlignment', 'center', ...
                'FontSize', 9, ...
                'HandleVisibility', 'off');
        else
            xline(ax, xPos, '--', ...
                'Color', c_reg{r}, ...
                'LineWidth', 2.0, ...
                'Alpha', 0.9, ...
                'HandleVisibility', 'off');
        end
    end
end
end

function visitDefs = getVisitDefinitions()
yr = 2025;

visitDefs(1).labels = {'R1-A','R1-B','R1-C'};
visitDefs(1).mid = [ ...
    midpoint(datetime(yr,7,9,0,0,0),  datetime(yr,7,12,23,59,59)), ...
    midpoint(datetime(yr,7,25,0,0,0), datetime(yr,7,28,23,59,59)), ...
    midpoint(datetime(yr,8,9,0,0,0),  datetime(yr,8,10,23,59,59))];

visitDefs(2).labels = {'R2-A','R2-B','R2-C','R2-D'};
visitDefs(2).mid = [ ...
    midpoint(datetime(yr,7,14,0,0,0), datetime(yr,7,17,23,59,59)), ...
    midpoint(datetime(yr,7,30,0,0,0), datetime(yr,8,1,23,59,59)), ...
    midpoint(datetime(yr,8,12,0,0,0), datetime(yr,8,14,23,59,59)), ...
    midpoint(datetime(yr,8,23,0,0,0), datetime(yr,8,24,23,59,59))];

visitDefs(3).labels = {'R3-A','R3-B','R3-C','R3-D'};
visitDefs(3).mid = [ ...
    midpoint(datetime(yr,7,19,0,0,0), datetime(yr,7,22,23,59,59)), ...
    midpoint(datetime(yr,8,4,0,0,0),  datetime(yr,8,6,23,59,59)), ...
    midpoint(datetime(yr,8,16,0,0,0), datetime(yr,8,18,23,59,59)), ...
    midpoint(datetime(yr,8,26,0,0,0), datetime(yr,8,27,23,59,59))];
end

function tm = midpoint(t1, t2)
tm = t1 + (t2 - t1)/2;
end

function [xSel, ySel, ok] = interpCurveAtVisit(x, y, xTarget)
ok = false;
xSel = NaN;
ySel = NaN;

good = isfinite(x) & isfinite(y);
xg = x(good);
yg = y(good);

if numel(xg) < 2
    return
end

if xTarget < min(xg) || xTarget > max(xg)
    return
end

xSel = xTarget;
ySel = interp1(xg, yg, xTarget, 'linear');
ok = isfinite(ySel);
end