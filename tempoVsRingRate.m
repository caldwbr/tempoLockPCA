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
figure('Color','w','Position',[100 100 1400 600]); hold on;

% Tempo line + dots (replace blue bars)
plot(x, tempoList, '-o', ...
    'Color', [0.2 0.2 1], ...
    'MarkerFaceColor', [0.2 0.2 1], ...
    'LineWidth', 2);

% Ring rate line + dots
plot(x, ringRateList, '-o', ...
    'Color', [0.1 0.6 0.1], ...
    'MarkerFaceColor', [0.1 0.6 0.1], ...
    'LineWidth', 2);

% Error bars + shaded SD
for i = 1:nSongs
    line([x(i) x(i)], ...
         [ringRateList(i) - ringSDList(i), ringRateList(i) + ringSDList(i)], ...
         'Color', [0.1 0.6 0.1 0.3], ...
         'LineWidth', 2);
end
fillX = [x, fliplr(x)];
fillY = [ringRateList + ringSDList, fliplr(ringRateList - ringSDList)];
fill(fillX, fillY, [0.1 0.6 0.1], 'FaceAlpha', 0.1, 'EdgeColor', 'none');

% === Manual multiline labels, rotated 45º CCW ===
ylimLow = min([tempoList, ringRateList - ringSDList]) - 0.6;
ylim([0 6]);  % Lock Y-axis to 0–6 Hz

xticks([]);  % Disable default xtick labels
for i = 1:nSongs
    txt = sprintf('%s\\newline\\it{%s}', songList{i}, artistList{i});
    text(x(i), ylimLow + 0.2, txt, ...
        'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'top', ...
        'Interpreter', 'tex', ...
        'FontSize', 10, ...
        'Rotation', 45);  % Rotate CCW
end

% Labels and title
ylabel('Frequency (Hz)');
title('Song Stimulus Tempo vs. PCA Ring Rate (61.5 Hz Amplitude), Whole Cortex');
legend({'Stimulus Tempo', 'Ring Rate', '±1 SD'}, 'Location', 'northwest');
grid on;
