function [outputData, highData, gamma_vals, gamma_locs] = ...
    bsPostReBuildMulTraceCSR(GInvParam, GSParam, invData, inputData, inIds, crossIds, options)

    [sampNum, traceNum] = size(inputData);
    
    K = options.nMultipleTrace;
    
%     GSParam = bsInitDLSRPkgs(GSParam, options.gamma, sampNum, options);
    [GSParam] = bsInitGSparseParam(GSParam, sampNum, K, [], 2);
    
        % tackle the inverse task
    outputData = zeros(sampNum, traceNum);
    highData = zeros(sampNum, traceNum);
    gamma_vals = zeros(GSParam.sparsity * GSParam.ncell, traceNum);
    gamma_locs = zeros(GSParam.sparsity * GSParam.ncell, traceNum);
    
    dt = GInvParam.dt;

    pbm = bsInitParforProgress(GInvParam.numWorkers, ...
        traceNum, ...
        'Rebuid data progress information', ...
        GInvParam.modelSavePath, ...
        GInvParam.isPrintBySavingFile);

    if ~isfield(GSParam, 'wellPos')
        GSParam.wellPos = [];
    end
    
    n = traceNum * options.ratio_to_reconstruction;
    seqs = unique([round(linspace(1, traceNum, n)), GSParam.wellPos]);
    seqs = sort(seqs);
    
    
    % 获取工区范围
    [rangeInline, rangeCrossline] = bsGetWorkAreaRangeByParam(GInvParam);
    nRangeInline = rangeInline(2) - rangeInline(1) + 1;
    nRangeCrossline = rangeCrossline(2) - rangeCrossline(1) + 1;
    
    if nRangeInline > nRangeCrossline
        nTracePerLine = nRangeInline;
    else
        nTracePerLine = nRangeCrossline;
    end
    
    iterTrace = 1;
    
    if K == 1
        fcn = @(iTrace) iTrace;
    else
        fcn = @(iTrace) bsFindNearestKTrace(iTrace, inIds, crossIds, K, nTracePerLine);
    end
    
	for iTrace = seqs
        % 找当前当的所有邻近道
        ids = fcn(iTrace);
%             ids = bsFindNearestKTrace(iTrace, inIds, crossIds, K, nTracePerLine);
%         nlm_ps = bsGetNonLocalSimilarPatches(inputData(:, iTrace), inputData(:, ids), GSParam.sizeAtom, 10);
        [highData(:, iTrace), t_gammas] = bsSparsePredictOneTrace(GSParam, {invData(:, ids)}, inIds(ids), crossIds(ids));

        if ~options.is3D
            [gamma_vals(:, iTrace), gamma_locs(:, iTrace)] = bsGetNonZeroElements(t_gammas, GSParam.sparsity);
        end

        bsIncParforProgress(pbm, iterTrace, 10000);
        iterTrace = iterTrace + 1;
	end

    % 给未高分辨率的道插值
    if options.ratio_to_reconstruction < 1 && traceNum > 1
        [X, Y] = meshgrid(seqs, 1:sampNum);
        [Xq,Yq] = meshgrid(1:traceNum, 1:sampNum);

        highData = interp2(X, Y, highData(:, seqs), Xq, Yq, 'spline');
    end
    
    if ~isempty(options.gst_options)
        if options.is3D
            nInline = max(inIds(:)) - min(inIds(:)) + 1;
            nCrossline = max(crossIds(:)) - min(crossIds(:)) + 1;

            highData = bsSmoothByGST3D(bsReshapeDataAs3D(highData, nInline, nCrossline), bsReshapeDataAs3D(inputData, nInline, nCrossline), options.gst_options);
            highData = bsReshapeDataAs2D(highData);
        else
            highData = bsSmoothByGST2D(highData, invData, options.gst_options);
        end
    end
    
    % parallel computing
    parfor iTrace = 1 : traceNum
        outputData(:, iTrace) = bsHandleOneTrace(invData(:, iTrace), highData(:, iTrace), options, dt);
        bsIncParforProgress(pbm, iTrace, 10000);
    end

    bsDeleteParforProgress(pbm);
    
