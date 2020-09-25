function outResult = bsPreRebuildByCSRWithWholeProcess(GInvParam, timeLine, wellLogs, method, invResult, name, varargin)

    p = inputParser;
    GTrainDICParam = bsCreateGTrainDICParam(...
        'csr', ...
        'title', 'high_freq', ...
        'sizeAtom', 90, ...
        'sparsity', 5, ...
        'iterNum', 5, ...
        'nAtom', 4000, ...
        'filtCoef', 1);
    

    addParameter(p, 'ratio_to_reconstruction', 1);
    addParameter(p, 'mode', 'full_freq');
    addParameter(p, 'wellFiltCoef', 0.1);
    addParameter(p, 'lowCut', 0.1);
    addParameter(p, 'highCut', 1);
    addParameter(p, 'sparsity', 5);
    addParameter(p, 'gamma', 0.5);
    addParameter(p, 'title', 'HLF');
    addParameter(p, 'trainNum', length(wellLogs));
    addParameter(p, 'exception', []);
    addParameter(p, 'mustInclude', []);
    addParameter(p, 'GTrainDICParam', GTrainDICParam);
    
    % ���ڶ����ͬʱϡ���ʾ�ĸ���
    addParameter(p, 'nMultipleTrace', 1);
    addParameter(p, 'isInterpolation', 0);
    
    p.parse(varargin{:});  
    options = p.Results;
    GTrainDICParam = options.GTrainDICParam;
    GTrainDICParam.filtCoef = 1;
    
    switch options.mode
        case 'full_freq'
            GTrainDICParam.normailzationMode = 'off';
            DICTitle = sprintf('%s_highCut_%.2f', ...
                GTrainDICParam.title, options.highCut);
        case 'low_high'
%             GTrainDICParam.normailzationMode = 'whole_data_max_min';
            options.gamma = 1;
            DICTitle = sprintf('%s_lowCut_%.2f_highCut_%.2f', ...
                GTrainDICParam.title, options.lowCut, options.highCut);
    end
    
    wells = cell2mat(wellLogs);
    wellInIds = [wells.inline];
    wellCrossIds = [wells.crossline];

    % inverse a profile
    [~, ~, GInvParamWell] = bsBuildInitModel(GInvParam, timeLine, wellLogs, ...
        'title', 'all_wells', ...
        'inIds', wellInIds, ...
        'filtCoef', options.wellFiltCoef, ...
        'isRebuild', 1, ...
        'crossIds', wellCrossIds ...
    );

    fprintf('�������в⾮��...\n');
    method.isSaveMat = 0;
    method.isSaveSegy = 0;
    method.parampkgs.nMultipleTrace = 1;
    method.parampkgs.is3D = false;
    method.load.mode = 'off';
