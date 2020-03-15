close all
clear all
clc
warning('off')

%%% Task 1 %%%

[decisiones_clean, decisiones_noisy] = task1();

%%% Task 2 %%%

[error_clean_prev, error_noisy_prev] = task2(decisiones_clean, decisiones_noisy);

%%% Task 3 %%%

[error_clean_vad, error_noisy_vad] = task3();

%%% Task 4 %%%

[error_clean_ss, error_noisy_ss] = task4();

%%% Task 5 %%%

[error_clean_nmf, error_noisy_nmf] = task5();

clc

fprintf('\n\n\n\nIdentification Accuracy (%%):\n\n');
fprintf('\t\t  clean\t\t  noisy\n');
fprintf('Base\t%f\t%f\n',(1-error_clean_prev)*100, (1-error_noisy_prev)*100);
fprintf('VAD\t\t%f\t%f\n',(1-error_clean_vad)*100, (1-error_noisy_vad)*100);
fprintf('SS\t\t%f\t%f\n',(1-error_clean_ss)*100, (1-error_noisy_ss)*100);
fprintf('NMF\t\t%f\t%f\n',(1-error_clean_nmf)*100, (1-error_noisy_nmf)*100);
