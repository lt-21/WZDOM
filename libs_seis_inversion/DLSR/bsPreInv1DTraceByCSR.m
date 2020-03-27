function [x, fval, exitFlag, output] = bsPreInv1DTraceByCSR(d, G, xInit, Lb, Ub, regParam, parampkgs, options, mode, lsdCoef)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code is designed for prestack 1D seismic inversion using dictionary
% learning and collaboration sparse representation representation
%
% Programmed by: Bin She (Email: bin.stepbystep@gmail.com)
% Programming dates: Dec 2019
% -------------------------------------------------------------------------
% Input
% 
% d: observed seismic data, a vector.
% 
% G: forward operator made up by the wavelet information
% 
% xInit: initial guess of model parameters
% 
% Lb: lower boundary of x
% 
% Ub: upper boundary of x
% 
% regParam: regularization parameter. If it is empty, I will start a search
% process to find the optimal regParam.
%
% parampkgs: specail parameter for diffrent methods.
% 
% options: options parameters for 1D seismic inversion. See function
% bsCreateSeisInv1DOptions
% 
% regFunc: regularization function handle. It could be @bsReg*.m
%
% -------------------------------------------------------------------------
% Output
%
% x          is a column vector; refers to the estimated result.
%
% fval          the objective function value at the last iteration
%
% exitFlag      corresponds to the stopCriteria
% see function bsCheckStopCriteria
%
% output    a struct, in general, it has
% output.iterations: the number of iterations
% output.nfev: the number of function evaluations
% ouput.midResults: the middle results during the iteration process
% output.regParam: the regularization parameters used
% -------------------------------------------------------------------------

    % create mainData
    mainData.A = G;
    mainData.B = d;
    sampNum = length(xInit)/3;
    initLambda = options.initRegParam(1);
    
    % re-organize the input objective function pakages
    inputObjFcnPkgs = {
        options.mainFunc,       mainData,   1; 
        @bsReg1DTKInitModel,    struct('xInit', xInit), initLambda;
        @bsReg1DTKInitModel,    struct('xInit', xInit), initLambda;
    };
    
    % if the regParam is not given, I search it by a search subroutine
    % which is save in options.searchRegParamFcn. 
    if ~isfield(regParam, 'lambda')
        % find the best regularization parameter
        regParam.lambda = bsFindBestRegParameter(options, inputObjFcnPkgs, xInit, Lb, Ub);
    end
           
    GBOptions = options.GBOptions;
    inputObjFcnPkgs{2, 3} = regParam.lambda;
    GBOptions.maxIter = options.innerIter;
    
    % create packages for sparse inversion 
    GSparseInvParam = bsInitDLSRPkgs(parampkgs, regParam.gamma, sampNum);
    
    ncell = GSparseInvParam.ncell;
    sizeAtom = GSparseInvParam.sizeAtom;
    rangeCoef = GSparseInvParam.rangeCoef;
    patches = zeros(sizeAtom*3, ncell);
    
    midX = [];
    midF = [];
    data = zeros(sampNum, 4);
    newData = data;
    maxIter = options.maxIter;
    lambda = regParam.lambda(1);
    
    
    for iter = 1 : maxIter
        
        % change the current initial guess
        inputObjFcnPkgs{2, 2} = [];
        if length(regParam.gamma) == 2
            gamma  = (maxIter - iter)*(regParam.gamma(2) - regParam.gamma(1))/(maxIter - 1) + regParam.gamma(1);
        else
            gamma = regParam.gamma;
        end
        
        if length(regParam.lambda) == 2
            lambda  = lambda * regParam.lambda(2);
            inputObjFcnPkgs{2, 3} = lambda;
        else
            inputObjFcnPkgs{2, 3} = regParam.lambda;
        end
        
        if length(options.initRegParam) == 2
            initLambda = initLambda * options.initRegParam(2);
            inputObjFcnPkgs{3, 3} = initLambda;
        end
        
        if iter == 1
            inputObjFcnPkgs{2, 3} = 0;
        end

        [xOut, fval, exitFlag, output_] = bsGBSolveByOptions(inputObjFcnPkgs, xInit, Lb, Ub, GBOptions);

        if GBOptions.isSaveMiddleRes
            midX = [midX, output_.midResults.x];
            midF = [midF, output_.midResults.f];
        end
        
        % sparse reconstruction
        [data(:, 2), data(:, 3), data(:, 4)] = bsPreRecoverElasticParam(xOut, mode, lsdCoef);
        
        max_values = cell(1, 3);
        min_values = cell(1, 3);
        
        
        for j = 1 : ncell
            js = GSparseInvParam.index(j);
            for i = 1 : 3
                
                sPos = sizeAtom*(i-1) + 1;
                ePos = sPos + sizeAtom - 1;

                iData = data(js : js+sizeAtom-1, i+1);
                patches(sPos:ePos, j) = iData;
            end
        end

        for i = 1 : 3
            sPos = sizeAtom*(i-1) + 1;
            ePos = sPos + sizeAtom - 1;
            % normalization
            switch GSparseInvParam.trainDICParam.normalizationMode
                case 'patch_max_min'
                    max_values{i} = max(patches(sPos:ePos, :), [], 1);
                    min_values{i} = min(patches(sPos:ePos, :), [], 1);
                    max_values{i} = repmat(max_values{i}, sizeAtom, 1);
                    min_values{i} = repmat(min_values{i}, sizeAtom, 1);
                    patches(sPos:ePos, :) = (patches(sPos:ePos, :) - min_values{i}) ./ (max_values{i} - min_values{i});
                case 'whole_data_max_min'
                    patches(sPos:ePos, :) = (patches(sPos:ePos, :) - rangeCoef(i, 1))/(rangeCoef(i, 2) - rangeCoef(i, 1));
            end
        end
        
                
        if GSparseInvParam.isModifiedDIC
            patches = GSparseInvParam.M  * patches;
        end
        
        gammas = omp(GSparseInvParam.DIC'*patches, ...
                    GSparseInvParam.omp_G, ...
                    GSparseInvParam.sparsity);
        new_patches = GSparseInvParam.DIC *  gammas;
        
        %% reconstruct model by equations
        for i = 1 : 3
            sPos = sizeAtom*(i-1) + 1;
            ePos = sPos + sizeAtom - 1;
            
            switch GSparseInvParam.trainDICParam.normalizationMode
                case 'patch_max_min'
                    i_new_patches = new_patches(sPos:ePos, :) .* (max_values{i} - min_values{i}) + min_values{i}; 
                case 'whole_data_max_min'
                    i_new_patches = new_patches(sPos:ePos, :) * (rangeCoef(i, 2) - rangeCoef(i, 1)) + rangeCoef(i, 1);
            end
            
            switch GSparseInvParam.reconstructType
                case 'equation'
                    avgLog = gamma * data(:, i+1);
                    % get reconstructed results by equation
                    for j = 1 : ncell
                        
                        avgLog = avgLog + GSparseInvParam.R{j}' * i_new_patches(:, j);
                    end

                    newData(:, i+1) = GSparseInvParam.invR * avgLog;
                case 'simpleAvg'
                    % get reconstructed results by averaging patches
                    avgLog = bsAvgPatches(i_new_patches, GSparseInvParam.index, sampNum);
                    newData(:, i+1) = avgLog * gamma + data(:, i+1) * (1 - gamma);
            end
        end
        
        
        %% reconstruct model by 
        xInit = bsPreBuildModelParam(newData, mode, lsdCoef);
        
    end
    
    switch GSparseInvParam.isSparseRebuild
        case 1
            x = xInit;
        case 0 
            x = xOut;
        otherwise
            error('GSparseInvParam.isSparseRebuild must either 1 or 0. \n');
    end
    
    output.midResults.x = midX;
    output.midResults.f = midF;
    output.regParam = regParam;
    output.parampkgs = GSparseInvParam;
    
