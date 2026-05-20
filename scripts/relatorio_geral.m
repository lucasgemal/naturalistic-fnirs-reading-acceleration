% =========================================================================
% relatorio_geral.m
%
% PURPOSE  : Quality control report for the fNIRS preprocessing pipeline.
%            Validates all key properties of the processed data and GLM
%            outputs before proceeding to group-level analysis.
%
% INPUTS   : hb        — preprocessed nirs.core.Data array (140 sessions)
%            SubjStats — first-level GLM results (140 objects)
%
% OUTPUTS  : Console report with pass/fail for each QC check (no file).
%
% CHECKS   :
%   Block 1 — Basic structure: N sessions (140), Fs (4 Hz),
%             chromophores (StO2, HbO, HbR, HbT), N channels (100)
%   Block 2 — Signal quality: NaN, Inf, amplitude range, flat signals
%   Block 3 — Stimulus integrity: presence, name, block count, durations
%   Block 4 — Demographics: group labels, sessions per subject, subject IDs
%   Block 5 — GLM consistency: N SubjStats, condition name, NaN in betas
%
% AUTHOR   : Lucas Gemal (lucasgemal@gmail.com) — IDOR / UFRJ
% =========================================================================

%% VERIFICADOR COMPLETO DO PRÉ-PROCESSAMENTO
%% Projeto SESI — fNIRS Pipeline Quality Check

fprintf('╔══════════════════════════════════════════════════════╗\n');
fprintf('║     VERIFICAÇÃO DO PRÉ-PROCESSAMENTO — SESI fNIRS   ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n\n');

erros    = {};
avisos   = {};
ok_count = 0;
total    = 0;

% =========================================================================
%% BLOCO 1 — ESTRUTURA BÁSICA
% =========================================================================
fprintf('━━━ BLOCO 1: ESTRUTURA BÁSICA ━━━━━━━━━━━━━━━━━━━━━━━━\n');

% 1.1 N total de sessões
total = total + 1;
n_sessoes = length(hb);
if n_sessoes == 140
    fprintf('  ✔ [1.1] N sessões: %d (esperado: 140)\n', n_sessoes);
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [1.1] N sessões: %d (esperado: 140)\n', n_sessoes);
    erros{end+1} = sprintf('N sessões = %d (esperado 140)', n_sessoes);
end

% 1.2 Frequência de amostragem
total = total + 1;
fs_vals = arrayfun(@(i) 1/mean(diff(hb(i).time)), 1:length(hb));
fs_unico = unique(round(fs_vals, 4));
if all(abs(fs_vals - 4.0) < 0.01)
    fprintf('  ✔ [1.2] Fs: %.4f Hz em todas as sessões\n', mean(fs_vals));
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [1.2] Fs inconsistente: min=%.4f max=%.4f\n', min(fs_vals), max(fs_vals));
    erros{end+1} = 'Fs inconsistente entre sessões';
end

% 1.3 Cromóforos
total = total + 1;
tipos = unique(hb(1).probe.link.type);
tipos_esperados = {'StO2','hbo','hbr','hbt'};
if all(ismember(tipos_esperados, tipos))
    fprintf('  ✔ [1.3] Cromóforos: %s\n', strjoin(tipos_esperados, ', '));
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [1.3] Cromóforos faltando\n');
    erros{end+1} = 'Cromóforos incompletos';
end

% 1.4 N canais
total = total + 1;
n_canais = height(hb(1).probe.link);
if n_canais == 100
    fprintf('  ✔ [1.4] N canais: %d (25 × 4 cromóforos)\n', n_canais);
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [1.4] N canais: %d (esperado: 100)\n', n_canais);
    erros{end+1} = sprintf('N canais = %d', n_canais);
end

% =========================================================================
%% BLOCO 2 — QUALIDADE DOS DADOS
% =========================================================================
fprintf('\n━━━ BLOCO 2: QUALIDADE DOS DADOS ━━━━━━━━━━━━━━━━━━━━━\n');

