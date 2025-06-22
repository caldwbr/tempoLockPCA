%% ==== LOOP 1: MESSY RING DETECTION ====
pc1 = PC_scores_2;
pc2 = PC_scores_1;
pc3 = PC_scores_3;
Fs = 1000;  % sampling rate (Hz)
trailLength = 200;  % trail duration in ms
dataStepSize = 1;  % ms resolution for math
videoStepSize = 20;  % ms resolution for video frames
startTimeSec = 893.7200;  % adjust if needed

% Preallocate output vars
N = length(pc1);
phases = NaN(N,1);
velocities = NaN(N,1);
ringTimes = [];

% === Smooth PC1 for peak detection ===
pc1Smooth = movmean(pc1, 21);

% === Peak detection for PC1 oscillation ===
[~, peaks] = findpeaks(pc1Smooth);
[~, troughs] = findpeaks(-pc1Smooth);
allExtrema = sort([peaks; troughs]);

lastRingTime = -Inf;
minInterval = 160;  % ms

for i = 2:length(allExtrema)-1
    t1 = allExtrema(i-1);
    t2 = allExtrema(i);
    t3 = allExtrema(i+1);

    if t3 - lastRingTime < minInterval
        continue;
    end

    % Check for oscillatory cycle: min -> max -> min or max -> min -> max
    if (pc1Smooth(t1) < pc1Smooth(t2) && pc1Smooth(t3) < pc1Smooth(t2)) || ...
       (pc1Smooth(t1) > pc1Smooth(t2) && pc1Smooth(t3) > pc1Smooth(t2))
        ringTimes(end+1) = t3;
        lastRingTime = t3;
    end
end

% === Compute ring stats ===
ringPeriodMs = NaN(N,1);
ringRateHz = NaN(N,1);
ringRateBPM = NaN(N,1);

for i = 2:length(ringTimes)
    t = ringTimes(i);
    dt = ringTimes(i) - ringTimes(i-1);
    hz = Fs / dt;
    ringPeriodMs(t) = dt;
    ringRateHz(t) = hz;
    ringRateBPM(t) = hz * 60;
end

% Optional smoothing/interpolation of ring stats
ringPeriodMs = fillmissing(ringPeriodMs, 'previous');
ringRateHz = fillmissing(ringRateHz, 'previous');
ringRateBPM = fillmissing(ringRateBPM, 'previous');

% === Compute velocity ===
for t = 2:N
    prev = [pc1(t-1), pc2(t-1), pc3(t-1)];
    curr = [pc1(t), pc2(t), pc3(t)];
    velocities(t) = norm(curr - prev) * Fs;
end

%% === LOOP 2: VIDEO ===
v = VideoWriter('Teen_Spirit_Ring_Tracking.mp4', 'MPEG-4');
v.FrameRate = 1000 / videoStepSize;
open(v);

figure('Color','k','Position',[100 100 1200 900]);

for t = trailLength+1 : videoStepSize : (N-1)
    idx = (t - trailLength) : t;
    if any(idx <= 0 | idx > N)
        continue;
    end

    tail = [pc1(idx), pc2(idx), pc3(idx)];
    [coeff, ~, ~] = pca(tail);
    center = mean(tail);

    % Plane patch
    [xg, yg] = meshgrid(-4:0.4:4, -4:0.4:4);  % was -1:0.1:1
    planePatch = [xg(:), yg(:)] * coeff(:,1:2)' + center;
    patchX = reshape(planePatch(:,1), size(xg));
    patchY = reshape(planePatch(:,2), size(yg));
    patchZ = reshape(planePatch(:,3), size(yg));

    % Plot
    clf; hold on;
    plot3(pc1(idx), pc2(idx), pc3(idx), 'Color', [1 1 1 0.4], 'LineWidth', 1.5);
    scatter3(pc1(t), pc2(t), pc3(t), 60, 'r', 'filled');
    surf(patchX, patchY, patchZ, 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'FaceColor', 'cyan');

    % Degree Labels (truly stuck to plane)
    radius = 2.0;
    angles = 0:pi/2:(2*pi - pi/2);
    angleLabels = {'0°','90°','180°','270°'};
    for i = 1:length(angles)
        a = angles(i);
        localPt = [radius * cos(a), radius * sin(a)];    % In-plane 2D point
        globalPt = coeff(:,1:2) * localPt(:) + center(:); % Convert to 3D world coords
        text(globalPt(1), globalPt(2), globalPt(3), angleLabels{i}, ...
             'Color','yellow','FontSize',10, ...
             'HorizontalAlignment','center', ...
             'VerticalAlignment','middle');
    end

    % Title and info
    currentTime = startTimeSec + t/Fs;
    timeStr = datestr(seconds(currentTime), 'MM:SS.FFF');
    hz = ringRateHz(t);
    bpm = ringRateBPM(t);
    period = ringPeriodMs(t);
    vel = velocities(t);

    % Stabilized Title String with Fixed Widths
    hzStr     = sprintf('Freq = %6.3f Hz',   hz);
    bpmStr    = sprintf('BPM  = %6.1f',      bpm);
    periodStr = sprintf('Period = %6.1f ms', period);
    velStr    = sprintf('Velocity = %7.2f a.u./s', vel);

    % Combine all info with fixed-width spacing
    titleStr = sprintf('Time: %s   |   %s   |   %s   |   %s   |   %s', ...
        timeStr, hzStr, bpmStr, periodStr, velStr);

    title(titleStr, 'Color', 'w', 'FontSize', 12, 'FontName', 'Courier');


    axis equal;
    grid on;
    az = mod(30 + 0.02 * (t - trailLength), 360);  % slow azimuthal spin
    el = 20;  % fixed elevation
    view(az, el);
    set(gca,'Color','k','XColor','w','YColor','w','ZColor','w');
    xlim([-8 8]); ylim([-8 8]); zlim([-8 8]);
    xlabel('PC1'); ylabel('PC2'); zlabel('PC3');
    drawnow;

    writeVideo(v, getframe(gcf));
end

close(v);

