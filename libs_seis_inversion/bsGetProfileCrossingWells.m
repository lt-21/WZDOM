function [inIds, crossIds] = bsGetProfileCrossingWells(GInvParam, wellLogs, varargin)

    p = inputParser;
    
    [rangeInline, rangeCrossline] = bsGetWorkAreaRangeByParam(GInvParam);
    
    addParameter(p, 'isAlongCrossline', 1);
    addParameter(p, 'method', 'PCHIP');
    addParameter(p, 'rangeInline', rangeInline);
    addParameter(p, 'rangeCrossline', rangeCrossline);
    addParameter(p, 'leftTrNum', 5000);
    addParameter(p, 'rightTrNum', 5000);
    
    p.parse(varargin{:});  
    options = p.Results;
    
    wells = cell2mat(wellLogs);
    wellInIds = [wells.inline];
    wellCrossIds = [wells.crossline];
    nWell = length(wellLogs);
    
    % get the range of current work area
    rangeInline = options.rangeInline;
    rangeCrossline = options.rangeCrossline;
    
    if nWell == 1
        if options.isAlongCrossline
            traceNum = rangeCrossline(2) - rangeCrossline(1) + 1;
            
            inIds = ones(1, traceNum) * wellInIds(1);
            crossIds = rangeCrossline(1) : rangeCrossline(2);
        else
            
            traceNum = rangeInline(2) - rangeInline(1) + 1;
            
            crossIds = ones(1, traceNum) * wellCrossIds(1);
            inIds = rangeInline(1) : rangeInline(2);
        end
    else
        if options.isAlongCrossline
            [inIds, crossIds] = bsInterpolateALine(wellInIds, wellCrossIds, ...
                rangeInline, rangeCrossline, options.method);
        else
            [crossIds, inIds] = bsInterpolateALine(wellCrossIds, wellInIds, ...
                rangeCrossline, rangeInline, options.method);
        end
    end
    
    [wellPos, ~, ~] = bsFindWellLocation(wellLogs, inIds, crossIds);
    
    if isempty(wellPos)
        return;
    else
        left = min(wellPos) - options.leftTrNum;
        right = max(wellPos) + options.rightTrNum;

        if left < 1
            left = 1;
        end

        if right > length(inIds)
            right = length(inIds);
        end
        
        inIds = inIds(left:right);
        crossIds = crossIds(left:right);
    end
end

function [outInIds, outCrossIds] = bsInterpolateALine(inIds, crossIds, ...
    rangeInline, rangeCrossline, interp_method)

    [ids, index] = sortrows([inIds', crossIds'], [1, 2]);
    index = index';
    inIds = ids(:, 1)';
    crossIds = ids(:, 2)';
    
%     setInIds = [inIds(1), inIds, inIds(length(inIds))];
    
    setInIds = inIds;
    setCrossIds = crossIds;
    
    if isempty(find(crossIds == rangeCrossline(1), 1))
        setInIds = [inIds(1), setInIds];
        setCrossIds = [rangeCrossline(1), setCrossIds];
    end
    
    if isempty(find(crossIds == rangeCrossline(2), 1))
        setInIds = [setInIds, inIds(length(inIds))];
        setCrossIds = [setCrossIds, rangeCrossline(2)];
    end
    
    outCrossIds = rangeCrossline(1) : 1 : rangeCrossline(2);
    outInIds = interp1(setCrossIds, setInIds, outCrossIds, interp_method);

    for i = 1 : length(outInIds)
        outInIds(i) = floor(outInIds(i));
    end
    
    for i = 1 : length(crossIds)
        index = outCrossIds == crossIds(i);
        outInIds(index) = inIds(i);
    end
    
    outInIds(outInIds > rangeInline(2)) = rangeInline(2);
    outInIds(outInIds < rangeInline(1)) = rangeInline(1);
end