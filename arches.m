% PARAMETERS
nBeats = 929;
beatInterval_ms = 204.181;  

% Compute all beat times in ms
beatTimes_ms = round((0:nBeats-1) * beatInterval_ms);  

% Initialize cell array for beat size
beatSizes = repmat({'s'}, nBeats, 1);  % default 'small'

% Assign 'medium' every 4th beat (1-based: 1,5,9,...)
mediumIdx = 1:4:nBeats;
beatSizes(mediumIdx) = {'m'};

% Assign 'large' every 16th beat (1-based: 1,17,33,...)
largeIdx = 1:16:nBeats;
beatSizes(largeIdx) = {'l'};

% Build final beat ruler as a table for clarity
beatRuler = table((1:nBeats)', beatTimes_ms', beatSizes, ...
    'VariableNames', {'BeatNum', 'Time_ms', 'Size'});

%% Create Video
% PARAMETERS
Fs = 1000;
windowSizeSec = 5;
videoFrameRate = 50;
stepSize = round(Fs / videoFrameRate);
nFrames = floor(size(ampEnvelopeAll,1) / stepSize);
ySpacing = 5;
durationSec = size(ampEnvelopeAll,1) / Fs;

% OUTPUT
desktopPath = fullfile(getenv('HOME'), 'Desktop');
videoFileName = fullfile(desktopPath, 'BeatTroughEEG.mp4');
v = VideoWriter(videoFileName, 'MPEG-4');
v.FrameRate = videoFrameRate;
open(v);

% Setup figure
figh = figure('Position', [100, 100, 1600, 900], 'Color', 'w');

% Prepare y-labels
electrodeLabels = {'P4','P3','Cz','T3','F4','F3','F8','F7','O2','O1','Fz','Pz','C4','C3','Fp2','Fp1','Beat'};

% === PRECOMPUTE channel amplitude correction ===
ampTemp = ampEnvelopeAll;
ampTemp(ampTemp < 0.001) = 0.001;
logAmpFull = log10(ampTemp);

medians = median(logAmpFull);  % 1x16, channel-wise median log amplitude
globalMedian = median(medians);
ampCorrection = globalMedian - medians;  % shifts to center all channels

for frameNum = 1:nFrames
    cla; hold on;
    ax = gca;
    set(ax, 'Color', 'w');
    
    % Current time
    timeIdx = (frameNum-1)*stepSize + 1;
    timeSec = timeIdx / Fs;
    
    % Window range
    windowEnd = timeSec;
    windowStart = max(0, windowEnd - windowSizeSec);
    
    % Data range
    winStartIdx = max(1, round(windowStart * Fs) + 1);
    winEndIdx = min(round(windowEnd * Fs), size(ampEnvelopeAll,1));
    timeVec = (winStartIdx:winEndIdx) / Fs;

    % Plot amplitude traces (log scale + correction)
    for ch = 1:16
        yCh = 17 - ch;
        amp = ampEnvelopeAll(winStartIdx:winEndIdx, ch);
        amp(amp < 0.001) = 0.001;
        logAmp = log10(amp) + ampCorrection(ch);  % apply correction
        plot(timeVec, logAmp + yCh, 'k', 'LineWidth', 1.5);
    end
    
    % Plot chanRuler troughs
    for ch = 1:16
        yCh = 17 - ch;
        idx = chanRuler.Channel == ch;
        tTroughs = chanRuler.Time_ms(idx) / 1000;  
        mask = tTroughs >= windowStart & tTroughs <= windowEnd;
        plot(tTroughs(mask), yCh*ones(sum(mask),1), 'k.', 'MarkerSize', 8);
    end
    
    % Plot beatRuler ticks
    for i = 1:height(beatRuler)
        t = beatRuler.Time_ms(i) / 1000;
        if t >= windowStart && t <= windowEnd
            switch beatRuler.Size{i}
                case 's'
                    lw = 1.0; ht = 0.8;
                case 'm'
                    lw = 2.0; ht = 1.2;
                case 'l'
                    lw = 3.5; ht = 1.8;
            end
            plot([t t], [17-ht/2 17+ht/2], 'b', 'LineWidth', lw);
        end
    end

    % Axes and labels
    xlabel('Time (s)', 'FontSize', 14);
    ylabel('Channels + Beat', 'FontSize', 14);
    title('Beat Ruler + Channel Trough + 60Hz Envelope', 'FontSize', 16, 'FontWeight','bold');
    set(gca, 'YTick', 1:17, 'YTickLabel', electrodeLabels, 'FontSize', 12);
    xlim([windowStart windowEnd]);
    ylim([0.5 17.5]);
    grid on;
    
    drawnow;
    frame = getframe(figh);
    writeVideo(v, frame);
end

close(v);
