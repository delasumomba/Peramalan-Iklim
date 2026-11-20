
clear; clc; close all

%% 1. MEMBACA DATA RADIOSONDE
data = readmatrix('datawave.txt');

p   = data(:,1);       % Pressure (hPa)
T   = data(:,3);       % Temperature (°C)
Td  = data(:,4);       % Dew Point (°C)

% Membersihkan data
valid = isfinite(p) & isfinite(T) & isfinite(Td);

p = p(valid);
T = T(valid);
Td = Td(valid);

% Mengurutkan tekanan
[p,ord] = sort(p,'descend');
T = T(ord);
Td = Td(ord);


%% 2. PENGATURAN DIAGRAM
pmin = 100;
pmax = 1050;
p0 = 1000;
sk = 30;

% Transformasi Skew-T
skx = @(Tc,pp) Tc + sk*log(p0./pp);

% Rentang tekanan
pl = logspace(log10(pmin),log10(pmax),300);

% Rentang suhu
xrange = [-45 55];


%% 3. MEMBUAT FIGURE
fig = figure('Color','w', ...
    'Position',[100 50 1200 850]);

%% 4. DIAGRAM UTAMA
ax = axes('Parent',fig, ...
    'Position',[0.10 0.12 0.68 0.77]);

hold(ax,'on');
box(ax,'on');


%% 5. GARIS ISOBAR
ptick = [100 150 200 250 300 400 500 ...
         600 700 800 850 900 950 1000];

for pp = ptick

    plot(ax,xrange,[pp pp], ...
        'Color',[0.65 0.65 0.65], ...
        'LineWidth',0.65);

end


%% 6. GARIS ISOTERM
for T0 = -120:10:60

    plot(ax,skx(T0,pl),pl, ...
        'Color',[0.65 0.65 0.65], ...
        'LineWidth',0.65);

end


%% 7. ADIABAT KERING
for theta = 250:10:500

    Tad = theta.*(pl./1000).^0.2854 - 273.15;

    plot(ax,skx(Tad,pl),pl, ...
        'Color',[0.90 0.60 0.40], ...
        'LineWidth',0.65);

end


%% 8. SATURATION MIXING RATIO
mix = [0.1 0.2 0.4 0.6 1 2 3 5 8 12 16 20];

for r = mix

    e = pl.*r./(622+r);

    L = log(e./6.112);

    Tmix = 243.5.*L./(17.67-L);

    plot(ax,skx(Tmix,pl),pl, ...
        'Color',[0.45 0.70 0.55], ...
        'LineStyle','--', ...
        'LineWidth',0.55);

end


%% 9. TEMPERATURE
h1 = plot(ax,skx(T,p),p, ...
    'r-','LineWidth',2);

plot(ax,skx(T,p),p, ...
    'ro','MarkerSize',2.5, ...
    'MarkerFaceColor','r');


%% 10. DEW POINT
h2 = plot(ax,skx(Td,p),p, ...
    'g-','LineWidth',2);

plot(ax,skx(Td,p),p, ...
    'go','MarkerSize',2.5, ...
    'MarkerFaceColor','g');


%% 11. PENGATURAN SUMBU UTAMA
set(ax,'YScale','log');
set(ax,'YDir','reverse');

ylim(ax,[pmin pmax]);
xlim(ax,xrange);

set(ax,'YTick',ptick);
set(ax,'YTickLabel',string(ptick));
set(ax,'XTick',-40:10:50);

xlabel(ax,'Temperature (°C)');
ylabel(ax,'Pressure (hPa)');

set(ax,'FontSize',10);
set(ax,'LineWidth',1);


%% 12. MEMBACA DATA ANGIN
% Kolom 7 = Wind Direction (degree)
% Kolom 8 = Wind Speed (knot)

validwind = isfinite(data(:,1)) & ...
            isfinite(data(:,7)) & ...
            isfinite(data(:,8)) & ...
            data(:,1)>=pmin & ...
            data(:,1)<=pmax & ...
            data(:,7)>=0 & ...
            data(:,7)<=360 & ...
            data(:,8)>=0;

pw = data(validwind,1);
dw = data(validwind,7);
sw = data(validwind,8);

% Mengurutkan tekanan
[pw,iw] = sort(pw,'descend');

dw = dw(iw);
sw = sw(iw);


%% 13. PANEL WIND BARB
axw = axes('Parent',fig, ...
    'Position',[0.81 0.12 0.13 0.77]);

hold(axw,'on');

% Menghitung rasio panel
panelPos = get(axw,'Position');
figPos = getpixelposition(fig);

