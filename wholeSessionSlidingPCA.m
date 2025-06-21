%sliding PCA
%% PARAMETERS
Fs = 1000;
windowMs = 2000; % 2 sec window
halfWin = windowMs / 2;
sigmaMs = 500; % Gaussian sigma ~0.5 sec
timePoints = size(ampEnvelopeAll,1);
nChannels = size(ampEnvelopeAll,2);
nPCs = 3; % We want PC1-PC3

% Pad data (mirror padding)
ampPadded = padarray(ampEnvelopeAll, [halfWin 0], 'replicate', 'both');
timePointsPadded = size(ampPadded,1);

% Precompute Gaussian window
tVec = (-halfWin+1):(halfWin);
gaussWin = exp(-0.5 * (tVec/sigmaMs).^2);
gaussWin = gaussWin(:);
gaussWin = gaussWin / sum(gaussWin);

% Initialize output
PC_weights = zeros(timePoints, nChannels, nPCs); % time x channels x PCs

%% SLIDING WINDOW PCA
for t = 1:timePoints
    % Extract window
    dataWin = ampPadded(t:t+windowMs-1, :);
    
    % Apply Gaussian weighting to each channel
    weightedData = dataWin .* gaussWin;
    
    % Avoid log(0)
    weightedData(weightedData < 0.0001) = 0.0001;
    ampLog = log10(weightedData);
    
    % Z-score normalize
    ampZ = zscore(ampLog);
    
    % PCA
    [coeff, ~, ~] = pca(ampZ);
    
    % Store PC1-PC3 loadings, normalized
    for pcIdx = 1:nPCs
        pcVec = coeff(:, pcIdx);
        pcVec_norm = pcVec / norm(pcVec);
        PC_weights(t,:,pcIdx) = pcVec_norm';
    end
end

%% Convert to 3D trajectory like before
% Project original data onto time-resolved PCA weights
score_dynamic = zeros(timePoints, nPCs);

for t = 1:timePoints
    % Use ampZ from global prep (optional, or recalc local ampZ here)
    dataVec = log10(ampEnvelopeAll(t,:));
    dataVecZ = (dataVec - mean(dataVec)) ./ std(dataVec); 
    
    % Project onto time-local PCA basis
    for pcIdx = 1:nPCs
        pcVec = squeeze(PC_weights(t,:,pcIdx))';
        score_dynamic(t,pcIdx) = dot(dataVecZ, pcVec);
    end
end
