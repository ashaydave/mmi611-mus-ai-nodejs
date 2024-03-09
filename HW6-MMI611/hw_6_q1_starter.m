% function get_peaks_and_calc_fingerprints(user)

% Copyright Tom Collins 20/2/2024

% Compute spectrogram peaks for a directory of audio files.

% Requires
addpath('C:\Users\ashay\source\repos\HW6-MMI611');

inDir = fullfile('/Users', 'ashay', 'source',...
    'repos', 'HW6-MMI611', 'small_dir_audio');
outDir = fullfile('/Users', 'ashay', 'source',...
    'repos', 'HW6-MMI611', 'matlab_out');

% Parameters
param = struct;

% Frequency analysis
param.fft = struct('nfft', 1024);
param.fft.win = hann(param.fft.nfft);

% 87.5% overlap between adjacent spectra.
param.fft.overlap = 7*param.fft.nfft/8;

% Given above params, this value of nrows would mean the analysis considers
% frequency components in the range 0-10.8 kHz (=250*44100/1024)
param.fft.nrows = 250;
param.ppeak = struct();

% When extracting peaks, how many seconds of STFT to analyze at a time.
param.ppeak.winLength = 2.5;

% How much to step from one analysis to the next.
param.ppeak.winStep = 2.5;

% A value will have to be in the top 2.5% of magnitude spectra values to
% even be considered a peak.
param.ppeak.thresh = 0.975;

% Fingerprint parameters
param.fp = struct('mode', 'shazam', 'timeDiffMin', 0.1,...
  'timeDiffMax', 1, 'fIdxDiffMin', 5, 'fIdxDiffMax', 150);

% Set up output/updating variables
s = struct;
s.hashMap = struct; % Will hold the hash codes and song/time info.
s.idCumu = []; % Keeps track of the cumulative sample.
cumuSamp = 0;

% Import and analyse the audio files.
% Obtain details of all the WAV and MP3 files in inDir.
inWavs = fullfile(inDir, '*.wav');
inMp3s = fullfile(inDir, '*.mp3');
fnams = [dir(inWavs); dir(inMp3s)];
naud = length(fnams);

% Can't be bothered to keep writing param.fft.nfft!
nfft = param.fft.nfft;

% Iterate.
for i=1:naud
  fprintf('Processing file %d of %d.\n', i, naud);
  % Import audio file.
  [sig, Fs] = audioread(fullfile(fnams(i).folder, fnams(i).name));
  % Spectrogram
  % Just left channel. Could do both or take the mean instead.
  [u, f, ta] = stft(...
    sig(:, 1), Fs, Window = param.fft.win,...
    OverlapLength = param.fft.overlap,...
    FFTLength = nfft...
  );
  ua = abs(u(nfft/2:nfft/2 + param.fft.nrows - 1, :));
  f = f(nfft/2:nfft/2 + param.fft.nrows - 1);

  % Show spectrogram.
  % close all; imagesc(-ua); colormap 'gray'; axis xy
  % xlabel('Time (Spectrogram Increment)', 'FontSize', 18);
  % ylabel('Frequency (Spectrogram Increment)', 'FontSize', 18);

  % Pick peaks.
  tdiff = ta(2) - ta(1);
  colsPerWin = floor(param.ppeak.winLength/tdiff);
  colsPerStep = floor(param.ppeak.winStep/tdiff);
  for j=1:floor(size(ua, 2)/colsPerStep)
    startIdx = colsPerStep*(j - 1) + 1;
    endIdx = startIdx + colsPerWin - 1;
    uaPart = ua(:, startIdx:endIdx);
    rawThresh = quantile(uaPart(:), param.ppeak.thresh);
    IJ = FastPeakFind(uaPart, rawThresh);
    I = IJ(2:2:end);
    J = IJ(1:2:end) + startIdx - 1;
    % Plot/visualize.
    % imagesc(-uaPart); colormap 'gray'; axis xy
    % xlabel('Time (Spectrogram Increment)', 'FontSize', 18);
    % ylabel('Frequency (Spectrogram Increment)', 'FontSize', 18);
    hold on; plot(IJ(1:2:end), I, 'r+'); hold off;
    param.fp.fs = Fs;
    param.fp.colTimes = ta;
    param.fp.cumuSamp = cumuSamp;
    param.fp.idPiece = fnams(i).name;
    s = calc_fingerprints([I J], s, param.fp);
    % Keep track of cumuSamp values.
    s.idCumu = [s.idCumu...
      struct('fnam', param.fp.idPiece, 'cumuSamp', cumuSamp...
    )];
    cumuSamp = cumuSamp + size(sig, 1);
  end
end

% Write s to file.
save(fullfile(outDir, 'fp.mat'), "s");