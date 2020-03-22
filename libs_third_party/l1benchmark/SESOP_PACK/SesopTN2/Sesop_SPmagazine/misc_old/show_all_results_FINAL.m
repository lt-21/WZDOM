% Show results  of all optimization methods
%
% show_all_results.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Uncomment one of the lines:

%load reports_ComprSens_128b.mat;  report_name='ComprSens'
%load reports_tomogr_128b.mat;  report_name='Tomogr'    
%load reports_deblur_128b.mat; report_name='Deblur'     
%load reports_deblur_sparse_64.mat; report_name='Deblur-Sparse-64' 
%load reports_denoise_128.mat; report_name='Denoise'     
%load reports_denoise_128a.mat; report_name='Denoise'     
%load reports_denoise_128c.mat; report_name='Denoise'     
%load reports_denoise_pepers128.mat; report_name='Denoise Pepers'    
%load reports_denoise_lena128.mat; report_name='Denoise Lena'    
%load reports_ComprSens_SparseImage_128.mat; report_name='ComprSens-SparseImage-128'
%load reports_ComprSens_Lena_128.mat; report_name='ComprSens-Lena-128'
%load reports_ComprSens_Pepers_128b.mat;report_name='ComprSens_Pepers_128'
%load reports_ComprSens_Sparse_733973.5948.mat; 
%load reports_ComprSens_Lena_733976.4733.mat;

%load reports_ComprSens_Sparse_733976.5149.mat; % Nice results!!
%load reports_Tomogr_Sparse_733976.5196.mat;  % also rather good plots
%load reports_Deblur_Sparse_733976.5477.mat;  % also rather good plots
%load reports_Deblur_Sparse_733980.3852.mat; % with L-BFGS
%load reports_Deblur_Peppers_733980.3961.mat; %dim 128

%load reports_ComprSens_Sparse_733987.4809_smooth_1e-8.mat; % With Interior Point as well; eps_smoothing=1e-8
%load reports_ComprSens_Sparse_733987.5021_smooth_1e-3.mat % With Interior Point as well; eps_smoothing=1e-3



%%%%%%%   LATEST RESULTS FOR THE PAPER  %%%%%%%%%%%%%%

%load reports_ComprSens_Sparse_733988.4394_smooth_1e-3.mat; ind=[4:9];
%load reports_ComprSens_Sparse_733988.4394_smooth_1e-3.mat; ind=[1 3 6 10 11];  
%load reports_ComprSens_Sparse_733988.4228_concave.mat; ind=[4,5,7,8];

%load reports_Tomogr_Phantom_733988.4817_smooth_1e-3.mat; ind=4:9;     
%load reports_Tomogr_Phantom_733988.4817_smooth_1e-3.mat; ind=[1 3 6 10 11];   

%load reports_Deblur_Phantom_733989.3502_smooth_1e-3.mat; ind=4:9; 
%load reports_Deblur_Phantom_733989.3502_smooth_1e-3.mat; ind=[1 3 6 10 11];  



%load reports_Matrix_Sparse_734131.4333_smooth_1e-3_weight_1e-6.mat
%load reports_Matrix_Sparse_734131.4424_smooth_1e-3.mat
%load reports_Matrix_Sparse_geogaussmatrix_734131.5007_smooth_1e-3_weight_1e-6.mat;
%load reports_Matrix_Sparse_tonytaperwavreal_734131.4770_smooth_1e-3_weight_1e-6.mat

%load reports_Matrixgeogaussmatrix_Sparse128_734135.7210_smooth_1e-3_weight_1e-6.mat
%load reports_Matrixgeogaussmatrix_Sparse128_734135.7587_smooth_1e-3.mat
%load reports_Matrixbadgaussmatrix_Sparse128_734135.6777_smooth_1e-3_weight_1e-6.mat
%load reports_Matrixbadgaussmatrix_Sparse128_734135.6777_smooth_1e-3.mat
load reports_Matrixgaussmatrix_Sparse128_734135.7963_smooth_1e-3_weight_1e-6.mat
%load reports_Matrixgaussmatrix_Sparse128_734135.7798_smooth_1e-3.mat

