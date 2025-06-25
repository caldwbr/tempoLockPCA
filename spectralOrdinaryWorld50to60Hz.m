%% MORE LIKELY THE CODE USED, SAVES WEIGHTS
% === PARAMETERS ===
nPCs = 16;
nCoarse = 300; % Number of coarse timepoints
halfWin = round(800 / 2); % 800 ms window
sigmaMs = 200;
timePoints = size(ampEnvelopeAll, 1);
numChannels = size(ampEnvelopeAll, 2);
numFreqs = size(ampEnvelopeAll, 3);
%frequencies = evalin('base', 'freqs_01');  % <--- Use actual frequency values

coarseIdx = round(linspace(1, timePoints, nCoarse));
gaussWin = exp(-0.5 * ((-halfWin+1):(halfWin))'.^2 / sigmaMs^2);
gaussWin = gaussWin / sum(gaussWin);

% === PREALLOCATE ===
for pcIdx = 1:nPCs
    eval(sprintf('PC_scores_%d = zeros(timePoints, numFreqs);', pcIdx));
end

PC_weights_all = cell(1, nPCs);
for pcIdx = 1:nPCs
    PC_weights_all{pcIdx} = zeros(timePoints, numFreqs, numChannels);
end

% === MAIN LOOP OVER FREQUENCIES ===
for fi = 1:numFreqs
    disp(['Processing frequency: ' sprintf('%.1f', frequencies(fi)) ' Hz']);
    
    ampThisFreq = ampEnvelopeAll(:,:,fi);
    PC_weights_coarse = zeros(nCoarse, numChannels, nPCs);
    
    % === PCA per COARSE TIMEPOINT ===
    for i = 1:nCoarse
        t = coarseIdx(i);
        tStart = max(1, t - halfWin + 1);
        tEnd = min(timePoints, t + halfWin);
        idxActual = (tStart:tEnd)';
        gwActual = gaussWin((tStart-t+halfWin):(tEnd-t+halfWin));

        dataWin = ampThisFreq(idxActual, :);
        weightedData = dataWin .* gwActual;
        weightedData(weightedData < 0.0001) = 0.0001;
        dataLog = log10(weightedData);
        dataZ = zscore(dataLog);

        [coeff, ~, ~] = pca(dataZ);

        for pcIdx = 1:nPCs
            pcVec = coeff(:, pcIdx);
            pcVec_norm = pcVec / norm(pcVec);
            PC_weights_coarse(i,:,pcIdx) = pcVec_norm';
        end
    end

    % === INTERPOLATE WEIGHTS TO ALL TIMEPOINTS AND SAVE ===
    for pcIdx = 1:nPCs
        for ch = 1:numChannels
            coarseVals = squeeze(PC_weights_coarse(:,ch,pcIdx));
            interpVals = interp1(coarseIdx, coarseVals, 1:timePoints, 'pchip', 'extrap');
            PC_weights_all{pcIdx}(:, fi, ch) = interpVals(:);
        end
    end

    % === PROJECT DATA ONTO INTERPOLATED WEIGHTS (SCORES) ===
    for t = 1:timePoints
        dataVec = log10(max(ampThisFreq(t,:), 0.0001));
        dataVecZ = (dataVec - mean(dataVec)) ./ std(dataVec);
        for pcIdx = 1:nPCs
            pcVec = squeeze(PC_weights_all{pcIdx}(t, fi, :))';
            pcScore = dot(dataVecZ, pcVec);
            eval(sprintf('PC_scores_%d(t,fi) = pcScore;', pcIdx));
        end
    end
end

% === SAVE TO WORKSPACE ===
for pcIdx = 1:nPCs
    assignin('base', sprintf('PC_weights_interp_%d', pcIdx), PC_weights_all{pcIdx});
end
