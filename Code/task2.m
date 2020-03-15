%%% Task 2 %%%

function [error_clean, error_noisy] = task2(decisiones_clean, decisiones_noisy)

    etiquetas = zeros(160,1);
    for i = 1 : 16
        etiquetas((i-1)*10+1:(i-1)*10+1+9) = i;
    end

    error_clean = mean(decisiones_clean ~= etiquetas);
    error_noisy = mean(decisiones_noisy ~= etiquetas);

end
