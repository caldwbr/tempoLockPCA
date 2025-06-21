%Likely the video code for spectral Ordinary World 50-60 Hz amp dyn PCA 
%% SETTINGS
Fs = 1000;
trailDurationSec = 0.25;
trailLength = round(trailDurationSec * Fs);
videoFrameRate = 50;
stepSize = round(Fs / videoFrameRate);
nFrames = floor(340181 / stepSize);
frequencies = 1:60;
nFreqs = length(frequencies);
colorMap = jet(nFreqs);  % 1 Hz = blue, 60 Hz = red
shiftAmount = 6;

% Load PC scores
PC1 = evalin('base', 'PC_scores_1');
PC2 = evalin('base', 'PC_scores_2');
PC3 = evalin('base', 'PC_scores_3');

%% Reorganize into scoresByFreq{f} = [PC1(t,f), PC2(t,f), PC3(t,f)]
scoresByFreq = cell(1, nFreqs);
for f = 1:nFreqs
    scoresByFreq{f} = [PC1(:,f), PC2(:,f), PC3(:,f)];
end

% Offsets for spatial and time staggering
pc1Offsets = (60 - frequencies) * 0.05;
timeOffsets = (60 - frequencies) * 5;

%% Determine plot limits (log-transformed)
allTrail = [];
for f = 1:nFreqs
    s = scoresByFreq{f};
    s(:,1) = s(:,1) + pc1Offsets(f);
    s = log10(s + shiftAmount);
    allTrail = [allTrail; s];
end
xMin = min(allTrail(:,1)); xMax = max(allTrail(:,1));
yMin = min(allTrail(:,2)); yMax = max(allTrail(:,2));
zMin = min(allTrail(:,3)); zMax = max(allTrail(:,3));

%% INIT FIGURE & VIDEO
figure('Color','k','Position',[100 100 1200 900]);
v = VideoWriter('ordinaryRings.mp4', 'MPEG-4');
v.FrameRate = videoFrameRate;
open(v);

%% FRAME LOOP
for iFrame = 1:nFrames
    clf; hold on;
    tNow = (iFrame - 1) * stepSize + 1;

    for f = 1:nFreqs
        scores = scoresByFreq{f};
        color = colorMap(f,:);
        tOffset = round(timeOffsets(f));
        xOffset = pc1Offsets(f);

        tUse = tNow - tOffset;
        if tUse < trailLength + 1 || tUse > size(scores,1)
            continue;
        end

        trailIdx = (tUse - trailLength + 1):tUse;
        trail = scores(trailIdx,:);
        trail(:,1) = trail(:,1) + xOffset;

        trailLog = log10(trail + shiftAmount);
        pt = scores(tUse,:); pt(1) = pt(1) + xOffset;
        ptLog = log10(pt + shiftAmount);

        plot3(trailLog(:,1), trailLog(:,2), trailLog(:,3), '-', ...
              'Color', color, 'LineWidth', 1.4);
        plot3(ptLog(1), ptLog(2), ptLog(3), 'o', ...
              'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'MarkerSize', 6);
    end

    axis([xMin xMax yMin yMax zMin zMax]);
    set(gca, 'Color', 'k', 'Visible', 'off');
    view(30 + 0.25 * iFrame, 20);

    writeVideo(v, getframe(gcf));
end

close(v);
disp('🔥 ordinaryRings.mp4 done. Import into Premiere, blast Ordinary World.');
