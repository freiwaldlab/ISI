function synctimes = processGrabSyncs(syncwave, Fs)
    % Produces a vector corresponding to the rising edge times of syncwave
    high = max(syncwave);
    low = median(syncwave);  % median to avoid negative transients
    thresh = (high + low) / 2;

    syncwave = sign(syncwave - thresh);
    syncwave(syncwave == 0) = 1;
    syncwave = diff((syncwave + 1) / 2);
    synctimes = find(syncwave == 1) + 1;
    synctimes = synctimes / Fs;
    clear syncwave