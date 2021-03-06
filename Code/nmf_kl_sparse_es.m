function [W,H,errs,vout] = nmf_kl_sparse_es(V, r, varargin)
% function [W,H,errs,vout] = nmf_kl_sparse_es(V, r, varargin)
%
% Implements NMF using the normalized Kullback-Leibler divergence (see [1]
% for details) with the sparsity constraints proposed in [2,3]:
% 
%      min  D(V||W*H) + alpha*sum(sum(H)) s.t. W>=0, H>=0
% 
% Inputs: (all except V and r are optional and passed in in name-value pairs)
%   V      [mat]  - Input matrix (n x m)
%   r      [num]  - Rank of the decomposition
%   alpha  [num]  - Sparsity parameter [0]
%   niter  [num]  - Max number of iterations to use [100]
%   thresh [num]  - Number between 0 and 1 used to determine convergence;
%                   the algorithm has considered to have converged when:
%                   (err(t-1)-err(t))/(err(1)-err(t)) < thresh
%                   ignored if thesh is empty [[]]
%   norm_w [num]  - Type of normalization to use for columns of W [1]
%                   can be 1 (1-norm) or 2 (2-norm)
%   norm_h [num]  - Type of normalization to use for rows of H [0]
%                   can be 0 (none), 1 (1-norm), 2 (2-norm), or 'a' (sum(H(:))=1)
%   verb   [num]  - Verbosity level (0-3, 0 means silent) [1]
%   W0     [mat]  - Initial W values (n x r) [[]]
%                   empty means initialize randomly
%   H0     [mat]  - Initial H values (r x m) [[]]
%                   empty means initialize randomly
%   W      [mat]  - Fixed value of W (n x r) [[]] 
%                   empty means we should update W at each iteration while
%                   passing in a matrix means that W will be fixed
%   H      [mat]  - Fixed value of H (r x m) [[]] 
%                   empty means we should update H at each iteration while
%                   passing in a matrix means that H will be fixed
%   myeps  [num]  - Small value to add to denominator of updates [1e-20]
%
% Outputs:
%   W      [mat]  - Basis matrix (n x r)
%   H      [mat]  - Weight matrix (r x m)
%   errs   [vec]  - Error of each iteration of the algorithm
%  (packed into vout cell-array):
%   I_errs [vec]  - I-divergence errors at each iteration
%   s_errs [vec]  - Sparsity errors at each iteration
%
% [1] D. Lee and S. Seung, "Algorithms for Non-negative Matrix Factorization", 
%     NIPS, 2001
% [2] J. Eggert and E. Korner, "Sparse Coding and NMF", in Neural Networks, 2004
% [3] M. Schmidt, "Speech Separation using Non-negative Features and Sparse 
%     Non-negative Matrix Factorization", Tech. Report, 2007
%
% 2010-01-14 Graham Grindlay (grindlay@ee.columbia.edu)

% Copyright (C) 2008-2010 Graham Grindlay (grindlay@ee.columbia.edu)
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% do some sanity checks
if min(min(V)) < 0
    error('Matrix entries can not be negative');
end
if min(sum(V,2)) == 0
    error('Not all entries in a row can be zero');
end

[n,m] = size(V);

% process arguments
[niter, thresh, alpha, norm_w, norm_h, verb, myeps, W0, H0, W, H] = ...
    parse_opt(varargin, 'niter', 100, 'thresh', [], 'alpha', 0, ...
                        'norm_w', 1, 'norm_h', 0, 'verb', 1, ...
                        'myeps', 1e-20, 'W0', [], 'H0', [], ...
                        'W', [], 'H', []);

if norm_w == 0
    error('nmf_kl_sparse_es: W has to be normalized to prevent scaling drift!');
end

% initialize W based on what we got passed
if isempty(W)
    if isempty(W0)
        W = rand(n,r);
    else
        W = W0;
    end
    update_W = true;
else 
    update_W = false;
end

% initialize H based on what we got passed
if isempty(H)
    if isempty(H0)
        H = rand(r,m);
    else
        H = H0;
    end
    update_H = true;
else % we aren't H
    update_H = false;
end

% normalize W
W = normalize_W(W,norm_w);

if norm_h ~= 0
    % normalize H
    H = normalize_H(H,norm_h);
end

% preallocate matrix of ones
Onn = ones(n,n);
Onm = ones(n,m);

I_errs = zeros(niter,1);
s_errs = zeros(niter,1);
errs = zeros(niter,1);
for t = 1:niter
    % update H if requested
    if update_H
        H = H .* ( (W'*(V./(W*H))) ./ max(W'*Onm + alpha, myeps) );
        if norm_h ~= 0
            H = normalize_H(H,norm_h);
        end
    end
    
    % update W if requested
    if update_W
        R = V./(W*H);
        if norm_w == 1
            W = W .* ( (R*H' + (Onn*(Onm*H' .* W))) ./ ...
                       max(Onm*H' + (Onn*(R*H' .* W)), myeps) );
        elseif norm_w == 2
            W = W .* ( (R*H' + W .* (Onn*(Onm*H' .* W))) ./ ...
                       max(Onm*H' + W .* (Onn*(R*H' .* W)), myeps) );
        end
        W = normalize_W(W,norm_w);
    end
    
    R = W*H;
    
    % compute squared error
    I_errs(t) = sum(V(:).*log(V(:)./R(:)) - V(:) + R(:));
    s_errs(t) = sum(H(:));
    errs(t) = I_errs(t) + alpha*s_errs(t);
    
    % display error if asked
    if verb >= 3
        fprintf(1, ['nmf_kl_sparse_es: iter=%d, I-div=%f, sparse_err=%f (alpha=%f), ' ...
                    'total_err=%f\n'], t, I_errs(t), s_errs(t), alpha, errs(t));
    end
    
    % check for convergence if asked
    if ~isempty(thresh)
        if t > 2
            if (errs(t-1)-errs(t))/(errs(1)-errs(t-1)) < thresh
                break;
            end
        end
    end
end

% display error if asked
if verb >= 2
    fprintf(1, ['nmf_kl_sparse_es: final, I-div=%f, sparse_err=%f (alpha=%f), ' ...
                'total_err=%f\n'], I_errs(t), s_errs(t), alpha, errs(t));
end

% if we broke early, get rid of extra 0s in the errs vector
I_errs = I_errs(1:t);
s_errs = s_errs(1:t);
errs = errs(1:t);

% needed to conform to function signature required by nmf_alg
vout = {I_errs,s_errs};
