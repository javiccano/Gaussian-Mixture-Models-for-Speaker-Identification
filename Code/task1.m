%%% Task 1 %%%%

function [decisiones_clean, decisiones_noisy] = task1()

    sr = 16e3;
    
    %TRAIN%
    X_train = cell(16, 1);
    cepstra_train = cell(16, 1);
    gaussianas = cell(16, 1);
    for i = 1 : 16

        X_train{i} = load_train_data('list_train.txt', i);
        [cepstra_train{i}, ~, ~] = melfcc(X_train{i}, sr, 'wintime', 0.02, 'hoptime', 0.01, 'numcep', 20);
        gaussianas{i} = gmdistribution.fit(cepstra_train{i}',16, 'CovType', 'diagonal', 'Replicates', 3);

    end
    
    %TEST%
    cepstra_test_clean = cell(10, 1);
    cepstra_test_noisy = cell(10, 1);
    decisiones_clean = zeros(160,1);
    decisiones_noisy = zeros(160,1);

    for i = 1 : 16

        X_test_clean = load_test_data('list_test1.txt', i);
        X_test_noisy = load_test_data('list_test2.txt', i);
        for j = 1 : 10
            [cepstra_test_clean{j}, ~, ~] = melfcc(X_test_clean{j}, sr, 'wintime', 0.02, 'hoptime', 0.01, 'numcep', 20);
            [cepstra_test_noisy{j}, ~, ~] = melfcc(X_test_noisy{j}, sr, 'wintime', 0.02, 'hoptime', 0.01, 'numcep', 20);
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

end