%load reports_Tomogr_Phantom32_734134.6232_smooth_1e-3.mat
%load reports_Tomogr_Phantom64_734134.6264_smooth_1e-3.mat
%load reports_Tomogr_Phantom128_734134.6511_smooth_1e-3.mat
%load reports_Tomogr_Phantom256_734134.6749_smooth_1e-3.mat


i_run=numel(reports); ind=1:i_run;  % which curves to show


ColorPlots=1;

if ColorPlots
	%colorvec = [{'k'},{'b'},{'r'},{'g'},{'y'},{'c'},{'m'},{'.'},{'--'},{'r.'}];
	colorvec = [{'k'},{'k:'},{'b'},{'b:'},{'r'},{'r:'},{'g'},{'g:'},{'y'},{'c'},{'m'},{'.'},{'--'},{'r.'}];
	
else
	%colorvec = [{'k:'},{'k-.'},{'k--'},{'k.'},{'k'},{'k+'},{'k^'},{'ks'},{'k'}];
	%colorvec = [{'k'},{'k:'},{'k-.'},{'k--'},{'k.'},{'k+'},{'k^'},{'ko'},{'ks'}];
	%colorvec = [{'k'},{'k:'},{'k.'},{'k+'},{'k-.'},{'k^'},{'ko'},{'ks'},{'k--'}];
	%colorvec = [{'k'},{'k.'},{'k:'},{'k+'},{'k-.'},{'k^'},{'ko'},{'ks'},{'k--'}];

	%colorvec = [{'k'},{'k:'},{'k-.'},{'ko'},{'k+'},{'k^'},{'ko'},{'ks'},{'k--'}];
	%colorvec = [{'k'},{'k.'},{'ko'},{'k*'},{'k^'},{'ks'},{'kd'},{'k>'},{'kv'}];
end


% if isfield(reports(1),'FlagNewReport'), FlagNewReport=1; %new report format
% else                                    FlagNewReport=0;
% end
% 


f_figure_handle=figure('Position',[00 40 500 800],'name',['Objective function' report_name] );

fbest=1e100; for i=1:i_run, fbest=min(fbest,min(reports(i).func_values));end
mylegends=[];
k=0;
for i=ind,
   semilogy(reports(i).nniter_fg, reports(i).func_values-fbest,colorvec{i});
   k=k+1; mylegends{k}=reports(i).method;
    xlabel('Iteration');ylabel('f - fbest');hold on;
end
legend(mylegends);


figure('Position',[400 40 500 800],'name',['Objective with time' report_name] );
for i=ind,
   ttt=reports(i).times;ttt=ttt-ttt(1);
   semilogy(ttt, reports(i).func_values-fbest,colorvec{i});
   xlabel('CPU time, Sec');ylabel('f - fbest'); hold on;
end
legend(mylegends);


figure('Position',[800 40 500 800],'name',['SNR ' report_name] );
for i=ind,
   plot(reports(i).nniter, reports(i).Xsnr,colorvec{i});hold on;
   xlabel('Iteration');ylabel('SNR, Db')
end
legend(mylegends,'Location','SouthEast');grid

figure('Position',[1200 40 500 800],'name',['SNR with time ' report_name] );
for i=1:i_run,
   if isfield(reports(i),'SNRtime') , ttt=reports(i).SNRtime;ttt=ttt-ttt(1);
   else ttt=reports(i).times(reports(i).nniter+1);ttt=ttt-ttt(1);
   end
   plot(ttt, reports(i).Xsnr,colorvec{i});
   xlabel('CPU time, Sec');ylabel('SNR, Db')
   hold on;
end
legend(mylegends,'Location','SouthEast');grid

% for i=1:i_run, reports(i).options=[];reports(i).options1=[];end
% save reports_ComprSens_128aaaa.mat reports

