clear;
%% load file

movie_source = 'm500-0304-s07-2P-sl2_uc_nc_zsc_ti4.hdf5';
M = load_movie(movie_source);

if ~isa(M,'double');    M = double(M);  end         % convert to single

[d1,d2,T] = size(M);                                % dimensions of dataset
d = d1*d2;                                          % total number of pixels

%% Set parameters

K = 50;                                           % number of components to be found
tau = 7;                                          % std of gaussian kernel (size of neuron) 
p = 2;                                            % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
merge_thr = 1;                                  % merging threshold

options = CNMFSetParms(...                      
    'd1',d1,'d2',d2,...                         % dimensions of datasets
    'search_method','ellipse','dist',3,...       % search locations when updating spatial components
    'deconv_method','constrained_foopsi',...    % activity deconvolution method
    'temporal_iter',2,...                       % number of block-coordinate descent steps 
    'fudge_factor',0.98,...                     % bias correction for AR coefficients
    'merge_thr',merge_thr,...                    % merging threshold
    'gSig',tau,...
    'noise_norm', false,...
    'max_width', 11,...
    'maxthr',0.2 ...
    );
%% Data pre-processing
[Pin,M] = preprocess_data(M,p);
Yr = reshape(M,d,T);
Cn =  correlation_image(M,8);

%% fast initialization of spatial components using greedyROI and HALS
tic;
fprintf('%s: Begin initialization...\n', datestr(now));
[A,C,b,f,center] = initialize_components(M,K,tau,options,Pin);  % initialize
t_init = toc;
fprintf('%s: Initialization took %.1f minutes\n', datestr(now), t_init / 60);

% display centers of found components
figure;imagesc(Cn);
    axis equal; axis tight; hold all;
    scatter(center(:,2),center(:,1),'mo');
    title('Center of ROIs found from initialization algorithm');
    drawnow;
   
%% Run one iteration of CNMF

[A, C, b, f, P] = single_iter(Yr,A,C,b,f,Pin,options);
save_cnmf_to_rec;

%% Manual sort
if (ds.num_cells == size(A,2))
    keep = logical(ds.is_cell)';
    A = A(:,keep);
    C = C(keep,:);
    fprintf('%s: Eliminated %d non-cells!\n',...
        datestr(now), ds.num_cells - sum(keep));
else
    fprintf('ERROR: Num cells in DaySummary inconsistent with CNMF variables!\n');
end

%% add points of interest (optional)

if exist('poi', 'var')
    num_sorted_cells = ds.num_classified_cells;
    center = zeros(num_sorted_cells, 2);
    idx = 1;
    for cell_idx = find(ds.is_cell)
        center(idx,:) = ds.cells(cell_idx).com;
        idx = idx+1;
    end
    center = fliplr(center);
    tau = options.gSig;
    [A, C] = manually_refine_components2(M,A,C,center,Cn,tau,options,poi(:,1:2));
end
clear poi;