function invResults = bsReshapeInvResultsAs3D(invResults, rangeInline, rangeCrossline)
%% smooth data by using the NLM algorithm, the similarites are referenced from refData
% Programmed by: Bin She (Email: bin.stepbystep@gmail.com)
% Programming dates: Dec 2019
% 
% Input
% options.p                 parameter for inverse distance weight function,
%                           its reasonable range is [0.5 3]
% options.nPointsUsed       the most number of points used to calculate the
%                           weight information
% options.stride            step size of sliding window
% options.searchOffset      indicating the search range
% options.windowSize        the size of the sliding 2D window

% see bsNLMByRef.m function
% -------------------------------------------------------------------------

    if isempty(invResults)
        return;
    end
    
    nInline = rangeInline(end) - rangeInline(1) + 1;
    nCrossline = rangeCrossline(end) - rangeCrossline(1) + 1;
    
    for i = 1 : length(invResults)
        data = invResults{i}.data;
        
        
        if ~iscell(data)
            fprintf('Reshaping %s data of %s...\n', invResults{i}.type, invResults{i}.name);
            invResults{i}.data = bsReshapeData(invResults{i}.data, nInline, nCrossline);
        else
            for j = 1 : length(data)
                fprintf('Reshaping %s data of %s...\n', invResults{i}.type{j}, invResults{i}.name);
                invResults{i}.data{j} = bsReshapeData(invResults{i}.data{j}, nInline, nCrossline);
            end
        end
        
    end
end

function volume = bsReshapeData(data, nInline, nCrossline)
    [sampNum, nTrace] = size(data);
    assert(nTrace==nInline*nCrossline, 'the number of traces must be equal to #inline * #crossline');
    
    volume = reshape(data, sampNum, nCrossline, nInline);
end