end

function GSparseInvParam = bsInitDLSRPkgs(GSparseInvParam, gamma, sampNum)
    
    if isfield(GSparseInvParam, 'omp_G')
        return;
    end

    validatestring(string(GSparseInvParam.reconstructType), {'equation', 'simpleAvg'});
    validateattributes(gamma, {'double'}, {'>=', 0, '<=', 1});
    
    [sizeAtom, nAtom] = size(GSparseInvParam.DIC);
    sizeAtom = sizeAtom / 3;
    
    GSparseInvParam.sizeAtom = sizeAtom;
    GSparseInvParam.nAtom = nAtom;
    GSparseInvParam.nrepeat = sizeAtom - GSparseInvParam.stride;
    
    index = 1 : GSparseInvParam.stride : sampNum - sizeAtom + 1;
    if(index(end) ~= sampNum - sizeAtom + 1)
        index = [index, sampNum - sizeAtom + 1];
    end
    
    GSparseInvParam.index = index;
    GSparseInvParam.ncell = length(index);
    [GSparseInvParam.R] = bsCreateRMatrix(index, sizeAtom, sampNum);
   
    tmp = zeros(sampNum, sampNum);
    for iCell = 1 : GSparseInvParam.ncell
        tmp = tmp + GSparseInvParam.R{iCell}' * GSparseInvParam.R{iCell};
    end
    GSparseInvParam.invTmp = tmp;
    GSparseInvParam.invR = inv(gamma(1) * eye(sampNum) + GSparseInvParam.invTmp);
    
    if GSparseInvParam.isModifiedDIC
        I = eye(sizeAtom * 3);
        oneSa = ones(sizeAtom, sizeAtom);
        Z = zeros(sizeAtom, sizeAtom);
        cOne = {oneSa Z Z;
              Z oneSa Z;
              Z Z oneSa};
        GSparseInvParam.M = I + GSparseInvParam.a / sizeAtom * cell2mat(cOne);

        MDIC = GSparseInvParam.M * GSparseInvParam.DIC;
        % normalize the modified dictionary
        for j = 1 : size(MDIC, 2)
            MDIC(:, j) = MDIC(:, j) / norm(MDIC(:, j));
        end
        
        GSparseInvParam.DIC = MDIC;
        GSparseInvParam.omp_G = GSparseInvParam.MDIC' * GSparseInvParam.MDIC;
    else
        GSparseInvParam.omp_G = GSparseInvParam.DIC' * GSparseInvParam.DIC;
    end
        
end


