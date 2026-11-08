
%% ================================================================
% DEKOMPOSISI DERET WAKTU BULANAN - NASA POWER
% VARIABEL : SUHU UDARA 2 METER (T2M)
% PERIODE  : 1995-2025
% METODE   : DEKOMPOSISI ADITIF KLASIK
% KOMPONEN : ORIGINAL, TREND, SEASONAL, RESIDUAL
% WARNA    : PINK, UNGU, BIRU, MAGENTA
% ================================================================

clear; clc; close all;

%% 0. PARAMETER

kota    = 'Lokasi Data';
param   = 'T2M';
label   = 'Suhu Udara 2 Meter';
satuan  = '°C';

thAwal  = 1995;
thAkhir = 2025;

fileCSV = 'suhu.csv';

folder = fileparts(mfilename('fullpath'));

if isempty(folder)
    folder = pwd;
end

fCSV = fullfile(folder,fileCSV);

if exist(fCSV,'file') ~= 2
    fCSV = fullfile(pwd,fileCSV);
end

if exist(fCSV,'file') ~= 2
    error('File suhu.csv tidak ditemukan!');
end

%% 1. MEMBACA DATA BULANAN NASA POWER

T = readtable(fCSV,'Delimiter',';');

yr = T.YEAR;

% Mengambil data Januari-Desember
M = T{:,3:14};

% Mengubah nilai kosong NASA menjadi NaN
M(M <= -990) = NaN;