% 2.1 NaN em todas as sessões
total = total + 1;
n_nan_total = sum(arrayfun(@(i) sum(isnan(hb(i).data(:))), 1:length(hb)));
if n_nan_total == 0
    fprintf('  ✔ [2.1] NaN: 0 em todas as sessões\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [2.1] NaN encontrados: %d\n', n_nan_total);
    erros{end+1} = sprintf('NaN = %d', n_nan_total);
end

% 2.2 Inf em todas as sessões
total = total + 1;
n_inf_total = sum(arrayfun(@(i) sum(isinf(hb(i).data(:))), 1:length(hb)));
if n_inf_total == 0
    fprintf('  ✔ [2.2] Inf: 0 em todas as sessões\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [2.2] Inf encontrados: %d\n', n_inf_total);
    erros{end+1} = sprintf('Inf = %d', n_inf_total);
end

% 2.3 Valores extremos (outliers globais)
total = total + 1;
hbo_idx = strcmp(hb(1).probe.link.type, 'hbo');
vals_hbo = [];
for i = 1:length(hb)
    vals_hbo = [vals_hbo; hb(i).data(:, hbo_idx)];
end
p1  = prctile(vals_hbo(:), 1);
p99 = prctile(vals_hbo(:), 99);
if p1 > -500 && p99 < 500
    fprintf('  ✔ [2.3] Amplitude hbo: [%.1f, %.1f] μM (dentro do esperado)\n', p1, p99);
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [2.3] Amplitude hbo fora do esperado: [%.1f, %.1f] μM\n', p1, p99);
    avisos{end+1} = sprintf('Amplitude hbo extrema: [%.1f, %.1f]', p1, p99);
end

% 2.4 Verifica sessões com sinal plano (std ≈ 0)
total = total + 1;
sessoes_planas = {};
for i = 1:length(hb)
    std_hbo = std(hb(i).data(:, find(hbo_idx, 1)));
    if std_hbo < 0.001
        sessoes_planas{end+1} = sprintf('%s/%s', ...
            hb(i).demographics('subject'), ...
            hb(i).demographics('experiment'));
    end
end
if isempty(sessoes_planas)
    fprintf('  ✔ [2.4] Sinal plano: nenhuma sessão\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [2.4] Sessões com sinal plano: %s\n', strjoin(sessoes_planas, ', '));
    erros{end+1} = sprintf('Sinal plano: %s', strjoin(sessoes_planas));
end

