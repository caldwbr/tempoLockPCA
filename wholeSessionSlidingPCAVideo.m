%Movie dynamic pca
%% MOVIE SETTINGS

trailDurationSec = 0.3; % how many seconds of trailing tail to show
trailLength = trailDurationSec * Fs;
videoFrameRate = 50; % frames per second
stepSize = round(Fs / videoFrameRate);
nFrames = floor(timePoints / stepSize);

% Get axis limits for consistent view
buffer = 0.2;
sampleWindow = score_dynamic(20*Fs:30*Fs,:); % same as before
pcMin = min(sampleWindow);
pcMax = max(sampleWindow);
pcRange = pcMax - pcMin;
pcMin = pcMin - buffer * pcRange;
pcMax = pcMax + buffer * pcRange;

%% CREATE MOVIE

figure('Position',[100 100 1000 800],'Color','w');
filename = 'entireGNBSsongsSession.mp4';
v = VideoWriter(filename, 'MPEG-4');
v.FrameRate = videoFrameRate;
open(v);

for iFrame = 1:nFrames
    clf;
    hold on;
    
    % Current time index
    tNow = (iFrame-1)*stepSize + 1;
    idxStart = max(1, tNow - trailLength);
    idxTrail = idxStart:tNow;
    
    % Plot full trajectory faint in background
    %plot3(score_dynamic(:,1), score_dynamic(:,2), score_dynamic(:,3), '-', 'Color', [0.9 0.9 0.9], 'LineWidth', 0.1);
    
    % Plot trail
    plot3(score_dynamic(idxTrail,1), score_dynamic(idxTrail,2), score_dynamic(idxTrail,3), 'b-', 'LineWidth', 2);
    
    % Current point
    plot3(score_dynamic(tNow,1), score_dynamic(tNow,2), score_dynamic(tNow,3), 'ro', 'MarkerFaceColor','r','MarkerSize',8);
    
    xlabel('PC 1','FontSize',14);
    ylabel('PC 2','FontSize',14);
    zlabel('PC 3','FontSize',14);
    title(sprintf('Sliding PCA Frame %d', iFrame), 'FontSize',16);
    
    grid on;
    axis equal;
    xlim([-2 2]);
    ylim([-5 5]);
    zlim([-4 4]);
    view([30 20]);
    box on;
    % (inside your for-loop)

    % Calculate rotating azimuth
    az0 = 30;
    el0 = 20;
    rotationPerFrame = 0.05;
    az = az0 + rotationPerFrame * iFrame;
    view([az el0]);

    frame = getframe(gcf);
    writeVideo(v, frame);
end

close(v);