% Mengubah matriks menjadi deret waktu
y = reshape(M',[],1);

% Membuat tanggal bulanan
t = datetime( ...
    repelem(yr,12), ...
    repmat((1:12)',numel(yr),1), ...
    1);

% Membatasi periode
ip = year(t) >= thAwal & year(t) <= thAkhir;

t = t(ip);
y = y(ip);
y = y(:);

n = numel(y);

fprintf('\n====================================\n');
fprintf(' DEKOMPOSISI SUHU UDARA NASA POWER\n');
fprintf('====================================\n');

fprintf('Parameter       : %s\n',param);
fprintf('Variabel        : %s\n',label);
fprintf('Periode         : %d-%d\n',thAwal,thAkhir);
fprintf('Jumlah data     : %d bulan\n',n);

fprintf('Data awal       : %s\n',datestr(t(1),'mmm yyyy'));
fprintf('Data akhir      : %s\n',datestr(t(end),'mmm yyyy'));

% Interpolasi data kosong
if any(isnan(y))
    fprintf('Data kosong     : %d\n',sum(isnan(y)));
    yi = fillmissing(y,'linear','EndValues','nearest');
else
    yi = y;
    fprintf('Data kosong     : Tidak ada\n');
end

%% 2. DEKOMPOSISI ADITIF KLASIK

% 2a. TREND
% Moving Average Terpusat 2x12 Bulan

w = [0.5; ones(11,1); 0.5] / 12;

trend = conv(yi,w,'same');

trend(1:6) = NaN;
trend(end-5:end) = NaN;

% 2b. SEASONAL

detr = yi - trend;

bln = month(t);

sMean = accumarray( ...
    bln,detr,[12 1], ...
    @(v) mean(v,'omitnan'));

sMean = sMean - mean(sMean);

seasonal = sMean(bln);

% 2c. RESIDUAL

resid = yi - trend - seasonal;

%% 3. PLOT DEKOMPOSISI - WARNA BERBEDA

fig = figure( ...
    'Color','w', ...
    'Position',[80 50 1100 800]);

tl = tiledlayout(fig,4,1, ...
    'TileSpacing','compact', ...
    'Padding','compact');

title(tl, ...
    sprintf('Dekomposisi Suhu Udara Bulanan - %s (%d-%d)', ...
    kota,thAwal,thAkhir), ...
    'FontName','Times New Roman', ...
    'FontSize',16, ...
    'FontWeight','bold');

% PALET WARNA

warnaOriginal = [0.95 0.30 0.60];  % Pink
warnaTrend    = [0.55 0.25 0.80];  % Ungu
warnaSeasonal = [0.15 0.45 0.85];  % Biru
warnaResidual = [0.75 0.25 0.60];  % Magenta

% 1. ORIGINAL - PINK

ax1 = nexttile(tl);

plot(ax1,t,y, ...
    'Color',warnaOriginal, ...
    'LineWidth',1.3);

ylabel(ax1,sprintf('Original\n(%s)',satuan));

grid(ax1,'on');

% 2. TREND - UNGU

ax2 = nexttile(tl);

plot(ax2,t,trend, ...
    'Color',warnaTrend, ...
    'LineWidth',1.8);

ylabel(ax2,sprintf('Trend\n(%s)',satuan));

grid(ax2,'on');

% 3. SEASONAL - BIRU

ax3 = nexttile(tl);

plot(ax3,t,seasonal, ...
    'Color',warnaSeasonal, ...
    'LineWidth',1.5);

ylabel(ax3,sprintf('Seasonal\n(%s)',satuan));

grid(ax3,'on');

% 4. RESIDUAL - MAGENTA

ax4 = nexttile(tl);

plot(ax4,t,resid, ...
    'Color',warnaResidual, ...
    'LineWidth',1.1);

hold(ax4,'on');

yline(ax4,0, ...
    'Color',[0.35 0.35 0.35], ...
    'LineWidth',0.8);

hold(ax4,'off');

ylabel(ax4,sprintf('Residual\n(%s)',satuan));

xlabel(ax4,'Tahun', ...
    'FontName','Times New Roman', ...
    'FontWeight','bold');

grid(ax4,'on');

% PENGATURAN SUMBU

axs = [ax1 ax2 ax3 ax4];

linkaxes(axs,'x');

xlim(ax1,[t(1) t(end)]);

set(axs, ...
    'FontName','Arial', ...
    'FontSize',11, ...
    'Box','on', ...
    'GridAlpha',0.15);

set([ax1 ax2 ax3],'XTickLabel',[]);

%% 4. RINGKASAN HASIL DEKOMPOSISI

kekuatanMusim = 1 - ...
    var(resid,'omitnan') / ...
    var(seasonal + resid,'omitnan');

[~,bMax] = max(sMean);
[~,bMin] = min(sMean);

nmBln = { ...
    'Januari','Februari','Maret','April', ...
    'Mei','Juni','Juli','Agustus', ...
    'September','Oktober','November','Desember'};

fprintf('\n========== HASIL DEKOMPOSISI ==========\n');

fprintf('Rata-rata suhu   : %.2f °C\n',mean(yi,'omitnan'));
fprintf('Suhu maksimum    : %.2f °C\n',max(yi));
fprintf('Suhu minimum     : %.2f °C\n',min(yi));

fprintf('Kekuatan musim   : %.3f\n',kekuatanMusim);

fprintf('Musim tertinggi  : %s (%.2f °C)\n', ...
    nmBln{bMax},sMean(bMax));

fprintf('Musim terendah   : %s (%.2f °C)\n', ...
    nmBln{bMin},sMean(bMin));

%% 5. MENYIMPAN GRAFIK

namaKota = regexprep(kota,'[^\w-]','_');

namaFile = fullfile(folder, ...
    sprintf('Dekomposisi_T2M_%s_%d-%d.png', ...
    namaKota,thAwal,thAkhir));

if exist('exportgraphics','file')
    exportgraphics(fig,namaFile,'Resolution',300);
else
    set(fig,'PaperPositionMode','auto');
    print(fig,namaFile,'-dpng','-r300');
end

fprintf('\nGrafik berhasil disimpan:\n%s\n',namaFile);

fprintf('\n====================================\n');
fprintf(' PROSES DEKOMPOSISI SELESAI\n');
fprintf('====================================\n');

