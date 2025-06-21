%% SETUP
Fs = 1000;
nSamples = size(ampEnvelopeAll,1);
nChannels = 16;
videoFrameRate = 50;
stepSize = round(Fs / videoFrameRate);
nFrames = floor(nSamples / stepSize);
timeVec = (0:nSamples-1) / Fs;

% Head coordinates (with your latest fixes)
headXY = [
    2,5;  4,5;  2,3;  4,3;  3,2;  3,3.7;  2,1;  4,1;
    2,3.8; 4,3.8; 1.3,4.5; 4.7,4.5; 1,3; 3,3; 2,2; 4,2
];

electrodeLabels = {'Fp1','Fp2','C3','C4','Pz','Fz','O1','O2','F7','F8','F3','F4','T3','Cz','P3','P4'};

% Rainbow colormap (wrapped phase)
nColors = 256;
hues = linspace(0,1,nColors);
cmap = hsv2rgb([hues' ones(nColors,1) ones(nColors,1)]);

% Prepare video
desktopPath = fullfile(getenv('HOME'), 'Desktop');
videoFileName = fullfile(desktopPath, 'HeadplotPhaseBeat_TRAILS_FINAL.mp4');
v = VideoWriter(videoFileName, 'MPEG-4');
v.FrameRate = videoFrameRate;
open(v);

% Setup figure handle safely
figh = figure('Position',[100 100 1200 1000],'Color','w');

% Build beat and channel lookup tables
beatTimes = beatRuler.Time_ms / 1000;
chanTimesCell = arrayfun(@(ch) chanRuler.Time_ms(chanRuler.Channel==ch)/1000, 1:16, 'UniformOutput', false);

%% MAIN VIDEO LOOP
for frameNum = 1:nFrames

    figure(figh); clf('reset'); hold on;
    timeIdx = (frameNum-1)*stepSize + 1;
    timeSec = timeIdx / Fs;

    % Generate trailing history: up to 20 steps back
    for trailStep = 0:20
        idxTrail = timeIdx - trailStep;
        if idxTrail < 1
            continue;
        end

        % Alpha transparency fades from 1 down to 0.05
        alphaFade = 1 - trailStep/21;

        % Extract amplitude at this trail point
        ampFrame = ampEnvelopeAll(idxTrail, :);
        ampFrame(ampFrame<0.0001) = 0.0001;
        logAmp = log10(ampFrame);  

        for ch = 1:16
            % Calculate phase-based color
            [~, iBeat] = min(abs(beatTimes - timeSec));
            beatTime = beatTimes(iBeat);
            chanTimes = chanTimesCell{ch};

            if isempty(chanTimes)
                deltaT = 0;
            else
                [~, iChan] = min(abs(chanTimes - beatTime));
                deltaT = chanTimes(iChan) - beatTime;
            end

            % Normalize deltaT into full beat cycle window [-beatDur/2, +beatDur/2]
            beatDur = 204.181 / 1000; % seconds per beat
            wrappedDelta = mod(deltaT + beatDur/2, beatDur) - beatDur/2;

            % Convert to phase fraction [0,1]
            phaseFrac = mod((wrappedDelta / beatDur) + 0.5, 1);
            colorIdx = round(phaseFrac * (nColors-1)) + 1;
            baseColor = cmap(colorIdx,:);

            % Apply fading
            fadedColor = baseColor * alphaFade + (1-alphaFade);  % soften into white background

            % Plot sphere
            [X,Y,Z] = sphere(20);
            radius = 0.1;
            surf(radius*X + headXY(ch,1), ...
                 radius*Y + headXY(ch,2), ...
                 logAmp(ch) + radius*Z, ...
                 'FaceColor', fadedColor, 'EdgeColor', 'none', 'FaceAlpha', alphaFade);
        end
    end

    % Plot labels (only at most recent position, no fading here)
    ampFrame = ampEnvelopeAll(timeIdx, :);
    ampFrame(ampFrame<0.0001) = 0.0001;
    logAmp = log10(ampFrame);  

    for ch = 1:16
        text(headXY(ch,1), headXY(ch,2), logAmp(ch) + 0.5, electrodeLabels{ch}, ...
    'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
    end

    % Plot settings
    axis equal
    view([45 30])
    xlabel('X'); ylabel('Y'); zlabel('log_{10} Amplitude');
    title(sprintf('Time: %.3f sec', timeSec),'FontSize',16);
    xlim([0 6]); ylim([0 6]); zlim([-4 3]); % log10 range

    % Log tick labels for z-axis
    zTicks = -4:1:3;
    zTickLabels = arrayfun(@(x) sprintf('%.4g',10.^x), zTicks,'UniformOutput',false);
    set(gca,'ZTick',zTicks,'ZTickLabel',zTickLabels);

    drawnow;
    frame = getframe(figh);
    writeVideo(v, frame);
end

close(v);