%     load test_method.mat;
%     method = test_method;
    
    if startsWith(method.flag, 'CSR')
        method.flag = 'CSR';
    end
    
    wellInvResults = bsPreInvTrueMultiTraces(GInvParamWell, wellInIds, wellCrossIds, timeLine, {method});
    [wellInvResults, ~, ~] = bsPreGetOtherAttributesByInvResults(wellInvResults, GInvParam, wellLogs);
    
    set_diff = setdiff(1:length(wellInIds), options.exception);
    train_ids = bsRandSeq(set_diff, options.trainNum);
    train_ids = unique([train_ids, options.mustInclude]);
    outResult = bsSetFields(invResult, {'name', name});
    
    %% ��ǰ�ж�������
    for i = 1 : length(invResult.type)
        switch lower(invResult.type{i})
            case 'vp'
                dataIndex = GInvParam.indexInWellData.vp;
                GTrainDICParam.title = ['vp_', DICTitle];
                iData = 1;
            case 'vs'
                dataIndex = GInvParam.indexInWellData.vs;
                GTrainDICParam.title = ['vs_', DICTitle];
                iData = 2;
            case 'rho'
                dataIndex = GInvParam.indexInWellData.rho;
                GTrainDICParam.title = ['rho_', DICTitle];
                iData = 3;
            case {'vpvs_ratio', 'vp_vs'}
                dataIndex = GInvParam.indexInWellData.vpvs_ratio;
                GTrainDICParam.title = ['vpvs_ratio_', DICTitle];
                iData = 4;
            case 'possion'
                dataIndex = GInvParam.indexInWellData.possion;
                GTrainDICParam.title = ['possion_', DICTitle];
                iData = 5;
        end
        
        [outLogs] = bsGetPairOfInvAndWell(GInvParam, timeLine, wellLogs, wellInvResults{1}.data{iData}, dataIndex, options);
        fprintf('ѵ�������ֵ���...\n');
        [DIC, train_ids, rangeCoef, output] = bsTrainDics(GTrainDICParam, outLogs, train_ids, [ 1, 2]);
        GInvWellSparse = bsCreateGSparseInvParam(DIC, GTrainDICParam, ...
            'sparsity', options.sparsity, ...
            'stride', 1);
        
        [wellPos, wellIndex, wellNames] = bsFindWellLocation(wellLogs, invResult.inIds, invResult.crossIds);
        
        GInvWellSparse.rangeCoef = rangeCoef;
        GInvWellSparse.output = output;
        GInvWellSparse.wellPos = wellPos;
%         [testData] = bsPostReBuildByCSR(GInvParam, GInvWellSparse, wellInvResults{1}.data{iData}, options);
    
%         figure; plot(testData(:, 1), 'r', 'linewidth', 2); hold on; 
%         plot(outLogs{1}.wellLog(:, 2), 'k', 'linewidth', 2); 
%         plot(outLogs{1}.wellLog(:, 1), 'b', 'linewidth', 2);
%         legend('�ع����', 'ʵ�ʲ⾮', '���ݽ��', 'fontsize', 11);
%         set(gcf, 'position', [261   558   979   420]);
%         bsShowFFTResultsComparison(GInvParam.dt, [outLogs{1}.wellLog, testData(:, 1)], {'���ݽ��', 'ʵ�ʲ⾮', '�ع����'});
        
%         startTime = invResult.horizon - GInvParam.upNum * GInvParam.dt;
%         sampNum = GInvParam.upNum + GInvParam.downNum;
%         inputData = bsStackPreSeisData(GInvParam.preSeisData.fileName, GInvParam.preSeisData.segyInfo, ...
%             invResult.inIds, invResult.crossIds, startTime, sampNum, GInvParam.dt);
    
        % �����ֵ�ϡ���ع�
        fprintf('�����ֵ�ϡ���ع�: �ο�����Ϊ���ݽ��...\n');
        if ~options.isInterpolation
%             if options.nMultipleTrace <= 1
%                 [outputData, highData, gamma_vals, gamma_locs] = bsPostReBuildPlusInterpolationCSR(GInvParam, GInvWellSparse, invResult.data{i}, invResult.data{i},...
%                     invResult.inIds, invResult.crossIds, options);
%             else
                [outputData, highData, gamma_vals, gamma_locs] = bsPostReBuildMulTraceCSR(GInvParam, GInvWellSparse, invResult.data{i}, invResult.data{i}, invResult.inIds, invResult.crossIds, options);
%             end
        else
            gamma_locs = [];
            gamma_vals = [];
            [outputData, highData] = bsPostReBuildInterpolation(GInvParam, outLogs(train_ids), invResult.data{i}, invResult.inIds, invResult.crossIds, options);
        end
    
        

        outResult.data{i} = outputData;
        outResult.high_freq_data{i} = highData;
        outResult.gamma_vals{i} = gamma_vals;
        outResult.gamma_locs{i} = gamma_locs;
        outResult.DIC{i} = DIC;
    end
    
    try
        bsWriteInvResultsIntoSegyFiles(GInvParam, {outResult}, options.title, 0);
    catch
        fprintf('������Ϊsegy�ļ�ʧ��...\n');
    end
    
end