end



% function [avgLog, gamma_vals, gamma_locs] = bsCalcHighFreqOfOneTrace(GSParam, realData, x, y, options)
%     ncell = GSParam.ncell;
%     trainDICParam = GSParam.trainDICParam;
%     
%     nSpecialFeat = trainDICParam.isAddLocInfo *2 + trainDICParam.isAddTimeInfo;
%     sizeAtom = GSParam.sizeAtom;
%     rangeCoef = GSParam.rangeCoef;
%     
%     realSizeAtom = nSpecialFeat + sizeAtom;
%     
%     nBlock = size(realData, 2);
%     
%     all_patches = zeros(realSizeAtom*nBlock, ncell);
%     patches = zeros(realSizeAtom, ncell);
%     
%     for k = 1 : nBlock
%         sPos = (k-1)*realSizeAtom + 1;
%         ePos = sPos + realSizeAtom - 1;
%             
%         if trainDICParam.isAddLocInfo && trainDICParam.isAddTimeInfo
%             patches(1:3, :) = [ones(1, ncell) * x(k); ones(1, ncell) * y(k); 1 : ncell];
%         elseif trainDICParam.isAddLocInfo
%             patches(1:2,:) = [ones(1, ncell) * x(k); ones(1, ncell) * y(k)];
%         elseif trainDICParam.isAddTimeInfo
%             patches(1, :) = [1 : ncell];
%         end
%         
%         for j = 1 : ncell
%             js = GSParam.index(j);
%             patches(nSpecialFeat+1:end, j) = realData(js : js+sizeAtom-1, k);
%         end
% 
%         
%         
%         all_patches(sPos:ePos, :) = patches;
%         
%     end
%     
%     switch options.mode
%     case {'low_high', 'seismic_high', 'residual'}
%     
%         switch trainDICParam.normalizationMode
%             case 'feat_max_min'
%                 all_patches = (all_patches - GSParam.low_min_values) ./ (GSParam.low_max_values - GSParam.low_min_values);
%             case 'feat_mean_sigma'
%                 all_patches = (all_patches - GSParam.low_mean_values) ./ GSParam.low_sigma_values;
%             case 'whole_data_max_min'
%                 all_patches = (all_patches - rangeCoef(1, 1)) / (rangeCoef(1, 2) - rangeCoef(1, 1));
%         end
%         
%     end
% %         
% %     if strcmp(trainDICParam.feature_reduction, 'high_resolution')
% %         patches = GSParam.output.B' * patches;
% %     end
% %     
%     gammas = omp(GSParam.D1'*all_patches, ...
%                     GSParam.omp_G, ...
%                     GSParam.sparsity);
%             
%     [gamma_vals, gamma_locs] = bsGetNonZeroElements(gammas, GSParam.sparsity);
%     
%     new_patches = GSParam.D2 *  gammas;
%     switch options.mode
%     case {'low_high', 'seismic_high', 'residual'}
%         
%         switch trainDICParam.normalizationMode
%             case 'feat_max_min'
%                 new_patches = new_patches .* (GSParam.high_max_values - GSParam.high_min_values) + GSParam.high_min_values; 
%             case 'feat_mean_sigma'
%                 new_patches = new_patches .* GSParam.high_sigma_values + GSParam.high_mean_values;
%                 
%             case 'whole_data_max_min'
%                 new_patches = new_patches .* (rangeCoef(2, 2) - rangeCoef(2, 1)) + rangeCoef(2, 1); 
%         end
%         
%     end
% 
%     avgLog = bsAvgPatches(new_patches, GSParam.index, size(realData, 1));
% 
% end

function newData = bsHandleOneTrace(realData, avgData, options, dt)

    
    % 合并低频和中低频
    switch options.mode
        case {'low_high', 'seismic_high'}

            ft = 1/dt*1000/2;
            newData = bsMixTwoSignal(realData, avgData, options.lowCut*ft, options.lowCut*ft, dt/1000);
