function [outputData] = bsPostReBuildByCSR(GInvParam, GSParam, inputData, inIds, crossIds, options)

    [sampNum, traceNum] = size(inputData);


%     GSParam = bsInitDLSRPkgs(GSParam, options.gamma, sampNum);
    [GSParam] = bsInitGSparseParam(GSParam, sampNum, 1, [], 2);
    
        % tackle the inverse task
    outputData = zeros(sampNum, traceNum);
    
    dt = GInvParam.dt;
    
    parfor iTrace = 1 : traceNum
        [highData, ~] = bsSparsePredictOneTrace(GSParam, {inputData(:, iTrace)}, inIds(iTrace), crossIds(iTrace));
        outputData(:, iTrace) = bsHandleOneTrace(inputData(:, iTrace), highData, options, dt);
    end
    
end

function newData = bsHandleOneTrace(realData, avgData, options, dt)

    
    % �ϲ���Ƶ���е�Ƶ
    switch options.mode
        case {'low_high', 'seismic_high'}

            ft = 1/dt*1000/2;
            newData = bsMixTwoSignal(realData, avgData, options.lowCut*ft, options.lowCut*ft, dt/1000);
%         bsShowFFTResultsComparison(1, [realData, avgData, newData], {'���ݽ��', '��Ƶ', '�ϲ�'});
        case {'full_freq'}
            newData = avgData;
        case 'residual'
            newData = avgData + realData;
    end
    
end
