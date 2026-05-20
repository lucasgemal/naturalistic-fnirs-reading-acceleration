% =========================================================================
% pre_processamento.m
%
% PURPOSE  : fNIRS preprocessing pipeline and first-level GLM for the
%            ACELETRA reading acceleration study.
%
% INPUTS   : backup — raw nirs.core.Data array (140 sessions,
%                     14 subjects × 10 sessions each)
%            Stimulus events must already be reconstructed via
%            contagem_nova.m before running this script.
%
% OUTPUTS  : hb_processado.mat  — preprocessed hemodynamic data
%            SubjStats.mat      — first-level GLM results (140 objects)
%
% PIPELINE STEPS:
%   1. Resample       → Fs = 4 Hz
%   2. TrimBaseline   → retain 10 s post-baseline
%   3. OpticalDensity → convert raw intensity to ΔOD
%   4. BeerLambertLaw → compute HbO, HbR, HbT, StO2
%   5. CalculateTotalHb → add HbT channel
%   6. BandPassFilter → 0.01–0.10 Hz (removes drift and high-freq noise)
%   7. WaveletFilter  → wavelet-based motion artifact correction
%   8. GLM (1st level)→ AddShortSepRegressors=1 for surface noise removal
%
% TOOLBOX  : NIRS Toolbox (Santosa et al., 2018) — MATLAB
% AUTHOR   : Lucas Gemal (lucasgemal@gmail.com) — IDOR / UFRJ
% =========================================================================

%% PRÉ-PROCESSAMENTO + GLM — Projeto SESI
%% Pipeline atualizado com BandPassFilter

%% Passo 1 — Resample
jobs1 = nirs.modules.Resample();
jobs1.Fs = 4;  % target sampling rate (Hz); original acquisition ~4.36 Hz
hb_rs = jobs1.run(backup);
fprintf('Resample OK: %d sessões | Fs=%.4f Hz\n', ...
    length(hb_rs), 1/mean(diff(hb_rs(1).time)));

%% Passo 2 — TrimBaseline
jobs2 = nirs.modules.TrimBaseline();
jobs2.preBaseline  = 0;   % seconds to retain before first stimulus
jobs2.postBaseline = 10;  % seconds to retain after last stimulus
hb_tb = jobs2.run(hb_rs);
fprintf('TrimBaseline OK: %d sessões\n', length(hb_tb));

%% Passo 3 — OpticalDensity
jobs3 = nirs.modules.OpticalDensity();
hb_od = jobs3.run(hb_tb);
fprintf('OpticalDensity OK: %d sessões\n', length(hb_od));

%% Passo 4 — BeerLambertLaw
jobs4 = nirs.modules.BeerLambertLaw();
hb_bl = jobs4.run(hb_od);
fprintf('BeerLambertLaw OK: %d sessões\n', length(hb_bl));

%% Passo 5 — CalculateTotalHb
jobs5 = nirs.modules.CalculateTotalHb();
hb_hbt = jobs5.run(hb_bl);
fprintf('CalculateTotalHb OK: %d sessões\n', length(hb_hbt));

%% Passo 6 — BandPassFilter CORRIGIDO
jobs6 = nirs.modules.BandPassFilter();
jobs6.highpass     = 0.01;  % high-pass cutoff (Hz): removes slow drift
jobs6.lowpass      = 0.10;  % low-pass cutoff (Hz): retains hemodynamic response band
jobs6.do_downsample = 0;    % keep at 4 Hz; no further downsampling
hb_bp = jobs6.run(hb_hbt);
fprintf('BandPassFilter OK: %d sessões | Fs=%.4f Hz\n', ...
    length(hb_bp), 1/mean(diff(hb_bp(1).time)));
%% Passo 7 — WaveletFilter (artefatos de movimento)
jobs7 = nirs.modules.WaveletFilter();
hb = jobs7.run(hb_bp);
fprintf('WaveletFilter OK: %d sessões\n', length(hb));

%% Transfere estímulos (WaveletFilter não propaga)
for i = 1:length(hb)
    hb(i).stimulus = backup(i).stimulus;
end
fprintf('Estímulos transferidos.\n');

%% Verificação rápida
fprintf('\nVerificação:\n');
fprintf('  Fs:         %.4f Hz\n', 1/mean(diff(hb(1).time)));
fprintf('  Shape:      %s\n', mat2str(size(hb(1).data)));
fprintf('  NaN:        %d\n', sum(isnan(hb(1).data(:))));
fprintf('  Cromóforos: '); disp(unique(hb(1).probe.link.type)')

%% Salva
save('hb_processado.mat', 'hb', '-v7.3');
fprintf('hb salvo.\n');

%% GLM — 1º nível
% Canonical HRF convolved with block-design stimulus function.
% Short-separation (SS) channels act as regressors to remove scalp
% hemodynamics from the fNIRS signal (Scholkmann et al., 2014).
jobs_glm = nirs.modules.GLM();
jobs_glm.AddShortSepRegressors = 1;  % use SS channels as nuisance regressors
SubjStats = jobs_glm.run(hb);
fprintf('GLM concluído. Total: %d\n', length(SubjStats));

%% Verificação GLM
SubjStats(1).draw('beta', [-10 10], 'p<0.05');
title('SUBJ\_002 ac\_01 — betas individuais');

%% Salva
save('SubjStats.mat', 'SubjStats', '-v7.3');
fprintf('SubjStats salvo.\n');