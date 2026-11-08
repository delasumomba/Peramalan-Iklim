
%% PETA STREAMLINE ANGIN INDONESIA - FORMAT BMKG
% Level tekanan : 850 hPa
% Tanggal       : 26 Oktober 2025
% Data          : NCEP/DOE Reanalysis 2 (daily mean, netCDF)
% Warna         : Pink - Magenta - Ungu
% File          : uwnd.2025.nc dan vwnd.2025.nc

clear; clc; close all;

%% 0. PARAMETER
tgl      = datetime(2025,10,26);
level    = 850;
fileU    = 'uwnd.2025.nc';
fileV    = 'vwnd.2025.nc';
shpfile  = 'landareas.shp';

lonMin = 92;
lonMax = 143;
latMin = -12;
latMax = 8;

% Posisi pusat tekanan rendah [lon lat]
pusat_L = [];

%% 1. MEMBACA DATA NETCDF
lon_nc = double(ncread(fileU,'lon'));
lat_nc = double(ncread(fileU,'lat'));
lev_nc = double(ncread(fileU,'level'));
t_nc   = double(ncread(fileU,'time'));

% Konversi waktu
t_all = datetime(1800,1,1) + hours(t_nc);

it = find(dateshift(t_all,'start','day') == tgl,1);
ik = find(lev_nc == level,1);

if isempty(it)
    error('Tanggal %s tidak ada di file.',datestr(tgl));
end

if isempty(ik)
    error('Level %d hPa tidak ada di file.',level);
end

% Membaca komponen angin U dan V
U = double(ncread(fileU,'uwnd',[1 1 ik it],[Inf Inf 1 1]))';
V = double(ncread(fileV,'vwnd',[1 1 ik it],[Inf Inf 1 1]))';

% Mengurutkan lintang
[lat_id,isrt] = sort(lat_nc);

U = U(isrt,:);
V = V(isrt,:);

lon_id = lon_nc;

% Subset wilayah Indonesia
ixLon = lon_id >= lonMin-5 & lon_id <= lonMax+5;
ixLat = lat_id >= latMin-5 & lat_id <= latMax+5;

lon_id = lon_id(ixLon);
lat_id = lat_id(ixLat);

U = U(ixLat,ixLon);
V = V(ixLat,ixLon);

%% 2. INTERPOLASI GRID HALUS
lon_f = linspace(lonMin,lonMax,500);
lat_f = linspace(latMin,latMax,200);

[Lon_f,Lat_f] = meshgrid(lon_f,lat_f);

U_f = interp2(lon_id,lat_id,U,Lon_f,Lat_f,'cubic');
V_f = interp2(lon_id,lat_id,V,Lon_f,Lat_f,'cubic');

% Kecepatan angin
WS_f = sqrt(U_f.^2 + V_f.^2);
WS_f_kt = WS_f * 1.94384;

% Koreksi arah streamline
U_plot = U_f ./ cosd(Lat_f);
V_plot = V_f;

%% 3. FIGURE
fig = figure('Color','w','Position',[50 50 1550 680]);

ax = axes('Parent',fig);
hold(ax,'on');

%% 4. LATAR KECEPATAN ANGIN
imagesc(ax,lon_f,lat_f,WS_f);
set(ax,'YDir','normal');

% GRADASI WARNA PINK - MAGENTA - UNGU
keys = [1.00 0.85 0.90;   % Pink sangat muda
        1.00 0.65 0.78;   % Pink muda
        1.00 0.43 0.67;   % Pink
        0.95 0.25 0.60;   % Pink magenta
        0.78 0.12 0.52;   % Magenta
        0.55 0.06 0.43;   % Ungu magenta
        0.32 0.02 0.28];  % Ungu tua

pos = linspace(0,1,size(keys,1));

cmap = interp1(pos,keys,linspace(0,1,256));

colormap(ax,cmap);
caxis(ax,[0 19]);

%% 5. DARATAN DAN GARIS PANTAI
if exist(shpfile,'file') == 2

    land = shaperead(shpfile,'UseGeoCoords',true);

    for k = 1:numel(land)

        lx = land(k).Lon(:);
        ly = land(k).Lat(:);

        if max(lx) < lonMin-2 || min(lx) > lonMax+2 || ...
           max(ly) < latMin-2 || min(ly) > latMax+2
            continue;
        end

        idx = [0; find(isnan(lx)); numel(lx)+1];

        for m = 1:numel(idx)-1

            seg = idx(m)+1:idx(m+1)-1;

            if numel(seg) < 3
                continue;
            end

            patch(ax,lx(seg),ly(seg),[0.80 0.80 0.80], ...
                'EdgeColor','k','LineWidth',0.4);
        end
    end

