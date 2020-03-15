function [x] = NMF (y, f_s, period_frame, Wr, Ws)


    size_window = 20e-3; % window size

    samples_window = f_s * size_window;
    samples_frame = f_s * period_frame;

    NFFT = 2^ceil(log2(samples_window));
    
    Vr_complex = zeros(NFFT, floor(length(y)/samples_frame));
    for l = 0 : size(Vr_complex, 2) - 1
       lim_max = l*samples_frame + samples_window; 
       if lim_max > samples_frame*size(Vr_complex, 2)
          lim_max = samples_frame*size(Vr_complex, 2);          
       end
       Vr_complex(:, l + 1) = fft(y(l*samples_frame + 1 : lim_max) .* rectwin(lim_max - l*samples_frame), NFFT); 
    end
    Vr = abs(Vr_complex);


    [Wr_test,Hr,~,~] = nmf_alg(Vr,128,'W',Wr,'alg',@nmf_kl);
    Hs = Hr(1:64,:);
    Vr_prima = Ws*Hs;
    x_aux = zeros(floor(length(y)/samples_frame), samples_window);
    
    for k=1:size(Vr,2)
        aux = ifft(Vr_prima(:,k).*exp(1j*phase(Vr_complex(:,k))),512)';
        x_aux(k,:) = aux(1:samples_window);
    end
    
    x_aux = real(x_aux);
    [x, ~] = overlapadd(x_aux,rectwin(samples_window), samples_frame);
    


end