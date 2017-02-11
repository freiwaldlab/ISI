%% Generate inverse look-up-tables to correct for monitor gamma offsets

BasePath = 'C:\Dropbox\ISI\Stimulator';
%BasePath = 'D:\Dropbox (Personal)\Freiwald\FreiwaldMarmosets\ISI\Stimulator';
MeasFile = '170209t1915_calvals.mat';
SaveSuffix = 'LUT.mat';

DataPath = strcat(BasePath, filesep, 'calibration', filesep, 'data');
CorrPath = strcat(BasePath, filesep, 'calibration', filesep, 'corrections');
DateString = datestr(now,30);
DateString = strrep(DateString(3:length(DateString)-2),'T','t');
Prefix = strcat(DateString,'_');

%% Load luminance measurements for each channel and make default settings
load([DataPath filesep MeasFile], 'Y', 'dom');
L = Y';
dom = dom';

domI = (0:255)';
% Assume the appropriate gamma fit will be in this range
gammaspace = 1.25:0.01:4.0;
ampspace = 0.95:0.01:1.05;

%% Find a good gamma fit for the measured values
baseL = mean(L(1,:));
for i = 1:size(L, 2)
    Ldum = L(:,i) - baseL;
    for j = 1:length(gammaspace)
        for k = 1:length(ampspace)
            domgam = dom .^ gammaspace(j);
            domgam = (ampspace(k) * domgam * L(end,i)) / domgam(end);
            E(j,k,i) = mean((domgam - Ldum) .^ 2);
        end
    end
    
    dum = E(:,:,i);
    [idy, idx] = find(dum == min(dum(:)));
    gamma(i) = gammaspace(idy);
    amp(i) = ampspace(idx);
    Lhat(:,i) = domI .^ gamma(i);
    Lhat(:,i) = ((amp(i) * Lhat(:,i) * L(end,i)) / Lhat(end,i)) + baseL;
end

%% Plot fit results for visual inspection
figure
hold on
plot(dom, L)
plot(domI, Lhat, 'k')
hold off
xlim([0 255])
axis square
legend('R', 'G', 'B', 'fits')

%% Convert fit to inverse look-up-table
Lhat = Lhat ./ (ones(256, 1) * Lhat(end,:));

gammaLUT = linspace(0, 1, 256)';
for i = 1:3
    bufLUT(:,i) = 10 .^ (log10(gammaLUT) / gamma(i));
end

%% Plot inverse look-up-table
figure
plot(bufLUT)
xlim([0 255])
axis square
legend('R', 'G', 'B')

%% Save inverse look-up-table for use and raw values for reference
L = Lhat;
save([CorrPath filesep Prefix SaveSuffix], 'bufLUT', 'L')