panelRatio = (panelPos(3)*figPos(3))/ ...
             (panelPos(4)*figPos(4));

% Koordinat panel
x0 = panelRatio/2;

xlim(axw,[0 panelRatio]);
ylim(axw,[0 1]);

set(axw,'YDir','reverse');
set(axw,'DataAspectRatio',[1 1 1]);

axis(axw,'off');


%% 14. GARIS VERTIKAL LURUS
% Garis penghubung seluruh wind barb
% Sesuai dengan contoh diagram

plot(axw,[x0 x0],[0 1], ...
    'k-', ...
    'LineWidth',0.8);


%% 15. MENGGAMBAR WIND BARB
targetP = [1000 925 850 700 600 500 ...
           400 300 250 200 150 100];

used = false(length(pw),1);

for k = 1:length(targetP)

    % Mencari tekanan terdekat
    [~,idx] = sort(abs(log(pw./targetP(k))));

    available = idx(~used(idx));

    if isempty(available)
        continue
    end

    j = available(1);

    % Batas toleransi tekanan
    if abs(log(pw(j)/targetP(k))) > 0.10
        continue
    end

    used(j) = true;

    % Posisi vertikal
    yn = (log(pmax)-log(pw(j))) / ...
         (log(pmax)-log(pmin));

    % Menggambar wind barb
    drawBarb(axw,x0,yn,dw(j),sw(j));

end


%% 16. JUDUL DIAGRAM
sgtitle({'Skew-T Log-P Radiosonde', ...
    'Thiruvananthapuram, India | 26 October 2025'}, ...
    'FontSize',14, ...
    'FontWeight','bold');


%% 17. LEGENDA
legend(ax,[h1 h2], ...
    {'Temperature','Dew Point'}, ...
    'Location','southwest');


%% 18. MENYIMPAN GAMBAR
exportgraphics(fig, ...
    'SkewT_Thiruvananthapuram_26Oct2025.png', ...
    'Resolution',300);


%% ==========================================
% FUNGSI WIND BARB
%% ==========================================

function drawBarb(ax,x0,y0,direction,speed)

    % Normalisasi arah angin
    direction = mod(direction,360);

    % Pembulatan kecepatan
    speed = 5*round(speed/5);

    % Menghitung komponen kecepatan
    n50 = floor(speed/50);

    remainder = speed-n50*50;

    n10 = floor(remainder/10);

    remainder = remainder-n10*10;

    n5 = round(remainder/5);

    % Simbol angin tenang
    if speed == 0

        plot(ax,x0,y0,'ko', ...
            'MarkerSize',3.5, ...
            'LineWidth',0.8);

        return
    end

    % Panjang batang utama
    L = 0.075;

    % Arah batang
    ux = sind(direction);
    uy = -cosd(direction);

    % Ujung batang
    x1 = x0+L*ux;
    y1 = y0+L*uy;

    % Batang utama
    plot(ax,[x0 x1],[y0 y1], ...
        'k-','LineWidth',0.85);

    % Vektor tegak lurus
    nx = -uy;
    ny = ux;

    % Ukuran bulu
    feather = 0.025;
    spacing = 0.018;

    pos = 0;

    % BENDERA 50 KNOT
    for j = 1:n50

        xa = x1-pos*ux;
        ya = y1-pos*uy;

        xb = xa-0.035*ux;
        yb = ya-0.035*uy;

        xc = xa+0.030*nx;
        yc = ya+0.030*ny;

        fill(ax,[xa xb xc], ...
                [ya yb yc], ...
                'k', ...
                'EdgeColor','k', ...
                'LineWidth',0.5);

        pos = pos+spacing*1.5;

    end

    % BULU 10 KNOT
    for j = 1:n10

        xa = x1-pos*ux;
        ya = y1-pos*uy;

        xb = xa-0.5*feather*ux ...
                +0.866*feather*nx;

        yb = ya-0.5*feather*uy ...
                +0.866*feather*ny;

        plot(ax,[xa xb],[ya yb], ...
            'k-','LineWidth',0.85);

        pos = pos+spacing;

    end

    % BULU 5 KNOT
    if n5 > 0

        xa = x1-pos*ux;
        ya = y1-pos*uy;

        xb = xa-0.5*(feather/2)*ux ...
                +0.866*(feather/2)*nx;

        yb = ya-0.5*(feather/2)*uy ...
                +0.866*(feather/2)*ny;

        plot(ax,[xa xb],[ya yb], ...
            'k-','LineWidth',0.85);

    end

end
