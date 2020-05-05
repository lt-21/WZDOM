function wellData = bsResampleWellData(data, dataIndex, timeIndex, dt)
    
    ct = 0;
    sampNum = size(data, 1);
    
    dataIndex = [dataIndex, timeIndex];
    wellData = [];
    sumData = data(1, dataIndex);
    num = 1;
    
    for i = 2 : sampNum
       
%         it = dz * 2 / data(i, vpIndex) * 1000;
        it = data(i, timeIndex) - data(i-1, timeIndex);
        ct = ct + it;
        sumData = sumData + data(i, dataIndex);
        
        num = num + 1;
        if ct > dt
            if isempty(timeIndex) || timeIndex<0
                wellData = [wellData; sumData/num];
            else
                
%                 if isempty(wellData)
%                     time = data(i, timeIndex) * 1000;
%                   	wellData = [wellData; [depth, sumData/num, time]];
%                 else
%                     time = wellData(end, end) + dt;
%                     wellData = [wellData; [depth, sumData/num, time]];
%                 end
                
                
                if isempty(wellData)
                    time = data(i, timeIndex);
                    wellData = [wellData; [sumData(1:end-1)/num, round(sumData(end)/num)]];
                else
                    wellData = [wellData; [sumData(1:end-1)/num, wellData(end, end) + dt]];
                end
                
            end
            num = 0;
            sumData = zeros(1, length(dataIndex));
            ct = ct - dt;
        end
    end
end