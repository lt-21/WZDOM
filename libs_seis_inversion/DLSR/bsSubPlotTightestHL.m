function bsSubPlotTightestHL( M, N, index, sx, sy)
%% ���������ڷǳ����յ���ʾ�ֵ�ѧϰ�Ľ��
%
% ����
% M             ����
% N             ����
% index         �ڼ���
%
% ���           ��

    dw = 0.93/N;  dh = 0.9/M;
    w = dw; h = dh ;
    
    y = floor( (index-1) / N);
    x = mod(index-1, N);
    subplot('Position', [x*dw+sx (M-y-1)*dh+sy w h]);
end
