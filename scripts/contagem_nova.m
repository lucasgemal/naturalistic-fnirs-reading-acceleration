% =========================================================================
% contagem_nova.m
%
% PURPOSE  : Reconstruct task-block stimulus events from raw ACELETRA
%            trial-level triggers. Raw data contain individual trial
%            onsets; this script collapses them into reading blocks
%            suitable for a block-design GLM.
%
% INPUTS   : raw — nirs.core.Data array (140 sessions) with per-trial
%                  stimulus channels ('onset', 'fim', 'repouso')
%
% OUTPUTS  : backup — same array with a single 'Aceletra' StimulusEvents
%                     object per session (onset, duration, amplitude)
%
% DESIGN   : calibration sessions → 4 blocks
%            training sessions (ac_01–ac_09) → 7 blocks each
%            5 stimuli (NstimPerBlock) expected per block
%
% AUTHOR   : Lucas Gemal (lucasgemal@gmail.com) — IDOR / UFRJ
% =========================================================================

backup = raw;
Nome   = 'Aceletra';
NstimPerBlock = 5;  % expected number of reading stimuli per block

for i = 1:length(backup)

    sessao  = backup(i).demographics('experiment');
    subject = backup(i).demographics('subject');

    if strcmp(sessao, 'calibracao')
        Nblocks_esperado = 4;
    else
        Nblocks_esperado = 7;
    end

    stim_names = cellfun(@(x) x.name, ...
        backup(i).stimulus.values, 'UniformOutput', false);

    n_eventos = cellfun(@(x) length(x.onset), backup(i).stimulus.values);
    [~, idx_repouso] = min(n_eventos);
    idx_leitura = setdiff(1:length(backup(i).stimulus.values), idx_repouso);

    if isempty(idx_leitura)
        warning('Sujeito %d (%s/%s): sem canais de leitura', i, subject, sessao);
        continue
    end

    idx_onset = idx_leitura(1);
    idx_fim   = idx_leitura(end);

    onsets_onset   = backup(i).stimulus.values{idx_onset}.onset;
    onsets_fim     = backup(i).stimulus.values{idx_fim}.onset;
    onsets_repouso = backup(i).stimulus.values{idx_repouso}.onset;

    Nblocks_real = length(onsets_repouso);

    if Nblocks_real ~= Nblocks_esperado
        warning('Sujeito %d (%s/%s): esperado %d blocos, encontrado %d', ...
            i, subject, sessao, Nblocks_esperado, Nblocks_real);
    end

    limites   = [0; onsets_repouso(:); Inf];
    onsets    = [];
    duracoes  = [];
    amplitude = [];

    for b = 1:Nblocks_real
        t_inicio = limites(b);
        t_fim_b  = limites(b+1);

        idx_ev_onset = find(onsets_onset > t_inicio & onsets_onset < t_fim_b);
        idx_ev_fim   = find(onsets_fim   > t_inicio & onsets_fim   < t_fim_b);

        if isempty(idx_ev_onset)
            warning('Sujeito %d (%s/%s) bloco %d: sem eventos — pulando', ...
                i, subject, sessao, b);
            continue
        end

        onset_bloco = onsets_onset(idx_ev_onset(1));

        if ~isempty(idx_ev_fim)
            fim_bloco = onsets_fim(idx_ev_fim(end));
        else
            fim_bloco = onsets_onset(idx_ev_onset(end));
        end

        onsets(end+1)    = onset_bloco;
        duracoes(end+1)  = fim_bloco - onset_bloco;
        amplitude(end+1) = 1;

        n_ev = length(idx_ev_onset);
        if n_ev ~= NstimPerBlock
            warning('Sujeito %d (%s/%s) bloco %d: %d estímulos (esperado %d)', ...
                i, subject, sessao, b, n_ev, NstimPerBlock);
        end
    end

    if isempty(onsets)
        warning('Sujeito %d (%s/%s): nenhum bloco extraído', i, subject, sessao);
        continue
    end

    % Descarta canais originais
    estimulo = nirs.modules.DiscardStims;
    estimulo.listOfStims = stim_names;
    backup(i) = estimulo.run(backup(i));

    % Cria novo estímulo — sintaxe correta nova versão
    novo_stim        = nirs.design.StimulusEvents();
    novo_stim.name   = Nome;
    novo_stim.onset  = onsets(:);
    novo_stim.dur    = duracoes(:);
    novo_stim.amp    = amplitude(:);

    % Atribui via chave string no Dictionary
    backup(i).stimulus(Nome) = novo_stim;

    fprintf('Sujeito %3d | %s | %-12s | B=%d/%d | dur média=%.1fs\n', ...
        i, subject, sessao, length(onsets), Nblocks_esperado, mean(duracoes));
end