function [x] = SS (y, f_s, period_frame) 

    size_window = 20e-3; % window size
    time_nonspeech = 150e-3; % first 150 ms of the signal, as they are assumed to be non-speech portions

    samples_window = f_s * size_window;
    samples_frame = f_s * period_frame;
    samples_nonspeech = f_s * time_nonspeech;
 

    NFFT = 2^ceil(log2(samples_window));
    
    D = zeros(NFFT, samples_nonspeech/samples_frame);

    for l = 0 : size(D, 2) - 1
       lim_max = l*samples_frame + samples_window; 
       if lim_max > samples_frame*size(D, 2)
          lim_max = samples_frame*size(D, 2);          
       end
       D(:, l + 1) = abs(fft(y(l*samples_frame + 1 : lim_max).* rectwin(lim_max - l*samples_frame), NFFT)); 
    end
    D = mean(D, 2);

    if (mod(length(y), samples_frame) ~= 0) % se rellena y con ceros para que llegue a un multiplo del periodo de trama
        y = [y; zeros(samples_frame*ceil(length(y)/samples_frame) - length(y), 1)];        
    end

    Y = zeros(NFFT, length(y)/samples_frame);
    for l = 0 : size(Y, 2) - 1
       lim_max = l*samples_frame + samples_window; 
       if lim_max > samples_frame*size(Y, 2)
          lim_max = samples_frame*size(Y, 2);          
       end
       Y(:, l + 1) = fft(y(l*samples_frame + 1 : lim_max) .* rectwin(lim_max - l*samples_frame), NFFT); 
    end


    SSNR = sum(abs(Y).^2,1)/sum(D.^2);
    
    alfa = (4 - (3/20).*SSNR).*(SSNR>=-5 & SSNR<=20) + 1.*(SSNR>20) + 5.*(SSNR<-5);
    beta = 0.01;
    
    S = zeros(size(Y));
    for l=1:size(Y,2)
        for w=1:size(Y,1)
            if((alfa(l)+beta)*abs(D(w))^2 < abs(Y(w,l))^2)
                S(w,l) = abs(Y(w,l)^2)-alfa(l)*abs(D(w))^2;
            else
                S(w,l) = beta*abs(D(w))^2;
            end
        end
        
    end
    
    s=zeros(size(Y,2), samples_window);
    for k=1:size(Y,2)
        s_aux = ifft(sqrt(S(:,k)).*exp(1j*phase(Y(:,k))),NFFT)';
        s(k,:) = s_aux(1:samples_window);
    end
    
    
    [x, ~] = overlapadd(s,rectwin(samples_window), samples_frame);
    x = real(x);

end