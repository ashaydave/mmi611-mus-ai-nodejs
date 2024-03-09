% function get_onsets_and_synthesize(user)

% Copyright Tom Collins 20/2/2024

% Compute spectrogram peaks for a directory of audio files.

% Individual user paths
addpath('C:\Users\ashay\source\repos\HW5-MMI611');

inDir = fullfile('/Users', 'ashay', 'source',...
    'repos', 'HW5-MMI611', 'small_dir_audio');
outDir = fullfile('/Users', 'ashay', 'source',...
    'repos', 'HW5-MMI611', 'small_dir_audio', 'outputSF');
clickFile = fullfile('/Users', 'ashay', 'source',...
    'repos', 'HW5-MMI611', 'click.wav');

% Parameters
nfft = 1024;
win = hann(nfft);
overlap = 7*nfft/8; % 87.5% overlap between adjacent spectra.
% step = nfft - overlap;
% Given above params, this value of nrows would mean the analysis considers
% frequency components in the range 0-10.8 kHz (=500*44100/1024)
nrows = 250;
% Spectral flux values larger than 40 will be considered big enough.
thresh = 40;

% Import and analyse the audio files.
% Obtain details of all the WAV and MP3 files in inDir.
inWavs = fullfile(inDir, '*.wav');
inMp3s = fullfile(inDir, '*.mp3');
fnams = [dir(inWavs); dir(inMp3s)];
naud = length(fnams);
click = audioread(clickFile);

% Iterate.
for i=1:naud
  fprintf('Processing file %d of %d.\n', i, naud);
  % Import audio file.
  [sig, Fs] = audioread(fullfile(fnams(i).folder, fnams(i).name));
  % Spectrogram
  [u, f, ta] = stft(...
    sig(:, 1), Fs, Window = win, OverlapLength = overlap, FFTLength = nfft...
  );
  ua = abs(u(nfft/2:nfft/2 + nrows - 1, :));

  % Show spectrogram.
  close all; imagesc(-ua); colormap 'gray'; axis xy
  xlabel('Time (Spectrogram Increment)', 'FontSize', 18);
  ylabel('Frequency (Spectrogram Increment)', 'FontSize', 18);

  %% YOU COME IN HERE! %%
  % Calculate spectral flux.
  sf = sum(diff(ua, 1, 2));
  sfa = zeros(size(sf));
  for j=1:length(sfa)
    if (sf(j) > thresh)
      sfa(j) = sf(j);
    end
  end
  
  sf2 = diff(sum(ua));
  sf2a = zeros(size(sf2));
  for j=1:length(sf2a)
    if (sf2(j) > thresh)
      sf2a(j) = sf2(j);
    end
  end
  [pks,locs] = findpeaks(sfa);
  % Plot/visualize.
  close all; plot(sf,'b');
  hold on; plot(sfa, 'g'); hold off;
  % findpeaks(sf2)
  [pks_sf2, locs_sf2] = findpeaks(sf2a);
  close all; plot(sf2,'b');
  hold on; plot(sf2a, 'g'); hold off;
  % Synthesize an audio file that contains the original audio in the left
  % channel and the detected onsets as clicks in the right channel.
  y = zeros(size(sig, 1), 2);
  y(:, 1) = sig(:, 1);
  for j=1:length(locs)
    currTime = ta(locs(j));
    cts = round(Fs*currTime); % Short for current time sample.
    y(cts:cts + length(click) - 1, 2) = y(cts:cts + length(click) - 1, 2)...
      + click;
  end
  y(:, 2) = 0.8*y(:, 2)/max(abs(y(:, 2))); % Normalize to [-.8, .8].
  fnams(i).onsets = [locs' pks']; % Store the peak locations.
  
  % Write output to file.
  audiowrite(fullfile(outDir, fnams(i).name), y, Fs);
  outfnam = fullfile(outDir, [fnams(i).name '.json']); 
  fid = fopen(outfnam, 'w');
  encodedJson = jsonencode(fnams(i));
  fprintf(fid, encodedJson);
  % fprintf(fid, '%d', [1, 2]);
  fclose(fid);
end
