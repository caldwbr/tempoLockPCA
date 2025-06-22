


% === DATA ===
songList = {'Threshold', 'Teen Spirit', 'Horse with No Name', 'Espresso', ...
            'Ocean Eyes', 'Physical', 'I Could Fall in Love', 'Dreaming of You', ...
            'Old Fashioned Love Song', 'Ordinary World', 'Alone'};

artistList = {'Sungazer', 'Nirvana', 'America', 'Carpenter', ...
              'Eilish', 'Dua Lipa', 'Selena Quintanilla', 'Selena Quintanilla', ...
              'Three Dog Night', 'Duran Duran', 'Heart'};

tempoList = [4.29 4.91 4.064 3.383 4.64 4.783 5.025 5.498 3.365 4.68 5.84];
ringRateList = [5.181 5.142 5.149 5.116 5.159 5.163 5.149 5.174 5.184 5.174 5.09];
ringSDList = [0.0 0.254 0.055 0.052 0.040 0.092 0.184 0.312 0.328 0.312 0.208];

nSongs = numel(songList);
x = 1:nSongs;

% === PLOT ===
figure('Color','w','Position',[100 100 1600 700]); hold on;

% Tempo line + dots
plot(x, tempoList, '-o', ...
    'Color', [0.2 0.2 1], ...
    'MarkerFaceColor', [0.2 0.2 1], ...
    'LineWidth', 4);  % thicker line

% Ring rate line + dots
plot(x, ringRateList, '-o', ...
    'Color', [0.1 0.6 0.1], ...
    'MarkerFaceColor', [0.1 0.6 0.1], ...
    'LineWidth', 4);

% Error bars + shaded SD
for i = 1:nSongs
    line([x(i) x(i)], ...
         [ringRateList(i) - ringSDList(i), ringRateList(i) + ringSDList(i)], ...
         'Color', [0.1 0.6 0.1 0.3], ...
         'LineWidth', 3);
end
fillX = [x, fliplr(x)];
fillY = [ringRateList + ringSDList, fliplr(ringRateList - ringSDList)];
fill(fillX, fillY, [0.1 0.6 0.1], 'FaceAlpha', 0.1, 'EdgeColor', 'none');

% === Manual labels with right-edge alignment for artist ===
ylimLow = min([tempoList, ringRateList - ringSDList]) - 0.6;
ylim([0 6]);  % Lock Y-axis

xticks([]);  % Disable default xtick labels
for i = 1:nSongs
    baseX = x(i);
    baseY = ylimLow + 0.2;

    % Song Title
    text(baseX, baseY + 0.2, songList{i}, ...
        'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'top', ...
        'FontSize', 20, ...
        'Rotation', 45);

    % Artist Name (manually nudged to match right edge of title)
    offsetX = 0.13;  % tweak this to shift artist right
    offsetY = 0.08;  % tweak this to shift artist upward
    text(baseX + offsetX, baseY, ['\it' artistList{i}], ...
        'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'top', ...
        'FontSize', 20, ...
        'Interpreter', 'tex', ...
        'Rotation', 45);
end




% Labels and title (scaled up)
ylabel('Frequency (Hz)', 'FontSize', 24);
title('Song Stimulus Tempo vs. PCA Ring Rate (61.5 Hz Amplitude), Whole Cortex', 'FontSize', 26);
legend({'Stimulus Tempo', 'Ring Rate', '±1 SD'}, 'Location', 'northwest', 'FontSize', 18);
set(gca, 'FontSize', 18);  % Axes tick font size
grid on;

