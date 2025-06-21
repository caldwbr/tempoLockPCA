% Likely similar to code used for Teen Spirit Video (50:0.5:60 Hz amplitude PCA run every 100 ms, weights interpolated to each millisecond).
%% SETTINGS
Fs = 1000;
trailDurationSec = 0.20;
trailLength = round(trailDurationSec * Fs);
videoFrameRate = 50;
stepSize = round(Fs / videoFrameRate);
nFrames = floor(timePoints / stepSize);
%frequencies = freqs_01;
nFreqs = length(frequencies);


% % 🎨 Full 60-color "Duran Duran" colormap
% colors1 = [linspace(0, 0.2, 20)', linspace(0, 0.1, 20)', linspace(0.5, 1, 20)'];       % Dark blue to electric blue
% colors2 = [linspace(0.2, 0.9, 20)', linspace(0.1, 0.1, 20)', linspace(1, 0.6, 20)'];   % Blue to purplish pink
% colors3 = [linspace(0.9, 1, 20)', linspace(0.1, 0, 20)', linspace(0.6, 0.3, 20)'];     % Pink to hot magenta
% duranColormap = [colors1; colors2; colors3];  % 60x3 colormap

% % Teen Spirit 5-color grunge colormap (RGB 0–1)
% colorMap = [
%     0.102, 0.089, 0.071;  % shadow brown (lamp background)
%     0.600, 0.490, 0.298;  % golden tan (face highlight)
%     0.847, 0.712, 0.349;  % light yellow (sweater stripe)
%     0.259, 0.204, 0.133;  % earthy midtone (shirt & wall hue)
%     0.392, 0.157, 0.098   % tom drum red-brown (from this new image)
% ];
% colorIdx = mod(0:nFreqs-1, size(colorMap,1)) + 1;
% colorMap = colorMap(colorIdx, :);

% colorMap = [
%     0.113, 0.490, 0.741;  % vibrant pool blue
%     0.792, 0.792, 0.792;  % off-white newspaper
%     0.341, 0.717, 0.847;  % aqua cyan from baby highlight
%     0.019, 0.215, 0.396;  % deep pool shadow blue
%     0.717, 0.792, 0.678;  % greenish paper tint
%     0.866, 0.803, 0.360   % yellow from dollar bill
% ];
% colorMap = interp1(1:size(colorMap,1), colorMap, linspace(1, size(colorMap,1), 21), 'pchip');

% Make sure freqs_01 is defined and gives you 101 frequencies
%frequencies = freqs_01;
nFreqs = length(frequencies);  % Should be 101

% % Your base 5-color palette from image
% baseMap = [
%     0.004, 0.627, 0.792;  % vibrant pool blue
%     0.043, 0.345, 0.607;  % deep pool shadow blue
%     0.047, 0.424, 0.533;  % greenish paper tint
%     0.812, 0.745, 0.129;  % yellow from dollar bill
%     0.870, 0.850, 0.810   % offwhite newspaper
% ];
% 
% % Interpolate up to 101 colors
% colorMap = interp1(1:size(baseMap,1), baseMap, linspace(1, size(baseMap,1), nFreqs), 'pchip');
% 
% % Defensive check
% if size(colorMap,1) ~= nFreqs || size(colorMap,2) ~= 3
%     error('ColorMap interpolation failed: size is %dx%d, expected %dx3', ...
%           size(colorMap,1), size(colorMap,2), nFreqs);
% end

% % 🎯 Resample 60-color colormap to match 11 frequencies
% colorIdx = round(linspace(1, 60, nFreqs));
% colorMap = duranColormap(colorIdx, :);

% % === NEBULA HARDCODED ===
% nebula256 = [ % RGB rows, 0–1 fits carpenter fine
%     0.99, 0.01, 0.34
%     0.6, 0.16, 0.69
%     0.01, 0.53, 0.98
% ]; % You can extend this list to 256 rows (full nebula)

% nebula256 = [
%     0.22, 0.27, 0.42
%     0.85, 0.43, 0.33
%     0.95, 0.83, 0.71
% ];

% nebula256 = [
%     0,         0,    0.5000   % dark blue
%     0,         0,    1.0000   % blue
%     0,    1.0000,    1.0000   % cyan
%     1.0000,    1.0000,    0   % yellow
%     1.0000,         0,         0   % red
% 
% ];

nebula256 = [
    0.95, 0.7, 0.7
    0.80, 0.5, 0.5
    0.65, 0.3, 0.3
]

% Interpolate to match number of frequencies
colorMap = interp1(1:size(nebula256,1), nebula256, linspace(1, size(nebula256,1), nFreqs), 'pchip');

% Check
if size(colorMap,1) ~= nFreqs || size(colorMap,2) ~= 3
    error('ColorMap interpolation failed: got %dx%d, expected %dx3', ...
          size(colorMap,1), size(colorMap,2), nFreqs);
end


shiftAmount = 6;

% Load PC scores
PC1 = evalin('base', 'PC_scores_1');
PC2 = evalin('base', 'PC_scores_2');
PC3 = evalin('base', 'PC_scores_3');

%% Reorganize into scoresByFreq{f} = [PC1(t,f), PC2(t,f), PC3(t,f)]
scoresByFreq = cell(1, nFreqs);
for idx = 1:nFreqs
    f = frequencies(idx);
    scoresByFreq{idx} = [PC1(:,idx), PC2(:,idx), PC3(:,idx)];
end

% Offsets for spatial and time staggering
pc1Offsets = (10.0 - frequencies) * 0;
timeOffsets = (10.0 - frequencies) * 0;

%% Determine plot limits (log-transformed)
allTrail = [];
for idx = 1:nFreqs
    s = scoresByFreq{idx};
    s(:,1) = s(:,1) + pc1Offsets(idx);
    s = log10(s + shiftAmount);
    allTrail = [allTrail; s];
end
xMin = min(allTrail(:,1)); xMax = max(allTrail(:,1));
yMin = min(allTrail(:,2)); yMax = max(allTrail(:,2));
zMin = min(allTrail(:,3)); zMax = max(allTrail(:,3));

%% INIT FIGURE & VIDEO
figure('Color','k','Position',[100 100 1200 900]);
v = VideoWriter('teenSpiritBeta.mp4', 'MPEG-4');
v.FrameRate = videoFrameRate;
open(v);



%% FRAME LOOP with single rotating view
initialAzimuth = 0;
elevation = 20;  % fixed elevation angle (you can tweak this)
azimuthStep = 360 / nFrames;  % one full rotation over all frames

for iFrame = 1:nFrames
    clf;
    hold on;

    tNow = (iFrame - 1) * stepSize + 1;

    for idx = 1:nFreqs
        scores = scoresByFreq{idx};
        color = colorMap(idx,:);
        tOffset = round(timeOffsets(idx));
        xOffset = pc1Offsets(idx);

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
              'Color', color, 'LineWidth', 2.4);
        plot3(ptLog(1), ptLog(2), ptLog(3), 'o', ...
              'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'MarkerSize', 7);
    end

    % Set view: azimuth rotates over time
    azimuth = initialAzimuth + azimuthStep * (iFrame - 1);
    view(azimuth, elevation);

    axis([xMin xMax yMin yMax zMin zMax]);
    set(gca, 'Color', 'k', 'XColor', 'none', 'YColor', 'none', 'ZColor', 'none');
    grid off;

    % Record frame
    frame = getframe(gcf);
    writeVideo(v, frame);
end

close(v);
