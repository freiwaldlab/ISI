
%2 doesn't assume 0:5:255.  I started using it with the UDT measurements

%IN 5/18/10  In this new version, it reads a .mat file instead of text
%file.  It doesn't have any interpolation of the raw data. And I fit a
%gamma function to smooth it.  The gamma turned out to be better than polynomial, mainly
%because it is always monotonic. The polynomials (and raw data because of
%noise)

%always give a nonmonotonic curve near the origin.
%%
CalPath = 'C:\Dropbox\ISI\Stimulator\master\Calibration\170201';
%CalPath = 'D:\Dropbox (Personal)\Freiwald\FreiwaldMarmosets\ISI\Stimulator\master\Calibration\170201';

fget = '170206t1930_calvals.mat';
fput = '170203t1509_LUT.mat';

load([CalPath filesep fget], 'Y', 'dom'); L = Y';

dom = dom';
domI = (0:255)';

clear E
gammaspace = 1.5:0.01:3.5;
Ampspace = 0.95:0.01:1.05;

base = mean(L(1,:));

for i = 1:3
    Ldum = L(:,i) - base;
    for j = 1:length(gammaspace)
        for k = 1:length(Ampspace)
            mod = dom.^gammaspace(j);
            mod = Ampspace(k)*mod*L(end,i)/mod(end);
            E(j,k,i) = mean((mod-Ldum).^2);
        end
    end
    
    dum = E(:,:,i);
    [idy, idx] = find(dum == min(dum(:)));
    gamma(i) = gammaspace(idy);
    amp(i) = Ampspace(idx);
    Lhat(:,i) = domI.^gamma(i);
    Lhat(:,i) = amp(i)*Lhat(:,i)*L(end,i)/Lhat(end,i) + base;
end

% 
% clear bufLUT
% bufLUT = zeros(256,3);
% for gun = 1:3
%     for i = 0:255;
%         val = i/255 * (Lhat(end,gun)-Lhat(1,gun)) + Lhat(1,gun);  %desired luminance as fraction of max
%         [dum id] = min(abs(val - Lhat(:,gun)));  %find gun value that outputs closest to the desired Lum
%         bufLUT(i+1,gun) = id;
%     end
% end
% 
% bufLUT = (bufLUT-1)/255;  %PTB wants it to be between 0 and 1
% 
% figure,plot(bufLUT)

figure
plot(dom,L)
hold on
plot(domI, Lhat, 'k')
xlim([0 255])
legend('R', 'G', 'B')
axis square
%Convert to Look-up-table
Lhat = Lhat ./ (ones(256,1) * Lhat(end,:));

gammaLUT = linspace(0,1,256)';
for i = 1:3
    bufLUT(:,i) = 10.^(log10(gammaLUT)/gamma(i));
end
figure
plot(bufLUT)

%Save raw values and look up table

L = Lhat;
%save([root fput],'bufLUT','L')
%save([CalPath filesep fput],'bufLUT','L')