% =========================================================================
%% BLOCO 3 — ESTÍMULOS
% =========================================================================
fprintf('\n━━━ BLOCO 3: ESTÍMULOS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

% 3.1 Estímulos presentes em todas as sessões
total = total + 1;
sem_stim = {};
for i = 1:length(hb)
    if isempty(hb(i).stimulus.values)
        sem_stim{end+1} = sprintf('%s/%s', ...
            hb(i).demographics('subject'), ...
            hb(i).demographics('experiment'));
    end
end
if isempty(sem_stim)
    fprintf('  ✔ [3.1] Estímulos presentes em todas as sessões\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [3.1] Sessões sem estímulos (%d): %s\n', ...
        length(sem_stim), strjoin(sem_stim(1:min(3,end)), ', '));
    erros{end+1} = sprintf('%d sessões sem estímulos', length(sem_stim));
end

% 3.2 Nome do estímulo correto
total = total + 1;
nome_errado = {};
for i = 1:length(hb)
    if ~isempty(hb(i).stimulus.values)
        nome = hb(i).stimulus.values{1}.name;
        if ~strcmp(nome, 'Aceletra')
            nome_errado{end+1} = sprintf('%s/%s=%s', ...
                hb(i).demographics('subject'), ...
                hb(i).demographics('experiment'), nome);
        end
    end
end
if isempty(nome_errado)
    fprintf('  ✔ [3.2] Nome do estímulo: ''Aceletra'' em todas as sessões\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [3.2] Nome errado em %d sessões\n', length(nome_errado));
    erros{end+1} = 'Nome de estímulo incorreto';
end

% 3.3 N de blocos por sessão
total = total + 1;
blocos_errados = {};
for i = 1:length(hb)
    if isempty(hb(i).stimulus.values), continue; end
    exp  = hb(i).demographics('experiment');
    subj = hb(i).demographics('subject');
    n_bl = length(hb(i).stimulus.values{1}.onset);
    esperado = 4 + 3*(~strcmp(exp,'calibracao'));  % 4 ou 7

    % Casos especiais conhecidos
    eh_especial = (strcmp(subj,'SUBJ_027') && strcmp(exp,'ac_01')) || ...
                  (strcmp(subj,'SUBJ_037') && strcmp(exp,'ac_01')) || ...
                  (strcmp(subj,'SUBJ_037') && strcmp(exp,'calibracao')) || ...
                  (strcmp(subj,'SUBJ_001') && strcmp(exp,'calibracao'));

    if n_bl ~= esperado && ~eh_especial
        blocos_errados{end+1} = sprintf('%s/%s=%d(esp=%d)', ...
            subj, exp, n_bl, esperado);
    end
end
if isempty(blocos_errados)
    fprintf('  ✔ [3.3] N blocos correto em todas as sessões\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [3.3] N blocos incorreto: %s\n', ...
        strjoin(blocos_errados(1:min(3,end)), ', '));
    avisos{end+1} = sprintf('N blocos incorreto: %d sessões', length(blocos_errados));
end

% 3.4 Durações dos blocos razoáveis (5s–600s)
total = total + 1;
dur_problemas = {};
for i = 1:length(hb)
    if isempty(hb(i).stimulus.values), continue; end
    durs = hb(i).stimulus.values{1}.dur;
    if any(durs < 5) || any(durs > 600)
        dur_problemas{end+1} = sprintf('%s/%s', ...
            hb(i).demographics('subject'), ...
            hb(i).demographics('experiment'));
    end
end
if isempty(dur_problemas)
    fprintf('  ✔ [3.4] Durações dos blocos: todas entre 5s e 600s\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [3.4] Durações suspeitas em: %s\n', ...
        strjoin(dur_problemas(1:min(3,end)), ', '));
    avisos{end+1} = 'Durações de bloco fora do intervalo esperado';
end

% =========================================================================
%% BLOCO 4 — DEMOGRAPHICS
% =========================================================================
fprintf('\n━━━ BLOCO 4: DEMOGRAPHICS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

% 4.1 Grupos corretos
total = total + 1;
grupos_validos = {'acelerado','nao_acelerado'};
grp_errado = {};
for i = 1:length(hb)
    g = hb(i).demographics('group');
    if ~ismember(g, grupos_validos)
        grp_errado{end+1} = sprintf('%s=%s', ...
            hb(i).demographics('subject'), g);
    end
end
if isempty(grp_errado)
    fprintf('  ✔ [4.1] Grupos válidos em todas as sessões\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [4.1] Grupos inválidos: %s\n', strjoin(grp_errado, ', '));
    erros{end+1} = 'Grupos inválidos';
end

% 4.2 Sessões por sujeito
total = total + 1;
T_demo = nirs.createDemographicsTable(hb);
subjs  = unique(T_demo.subject);
sess_count_errado = {};
for s = 1:length(subjs)
    n_s = sum(strcmp(T_demo.subject, subjs{s}));
    if n_s ~= 10
        sess_count_errado{end+1} = sprintf('%s=%d', subjs{s}{1}, n_s);
    end
end
if isempty(sess_count_errado)
    fprintf('  ✔ [4.2] 10 sessões por sujeito em todos os 14 sujeitos\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [4.2] N sessões incorreto: %s\n', ...
        strjoin(sess_count_errado, ', '));
    avisos{end+1} = sprintf('N sessões incorreto: %s', ...
        strjoin(sess_count_errado));
end

% 4.3 Sujeitos esperados — versão corrigida
total = total + 1;
subjs_esperados = {'SUBJ_001','SUBJ_002','SUBJ_004','SUBJ_005','SUBJ_006', ...
                   'SUBJ_007','SUBJ_018','SUBJ_024','SUBJ_027','SUBJ_028', ...
                   'SUBJ_030','SUBJ_034','SUBJ_035','SUBJ_037'};

% Converte subjs para cell array de strings simples
subjs_str = {};
for k = 1:length(subjs)
    s = subjs{k};
    if iscell(s)
        subjs_str{end+1} = s{1};
    else
        subjs_str{end+1} = char(s);
    end
end

faltando = setdiff(subjs_esperados, subjs_str);
extras   = setdiff(subjs_str, subjs_esperados);

if isempty(faltando) && isempty(extras)
    fprintf('  ✔ [4.3] 14 sujeitos corretos presentes\n');
    ok_count = ok_count + 1;
else
    if ~isempty(faltando)
        fprintf('  ✗ [4.3] Sujeitos faltando: %s\n', strjoin(faltando,', '));
        erros{end+1} = sprintf('Faltando: %s', strjoin(faltando));
    end
    if ~isempty(extras)
        fprintf('  ✗ [4.3] Sujeitos extras: %s\n', strjoin(extras,', '));
        erros{end+1} = sprintf('Extras: %s', strjoin(extras));
    end
end

% =========================================================================
%% BLOCO 5 — CONSISTÊNCIA COM SUBJSTATS
% =========================================================================
fprintf('\n━━━ BLOCO 5: CONSISTÊNCIA COM SUBJSTATS ━━━━━━━━━━━━━━\n');

% 5.1 N SubjStats
total = total + 1;
if length(SubjStats) == 140
    fprintf('  ✔ [5.1] SubjStats: %d objetos\n', length(SubjStats));
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [5.1] SubjStats: %d (esperado 140)\n', length(SubjStats));
    erros{end+1} = sprintf('SubjStats = %d', length(SubjStats));
end

% 5.2 Condição nos SubjStats
total = total + 1;
cond_errada = {};
for i = 1:length(SubjStats)
    T_i = SubjStats(i).table();
    conds = unique(T_i.cond);
    if ~any(strcmp(conds, 'Aceletra'))
        cond_errada{end+1} = sprintf('%s/%s', ...
            SubjStats(i).demographics('subject'), ...
            SubjStats(i).demographics('experiment'));
    end
end
if isempty(cond_errada)
    fprintf('  ✔ [5.2] Condição ''Aceletra'' em todos os SubjStats\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [5.2] Condição ausente em %d SubjStats\n', length(cond_errada));
    erros{end+1} = sprintf('Condição ausente: %d SubjStats', length(cond_errada));
end

% 5.3 NaN nos betas
total = total + 1;
beta_nan = 0;
for i = 1:length(SubjStats)
    T_i = SubjStats(i).table();
    beta_nan = beta_nan + sum(isnan(T_i.beta));
end
if beta_nan == 0
    fprintf('  ✔ [5.3] NaN nos betas: 0\n');
    ok_count = ok_count + 1;
else
    fprintf('  ✗ [5.3] NaN nos betas: %d\n', beta_nan);
    erros{end+1} = sprintf('NaN betas = %d', beta_nan);
end

% =========================================================================
%% RELATÓRIO FINAL
% =========================================================================
fprintf('\n╔══════════════════════════════════════════════════════╗\n');
fprintf('║                  RELATÓRIO FINAL                    ║\n');
fprintf('╠══════════════════════════════════════════════════════╣\n');
fprintf('║  Verificações OK:     %2d / %2d                        ║\n', ok_count, total);
fprintf('║  Erros críticos:      %2d                             ║\n', length(erros));
fprintf('║  Avisos:              %2d                             ║\n', length(avisos));
fprintf('╚══════════════════════════════════════════════════════╝\n');

if ~isempty(erros)
    fprintf('\n🔴 ERROS CRÍTICOS:\n');
    for i = 1:length(erros)
        fprintf('  [%d] %s\n', i, erros{i});
    end
end

if ~isempty(avisos)
    fprintf('\n🟡 AVISOS:\n');
    for i = 1:length(avisos)
        fprintf('  [%d] %s\n', i, avisos{i});
    end
end

if isempty(erros)
    fprintf('\n✅ Pipeline aprovado — dados prontos para análise.\n');
else
    fprintf('\n❌ Pipeline com erros — revisar antes de continuar.\n');
end