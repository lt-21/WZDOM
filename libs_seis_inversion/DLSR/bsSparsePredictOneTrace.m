function [reconstructed, gammas] = bsSparsePredictOneTrace(GSParam, input, inline, crossline, nlm_ps)
%% ���ݵͷֱ����ֵ�Ԥ��߷ֱ���
    
    [sampNum, ~] = size(input{1});
    
    % ���Ƚ�����ת��ΪС�� 
    if nargin > 4 && ~isempty(nlm_ps)
        [all_patches] = bsSparseTransInput2PatchesByNLM(GSParam, input, nlm_ps, inline, crossline);
    else
        [all_patches] = bsSparseTransInput2Patches(GSParam, input, inline, crossline);
    end
    
    % ��һ��
	[normal_patches, output] = bsSparseNormalization(GSParam.trainDICParam.normalizationMode, all_patches, GSParam.low_min_values, GSParam.low_max_values);
    % ϡ���ʾ
    if strcmpi(GSParam.trainDICParam.feature_reduction, 'high_resolution')
        normal_patches = GSParam.output.B' * normal_patches;
    end
    gammas = omp(GSParam.lowDIC'*normal_patches, GSParam.omp_low_G, GSParam.sparsity);
    new_patches = GSParam.highDIC *  gammas;
    % ����һ��
    denormal_patches = bsSparseDenormalization(GSParam.trainDICParam.normalizationMode, new_patches, output, GSParam.high_min_values, GSParam.high_max_values);
    
%     if length(GSParam.trainDICParam.normalizationMode) > 5
%         figure(100); 
%         subplot(1, 2, 1);
%         plot(all_patches(:,1), 'b', 'linewidth', 2);  hold on;
%         plot(denormal_patches(:,1), 'r', 'linewidth', 2); 
%         legend('ԭʼ��һ��ǰ', '�ع�ȥ��һ����');
% 
%         subplot(1, 2, 2);
%         plot(normal_patches(:,1), 'k', 'linewidth', 2); hold on;
%         plot(new_patches(:,1), 'r', 'linewidth', 2); 
%         legend('ԭʼ��һ����', '�ع�ȥ��һ��ǰ');
%     end
    
    % ���ع���С������Ϊ������һ���ź�
    reconstructed = bsAvgPatches(denormal_patches, GSParam.index, sampNum);
    
end