else
    warning('%s tidak ditemukan. Daratan tidak digambar.',shpfile);
end

%% 6. STREAMLINE PUTIH DENGAN PANAH
h = streamslice(ax,Lon_f,Lat_f,U_plot,V_plot,2.2);

set(h,'Color','w','LineWidth',0.9);

%% 7. LABEL KECEPATAN ANGIN (KNOT)
lon_lbl = lonMin+6:7:lonMax-3;
lat_lbl = latMin+2:4:latMax-1;

for a = 1:numel(lat_lbl)

    for b = 1:numel(lon_lbl)

        lo = lon_lbl(b)+3*mod(a,2);
        la = lat_lbl(a);

        if lo > lonMax-2
            continue;
        end

        kt = interp2(Lon_f,Lat_f,WS_f_kt,lo,la);

        if ~isnan(kt)

            text(ax,lo,la,sprintf('%.0f kt',kt), ...
                'Color','k', ...
                'FontSize',9, ...
                'FontWeight','bold', ...
                'FontName','Arial', ...
                'HorizontalAlignment','center');
        end
    end
end

%% 8. TANDA PUSAT TEKANAN RENDAH
if ~isempty(pusat_L)

    text(ax,pusat_L(1),pusat_L(2),'L', ...
        'Color','k','FontSize',34, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','center');

    text(ax,pusat_L(1),pusat_L(2)-1.6, ...
        sprintf('%d hPa',level), ...
        'Color','k','FontSize',11, ...
        'FontWeight','bold', ...
        'FontName','Arial', ...
        'HorizontalAlignment','center');
end

%% 9. SUMBU DAN TICK
xlim(ax,[lonMin lonMax]);
ylim(ax,[latMin latMax]);

xt = 100:10:140;
yt = -12:4:8;

set(ax,'XTick',xt,'YTick',yt);

set(ax,'XTickLabel', ...
    arrayfun(@(x) sprintf('%d%cE',x,176), ...
    xt,'UniformOutput',false));

yl = cell(size(yt));

for q = 1:numel(yt)

    if yt(q) > 0
        yl{q} = sprintf('%d%cN',yt(q),176);

    elseif yt(q) < 0
        yl{q} = sprintf('%d%cS',abs(yt(q)),176);

    else
        yl{q} = sprintf('0%c',176);
    end
end

set(ax,'YTickLabel',yl);

set(ax,'FontName','Arial', ...
    'FontSize',12, ...
    'Layer','top', ...
    'Box','on', ...
    'TickDir','out', ...
    'LineWidth',0.8);

%% 10. COLORBAR
cb = colorbar(ax);

cb.Ticks = 0:2:18;
cb.FontName = 'Arial';
cb.FontSize = 12;

cb.Label.String = 'Kecepatan Angin (m/s)';
cb.Label.FontSize = 12;
cb.Label.FontName = 'Arial';

%% 11. POSISI SUMBU DAN COLORBAR
set(ax,'Units','normalized', ...
    'Position',[0.075 0.15 0.828 0.72]);

set(cb,'Units','normalized', ...
    'Position',[0.909 0.15 0.012 0.72]);

%% 12. JUDUL DAN LABEL
bulan = {'Januari','Februari','Maret','April','Mei','Juni', ...
         'Juli','Agustus','September','Oktober', ...
         'November','Desember'};

judul = sprintf('Peta Streamline Indonesia %d %s %d', ...
    day(tgl),bulan{month(tgl)},year(tgl));

title(ax,judul, ...
    'FontName','Times New Roman', ...
    'FontSize',16, ...
    'FontWeight','bold');

xlabel(ax,'Longitude', ...
    'FontName','Times New Roman', ...
    'FontSize',13, ...
    'FontWeight','bold');

ylabel(ax,'Latitude', ...
    'FontName','Times New Roman', ...
    'FontSize',13, ...
    'FontWeight','bold');

hold(ax,'off');
drawnow;

%% 13. SIMPAN GAMBAR
namaFile = sprintf('Streamline_Indonesia_%s.png', ...
    datestr(tgl,'ddmmmyyyy'));

if exist('exportgraphics','file')

    exportgraphics(fig,namaFile,'Resolution',300);

else

    set(fig,'PaperPositionMode','auto');
    print(fig,namaFile,'-dpng','-r300');

end

disp(['Peta berhasil dibuat: ' namaFile]);
