% Likely the file used for Ordinary World 50-60 Hz amp dyn pca. nCoarse might be off.
%% BIG GOOD DYN PCA 800 ms
% === Parameters ===
nPCs = 16;
nCoarse = 300; % Number of coarse timepoints (adjust as needed)
coarseIdx = round(linspace(1, timePoints, nCoarse));
halfWin = round(800 / 2);
sigmaMs = 200;
gaussWin = exp(-0.5 * ((-halfWin+1):(halfWin))'.^2 / sigmaMs^2);
gaussWin = gaussWin / sum(gaussWin);

% === Initialize PC score storage ===
for pcIdx = 1:nPCs
    eval(sprintf('PC_scores_%d = zeros(timePoints, numFreqs);', pcIdx));
end

% === Main Loop ===
for fi = 1:numFreqs
    disp(['Processing frequency: ' num2str(frequencies(fi)) ' Hz']);
    
    ampThisFreq = ampEnvelopeAll(:,:,fi);
    PC_weights_coarse = zeros(nCoarse, numChannels, nPCs);
    
    % Coarse timepoint PCA
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

    % Interpolate weights to all timepoints
    PC_weights_interp = zeros(timePoints, numChannels, nPCs);
    for ch = 1:numChannels
        for pcIdx = 1:nPCs
            coarseVals = squeeze(PC_weights_coarse(:,ch,pcIdx));
            PC_weights_interp(:,ch,pcIdx) = interp1(coarseIdx, coarseVals, 1:timePoints, 'pchip', 'extrap');
        end
    end

    % Project onto weights and store each PC separately
    for t = 1:timePoints
        dataVec = log10(max(ampThisFreq(t,:), 0.0001));
        dataVecZ = (dataVec - mean(dataVec)) ./ std(dataVec);
        for pcIdx = 1:nPCs
            pcVec = squeeze(PC_weights_interp(t,:,pcIdx))';
            pcScore = dot(dataVecZ, pcVec);
            eval(sprintf('PC_scores_%d(t,fi) = pcScore;', pcIdx));
        end
    end
end
