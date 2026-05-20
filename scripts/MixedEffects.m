% =========================================================================
% MixedEffects.m
%
% PURPOSE  : Second-level (group) mixed-effects GLM for the ACELETRA
%            fNIRS study. Estimates group-level beta coefficients per
%            session (experiment) separately for each group.
%
% INPUTS   : SubjStats — array of 140 first-level GLM result objects
%                        (14 subjects × 10 sessions), produced by
%                        pre_processamento.m
%
% OUTPUTS  : GroupStats.mat — group-level GLM result object
%
% MODEL    : beta ~ -1 + group:experiment + (1|subject)
%            No intercept; group × session interaction estimated directly.
%            Robust estimation (Huber M-estimator) to reduce leverage of
%            outlier sessions.
%
% TOOLBOX  : NIRS Toolbox (Santosa et al., 2018) — MATLAB
% AUTHOR   : Lucas Gemal (lucasgemal@gmail.com) — IDOR / UFRJ
% =========================================================================

%% MixedEffects — 2º nível
j = nirs.modules.MixedEffects();
j.formula = 'beta ~ -1 + group:experiment + (1|subject)';  % no global intercept; separate mean per group:session
j.robust  = 1;  % Huber M-estimation to down-weight high-leverage sessions
GroupStats = j.run(SubjStats);

fprintf('MixedEffects concluído.\n');

%% Salva
save('GroupStats.mat', 'GroupStats', '-v7.3');
fprintf('GroupStats salvo.\n');