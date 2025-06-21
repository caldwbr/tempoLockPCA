videoFileName = 'ordinaryWeightsAllPCs.mp4';
videoFrameRate = 50;
stepPerFrame = 20;

frequencies = 1:60;
electrodeLabels = {'Fp1', 'Fp2', 'C3', 'C4', 'Pz', 'Fz', 'O1', 'O2', ...
                   'F7', 'F8', 'F3', 'F4', 'T3', 'Cz', 'P3', 'P4'};
numFreqs = length(frequencies);
numChannels = length(electrodeLabels);
numPCs = 16;

% Get size from one variable
dummy = evalin('base', 'PC_weights_interp_1');
[timePoints, ~, ~] = size(dummy);

% Preload all PCs into a cell array to make indexing cleaner
PC_interp_all = cell(1, numPCs);
sessionMean = zeros(numFreqs, numChannels, numPCs);

for pc = 1:numPCs
    thisVar = sprintf('PC_weights_interp_%d', pc);
    PC_interp_all{pc} = evalin('base', thisVar);
    sessionMean(:,:,pc) = squeeze(mean(PC_interp_all{pc}, 1));
end

% Setup video
v = VideoWriter(videoFileName, 'MPEG-4');
v.FrameRate = videoFrameRate;
open(v);

% Colormap
colors = flipud(jet(numPCs));  % PC1 = red, PC16 = blue

% Setup figure
figure('Color', 'w', 'Position', [100 100 1600 1000]);

% Grid layout for bar positions
[xGrid, yGrid] = meshgrid(0:3, 0:3);
xOffsets = xGrid(:) * 0.05;
yOffsets = yGrid(:) * 0.05;

% Main loop
for t = 1:stepPerFrame:(timePoints - 1)
    clf;
    hold on;

    for fi = 1:numFreqs
        for ch = 1:numChannels
            xBase = frequencies(fi);
            yBase = ch;

            for pc = 1:numPCs
                val = PC_interp_all{pc}(t, fi, ch);
                zAvg = sessionMean(fi, ch, pc);

                xo = xOffsets(pc);
                yo = yOffsets(pc);

                % Bar
                fill3([xBase+xo, xBase+xo, xBase+xo+0.03, xBase+xo+0.03], ...
                      [yBase+yo, yBase+yo, yBase+yo, yBase+yo], ...
                      [0, val, val, 0], colors(pc,:), 'EdgeColor', 'none');

                % Session average line
                plot3([xBase+xo+0.015, xBase+xo+0.015], ...
                      [yBase+yo, yBase+yo], ...
                      [0, zAvg], '-', 'Color', [0 0 0], 'LineWidth', 0.5);
            end
        end
    end

    view(3);
    axis([1 61 1 numChannels+1 -1 1]);
    xlabel('Frequency (Hz)');
    ylabel('Channel');
    zlabel('Weight');
    title(sprintf('All 16 PCs Weights at t = %.2f sec', t/1000));
    yticks(1:numChannels);
    yticklabels(electrodeLabels);
    set(gca, 'FontSize', 12);
    grid on;
    drawnow;

    frame = getframe(gcf);
    writeVideo(v, frame);
end

close(v);
