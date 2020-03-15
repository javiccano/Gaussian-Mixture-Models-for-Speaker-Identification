%%% Task 5 %%%

function [error_clean_nmf, error_noisy_nmf] = task5()

    sr = 16e3;
    period_frame = 10e-3;
    size_window = 20e-3;
    samples_window = sr * size_window;
    samples_frame = sr * period_frame;
    NFFT = 2^ceil(log2(samples_window));

    %TRAIN%
    X_train_NMF = cell(16, 1);
    X_train_NMF_VAD = cell(16,1);
    cepstra_train = cell(16, 1);
    gaussianas = cell(16, 1);
    for i = 1 : 16
        X_train_NMF{i} = load_train_data('list_train.txt', i);
        X_train_NMF_VAD{i} = VAD (X_train_NMF{i}, sr, period_frame);
        [cepstra_train{i}, ~, ~] = melfcc(X_train_NMF_VAD{i}, sr, 'wintime', 0.02, 'hoptime', 0.01, 'numcep', 20);
        gaussianas{i} = gmdistribution.fit(cepstra_train{i}',16, 'CovType', 'diagonal', 'Replicates', 3);
    end
    
    voz_train = cat(1, X_train_NMF{1}, X_train_NMF{2}, X_train_NMF{3}, X_train_NMF{4},...
        X_train_NMF{5}, X_train_NMF{6}, X_train_NMF{7}, X_train_NMF{8}, ...
        X_train_NMF{9}, X_train_NMF{10}, X_train_NMF{11}, X_train_NMF{12},...
        X_train_NMF{13}, X_train_NMF{14}, X_train_NMF{15}, X_train_NMF{16});

    ruido = audioread('..\speechdata\noise\factory1.wav');

    
    Vs = zeros(NFFT, floor(length(voz_train)/samples_frame));
    for i = 0 : size(Vs, 2) - 1
       lim_max = i*samples_frame + samples_window; 
       if lim_max > samples_frame*size(Vs, 2)
          lim_max = samples_frame*size(Vs, 2);          
       end
       Vs(:, i + 1) = abs(fft(voz_train(i*samples_frame + 1 : lim_max) .* rectwin(lim_max - i*samples_frame), NFFT)); 
    end

    Vn = zeros(NFFT, floor(length(ruido)/samples_frame));
    for i = 0 : size(Vn, 2) - 1
       lim_max = i*samples_frame + samples_window; 
       if lim_max > samples_frame*size(Vn, 2)
          lim_max = samples_frame*size(Vn, 2);          
       end
       Vn(:, i + 1) = abs(fft(ruido(i*samples_frame + 1 : lim_max) .* rectwin(lim_max - i*samples_frame), NFFT)); 
    end

    r = 64;

    [Ws,~,~,~] = nmf_alg(Vs,r,'alg',@nmf_kl);
    [Wn,~,~,~] = nmf_alg(Vn,r,'alg',@nmf_kl);

    Wr = [Ws, Wn];


    %TEST%

    X_test_clean_NMF_VAD = cell(10, 1);
    X_test_noisy_NMF_VAD = cell(10, 1);

    cepstra_test_clean = cell(10, 1);
    cepstra_test_noisy = cell(10, 1);
    decisiones_clean = zeros(160,1);
    decisiones_noisy = zeros(160,1);



    for i = 1 : 16

        X_test_clean_NMF = load_test_data('list_test1.txt', i);
        X_test_noisy_NMF = load_test_data('list_test2.txt', i);
        for j = 1 : 10

            X_test_clean_NMF{j} = NMF (X_test_clean_NMF{j}, sr, period_frame, Wr, Ws);
            X_test_noisy_NMF{j} = NMF (X_test_noisy_NMF{j}, sr, period_frame, Wr, Ws);
            X_test_clean_NMF_VAD{j} = VAD (X_test_clean_NMF{j}, sr, period_frame);
            X_test_noisy_NMF_VAD{j} = VAD (X_test_noisy_NMF{j}, sr, period_frame);
        end


        for j = 1 : 10
            [cepstra_test_clean{j}, ~, ~] = melfcc(X_test_clean_NMF_VAD{j}, sr, 'wintime', 0.02, 'hoptime', 0.01, 'numcep', 20);
            [cepstra_test_noisy{j}, ~, ~] = melfcc(X_test_noisy_NMF_VAD{j}, sr, 'wintime', 0.02, 'hoptime', 0.01, 'numcep', 20);
        end


        Prob_clean = zeros(16,1);
        Prob_noisy = zeros(16,1);

        for k = 1 : 10
            for j = 1 : 16
                P_clean = pdf(gaussianas{j}, cepstra_test_clean{k}');
                P_clean = sum(log(P_clean));
                Prob_clean(j) = P_clean;

                P_noisy = pdf(gaussianas{j}, cepstra_test_noisy{k}');
                P_noisy = sum(log(P_noisy));
                Prob_noisy(j) = P_noisy;
            end
            [~, decisiones_clean((i-1)*10+k)] = max(Prob_clean);
            [~, decisiones_noisy((i-1)*10+k)] = max(Prob_noisy);
        end    
    end
    
    [error_clean_nmf, error_noisy_nmf] = task2(decisiones_clean, decisiones_noisy);

    
end
