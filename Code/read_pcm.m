function x = read_pcm(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Read a PCM format sound file
%
% Inputs
%    filename: input sound file
%
% Outputs
%    x: data vector containing the sound samples
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fid = fopen(filename, 'r', 'b');
if fid == -1,
    fprintf('File %s does not exist\n');
    return;
end
x = fread(fid, 'int16');
fclose(fid);


