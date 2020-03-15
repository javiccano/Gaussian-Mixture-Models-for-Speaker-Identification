function vector_expand = VAD (x, f_s, period_frame) 



    size_window = 20e-3; % window size
    time_nonspeech = 150e-3; % first 150 ms of the signal, as they are assumed to be non-speech portions
    N = 6;

    samples_window = f_s * size_window;
    samples_frame = f_s * period_frame;
    samples_nonspeech = f_s * time_nonspeech;

    E_0 = 50;
    E_1 = 70;
    gamma_0 = 9;
    gamma_1 = 6;

    NFFT = 2^ceil(log2(samples_window));
    
    R = zeros(NFFT, samples_nonspeech/samples_frame);

    for l = 0 : size(R, 2) - 1
       lim_max = l*samples_frame + samples_window; 
       if lim_max > samples_frame*size(R, 2)
          lim_max = samples_frame*size(R, 2);          
       end
       R(:, l + 1) = abs(fft(x(l*samples_frame + 1 : lim_max).* hamming(lim_max - l*samples_frame), NFFT)); 
    end
    R = mean(R, 2);
    E  = 10*log10(mean(R.^2));

    if (E <= E_0)
        U = gamma_0;
    elseif (E > E_0 && E < E_1)
        U = E*(gamma_0 - gamma_1)/(E_0 - E_1) + gamma_0 - (gamma_0 - gamma_1)/(1 - E_1/E_0);
    else
        U = gamma_1;   
    end

    if (mod(length(x), samples_frame) ~= 0) % se rellena x con ceros para que llegue a un multiplo del periodo de trama
        x = [x; zeros(samples_frame*ceil(length(x)/samples_frame) - length(x), 1)];        
    end

    X = zeros(NFFT, length(x)/samples_frame);
    for l = 0 : size(X, 2) - 1
       lim_max = l*samples_frame + samples_window; 
       if lim_max > samples_frame*size(X, 2)
          lim_max = samples_frame*size(X, 2);          
       end
       X(:, l + 1) = abs(fft(x(l*samples_frame + 1 : lim_max) .* hamming(lim_max - l*samples_frame), NFFT)); 
    end


    LTSE = X;

    for k = 1 : size(X, 1) 
       for l = 1 : size(X, 2)       
           j_1 = l - N;
           j_2 = l + N;
           if j_1 < 1           
               j_1 = 1;
           end
           if j_2 > size(X, 2)
               j_2 = size(X, 2);
           end 
           LTSE(k, l) = max(X(k, j_1 : j_2));
       end
    end
    
   LTSD = 10*log10(mean(LTSE.^2./repmat(R.^2, [1 size(LTSE, 2)])));
   vector = double(LTSD > U);
   
   
    vector_expand = zeros(size(x));
    for l = 1 : length(vector)        
       vector_expand((l - 1)*samples_frame + 1 : l*samples_frame) = vector(l);
    end    
    vector_expand = vector_expand.*x;
    
    vector_expand = vector_expand(vector_expand ~= 0);


end