%         bsShowFFTResultsComparison(1, [realData, avgData, newData], {'反演结果', '高频', '合并'});
        case {'full_freq'}
            newData = avgData;
        case 'residual'
            newData = avgData + realData;
    end
    
end



% function GSParam = bsInitDLSRPkgs(GSParam, gamma, sampNum, options)
% 
%     validatestring(string(GSParam.reconstructType), {'equation', 'simpleAvg'});
%     
%     sizeAtom = GSParam.trainDICParam.sizeAtom;
%     nAtom = GSParam.trainDICParam.nAtom;
% 
%     
%     GSParam.sizeAtom = sizeAtom;
%     GSParam.nAtom = nAtom;
%     GSParam.nrepeat = sizeAtom - GSParam.stride;
%     
%     index = 1 : GSParam.stride : sampNum - sizeAtom + 1;
%     if(index(end) ~= sampNum - sizeAtom + 1)
%         index = [index, sampNum - sizeAtom + 1];
%     end
%     
%     GSParam.index = index;
%     GSParam.ncell = length(index);
%     [GSParam.R] = bsCreateRMatrix(index, sizeAtom, sampNum);
%    
%     tmp = zeros(sampNum, sampNum);
%     for iCell = 1 : GSParam.ncell
%         tmp = tmp + GSParam.R{iCell}' * GSParam.R{iCell};
%     end
%     GSParam.invTmp = tmp;
%     GSParam.invR = inv(gamma * eye(sampNum) + GSParam.invTmp);
%     
%     % 低分辨率patch可能有时间和地址信息
%     n1 = size(GSParam.DIC, 1) - sizeAtom;
% %     nSpecialFeat = trainDICParam.isAddLocInfo * 2 + trainDICParam.isAddTimeInfo;
%     
%     D1 = GSParam.DIC(1:n1, :);
%     D2 = GSParam.DIC(n1+1:end, :);
%     
%     nBlock = options.nMultipleTrace;
%     D1 = repmat(D1, nBlock, 1);
%     
%     [D1, D2, C] = bsNormalDIC(D1, D2);
%     
%     
%     GSParam.D1 = D1;
%     
%     GSParam.omp_G = D1' * D1;
%     GSParam.D2 = D2;
%     GSParam.C = C;
%     
% %     GSParam.neiborIndecies = bsGetNeiborIndecies(D1, GSParam.nNeibor);
%     rangeCoef = GSParam.rangeCoef;
%     n1 = size(rangeCoef, 1) - sizeAtom;
%     
%     switch GSParam.trainDICParam.normalizationMode
%     case 'feat_max_min'
%         GSParam.low_min_values = repmat(rangeCoef(1:n1, 1), nBlock, GSParam.ncell);
%         GSParam.low_max_values = repmat(rangeCoef(1:n1, 2), nBlock, GSParam.ncell);
%         
%         GSParam.high_min_values = repmat(rangeCoef(n1+1:end, 1), 1, GSParam.ncell);
%         GSParam.high_max_values = repmat(rangeCoef(n1+1:end, 2), 1, GSParam.ncell);
%     
%     case 'feat_mean_sigma'
%         GSParam.low_mean_values = repmat(rangeCoef(1:n1, 1), nBlock, GSParam.ncell);
%         GSParam.low_sigma_values = repmat(rangeCoef(1:n1, 2), nBlock, GSParam.ncell);
%         
%         GSParam.high_mean_values = repmat(rangeCoef(n1+1:end, 1), 1, GSParam.ncell);
%         GSParam.high_sigma_values = repmat(rangeCoef(n1+1:end, 2), 1, GSParam.ncell);
%                 
%     end
%         
%    
%                 
%     
% end
% 
% function [D1, D2, C] = bsNormalDIC(D1, D2)
%     C = zeros(size(D1, 2), 1);
%     
%     for i = 1 : size(D1, 2)
%         normCoef = norm(D1(:, i));
%         D1(:, i) = D1(:, i) / normCoef;
%         D2(:, i) = D2(:, i) / normCoef;
%         C(i) = normCoef;
%     end
% end
  