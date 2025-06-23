%% PARAMETERS
Fs = 1000;  % Sampling rate
range = (25*Fs):(205*Fs);  % 25 to 205 seconds

% Load your vars (assumes these were previously computed)
readout = ringRateHz(range);
validHz = ringRateHz(range);
validPeriod = ringPeriodMs(range);
validVel = velocities(range);

% Clean up NaNs
validHz = fillmissing(validHz, 'linear');
validPeriod = fillmissing(validPeriod, 'linear');
validVel = fillmissing(validVel, 'linear');

% Compute means and stds
avgHz = mean(validHz, 'omitnan');
stdHz = std(validHz, 'omitnan');
avgPeriod = mean(validPeriod, 'omitnan');
stdPeriod = std(validPeriod, 'omitnan');
avgVel = mean(validVel, 'omitnan');
stdVel = std(validVel, 'omitnan');

% SONG INFO
songName = 'Alone by Heart';
songTempoHz = 5.84;
songTempoBPM = 349.5;
songPeriodMs = 171;

timeVec = (range - 1) / Fs;  % seconds

%% PLOT
figure('Color','w', 'Position', [100 100 1200 600]);

% === Ring Frequency ===
subplot(3,1,1);
plot(timeVec, readout, 'b', 'DisplayName', 'Ring Frequency'); hold on;
yline(avgHz, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Mean');
yline(avgHz + stdHz, 'r:', 'LineWidth', 1, 'DisplayName', '+1 SD');
yline(avgHz - stdHz, 'r:', 'LineWidth', 1, 'DisplayName', '-1 SD');
yline(songTempoHz, 'k--', 'LineWidth', 2, ...
    'DisplayName', sprintf('%s Tempo (%.2f Hz)', songName, songTempoHz));
legend('Location','northeast');
title('Ring Frequency (Hz)');
ylabel('Hz');
grid on;

% === Ring Period ===
subplot(3,1,2);
plot(timeVec, validPeriod, 'g', 'DisplayName', 'Ring Period'); hold on;
yline(avgPeriod, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Mean');
yline(avgPeriod + stdPeriod, 'r:', 'LineWidth', 1, 'DisplayName', '+1 SD');
yline(avgPeriod - stdPeriod, 'r:', 'LineWidth', 1, 'DisplayName', '-1 SD');
yline(songPeriodMs, 'k--', 'LineWidth', 2, ...
    'DisplayName', sprintf('%s Tempo (%.0f ms)', songName, songPeriodMs));
legend('Location','northeast');
title('Ring Period (ms)');
ylabel('ms');
grid on;

% === Trajectory Velocity ===
subplot(3,1,3);
plot(timeVec, validVel, 'm', 'DisplayName', 'Tracer Velocity'); hold on;
yline(avgVel, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Mean');
yline(avgVel + stdVel, 'r:', 'LineWidth', 1);
yline(avgVel - stdVel, 'r:', 'LineWidth', 1);
title('Trajectory Velocity');
xlabel('Time (sec)');
ylabel('a.u./s');
grid on;

% === Overall Title ===
sgtitle(sprintf('Ring Dynamics from 25–205 Seconds (%s Tempo = %.2f Hz / %.1f BPM)', ...
    songName, songTempoHz, songTempoBPM));


fprintf('\n===== %s (11–288 sec) =====\n', songName);
fprintf('🎵 Song Tempo: %.2f Hz | %.1f BPM | %.0f ms\n', songTempoHz, songTempoBPM, songPeriodMs);

fprintf('\n📈 Ring Frequency:\n');
fprintf('  Mean: %.3f Hz\n', avgHz);
fprintf('  Std Dev: %.3f Hz\n', stdHz);

fprintf('\n🌀 Ring Period:\n');
fprintf('  Mean: %.1f ms\n', avgPeriod);
fprintf('  Std Dev: %.1f ms\n', stdPeriod);

fprintf('\n💨 Tracer Velocity:\n');
fprintf('  Mean: %.2f a.u./s\n', avgVel);
fprintf('  Std Dev: %.2f a.u./s\n', stdVel);
fprintf('===============================\n');
