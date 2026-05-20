% =========================================================================
% conectividade_funcional.m
%
% PURPOSE  : Compute inter-regional functional connectivity between left
%            frontal and left temporal ROIs using autoregressive
%            correlation (ar_corr) applied to fNIRS hemodynamic signals.
%            Fisher-z transformed Pearson correlations are exported for
%            subsequent LMM analysis in Python.
%
% INPUTS   : hb — preprocessed nirs.core.Data array (140 sessions)
%                 produced by pre_processamento.m
%
% OUTPUTS  : connstats_completo.xlsx — long-format table with R, Z, p, q
%                                      for every channel pair × session
%            connstats_completo.mat  — same data in MATLAB format
%
% METHOD   : nirs.modules.Connectivity with ar_corr (order = 4×Fs),
%            divide_events=true (connectivity estimated within each block),
%            min_event_duration=10 s, AddShortSepRegressors=1.
%            60 inter-ROI pairs per session (6 frontal × 10 temporal).
%
% REFERENCES: Santosa et al. (2018) NIRS Toolbox.
% AUTHOR   : Lucas Gemal (lucasgemal@gmail.com) — IDOR / UFRJ
% =========================================================================

%% =========================================================================
%% CONECTIVIDADE FUNCIONAL — ROI Frontal × Temporal
%% Projeto SESI — Pipeline Completo
%% =========================================================================

%% PARTE 1 — CÁLCULO DA CONECTIVIDADE
fprintf('╔══════════════════════════════════════════════════════╗\n');
fprintf('║         CONECTIVIDADE FUNCIONAL — SESI fNIRS        ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n\n');

%% 1.1 Calcula ConnStats
j_conn                    = nirs.modules.Connectivity();
j_conn.divide_events      = true;        % estimate connectivity within each block separately
j_conn.min_event_duration = 10;          % minimum block length (s) to include in analysis
j_conn.AddShortSepRegressors = 1;        % regress out scalp signal via short-separation channels
j_conn.corrfcn = @(data) nirs.sFC.ar_corr(data, '4xFs', true);  % AR model order = 4×Fs = 16
ConnStats = j_conn.run(hb);
fprintf('ConnStats gerado: %d sessões\n', length(ConnStats));

%% EXPORTAÇÃO CONNSTATS → TABELA COMPLETA
%% Projeto SESI — Conectividade fNIRS
%% Pré-requisito: ConnStats já calculado

fprintf('╔══════════════════════════════════════════════════════╗\n');
fprintf('║         EXPORTAÇÃO CONNSTATS — SESI fNIRS           ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n\n');

fprintf('ConnStats disponível: %d sessões\n', length(ConnStats));

%% Pré-computa pares únicos (triângulo superior)
link    = ConnStats(1).probe.link;
n_ch    = height(link);

pares = [];
for i = 1:n_ch
    for j = i+1:n_ch
        pares(end+1,:) = [i,j];
    end
end
n_pares = size(pares,1);
n       = length(ConnStats);

fprintf('Canais totais:    %d\n', n_ch);
fprintf('Pares únicos:     %d\n', n_pares);
fprintf('Sessões:          %d\n', n);
fprintf('Linhas esperadas: %d\n\n', n_pares * n);

%% Loop principal
all_rows = cell(n,1);

for s = 1:n

    subj = ConnStats(s).demographics('subject');
    exp  = ConnStats(s).demographics('experiment');
    grp  = ConnStats(s).demographics('group');
    snum = 0;
    if ~strcmp(exp,'calibracao')
        snum = str2double(exp(end-1:end));
    end

    if isempty(ConnStats(s).R)
        warning('R vazio: %s %s — pulando', subj, exp);
        continue
    end

    R = ConnStats(s).R;
    Z = ConnStats(s).Z;
    P = ConnStats(s).p;
    Q = ConnStats(s).q;

    np        = n_pares;
    src_orig  = zeros(np,1);  det_orig  = zeros(np,1);
    src_dest  = zeros(np,1);  det_dest  = zeros(np,1);
    type_orig = cell(np,1);   type_dest = cell(np,1);
    r_val     = zeros(np,1);  z_val     = zeros(np,1);
    p_val     = zeros(np,1);  q_val     = zeros(np,1);

    for k = 1:np
        ii = pares(k,1);  jj = pares(k,2);
        src_orig(k)  = link.source(ii);
        det_orig(k)  = link.detector(ii);
        type_orig{k} = link.type{ii};
        src_dest(k)  = link.source(jj);
        det_dest(k)  = link.detector(jj);
        type_dest{k} = link.type{jj};
        r_val(k)     = R(ii,jj);
        z_val(k)     = Z(ii,jj);
        p_val(k)     = P(ii,jj);
        q_val(k)     = Q(ii,jj);
    end

    T_s = table(src_orig, det_orig, type_orig, ...
                src_dest, det_dest, type_dest, ...
                r_val, z_val, p_val, q_val, ...
                'VariableNames', ...
                {'SourceOrigin','DetectorOrigin','TypeOrigin', ...
                 'SourceDest',  'DetectorDest',  'TypeDest', ...
                 'R','Z','p','q'});

    T_s.subject        = repmat({subj}, np, 1);
    T_s.experiment     = repmat({exp},  np, 1);
    T_s.group          = repmat({grp},  np, 1);
    T_s.session        = repmat(snum,   np, 1);
    T_s.channel_origin = strcat('S',string(src_orig),'-D',string(det_orig));
    T_s.channel_dest   = strcat('S',string(src_dest),'-D',string(det_dest));

    all_rows{s} = T_s;

    if mod(s,20)==0 || s==n
        fprintf('  %d/%d | %s | %s\n', s, n, subj, exp);
    end
end

%% Concatena
fprintf('\nConcatenando...\n');
all_rows    = all_rows(~cellfun(@isempty, all_rows));
T_conn_full = vertcat(all_rows{:});

%% Verificação
fprintf('\n=== VERIFICAÇÃO ===\n');
fprintf('Total linhas:  %d\n', height(T_conn_full));
fprintf('Colunas:       %d\n', width(T_conn_full));
fprintf('Sujeitos:      %d\n', length(unique(T_conn_full.subject)));
fprintf('Sessões:       %d\n', length(unique(T_conn_full.experiment)));
fprintf('Tipos únicos:  '); disp(unique(T_conn_full.TypeOrigin)')

%% Exporta
fprintf('\nExportando...\n');
writetable(T_conn_full, 'connstats_completo.xlsx');
fprintf('✔ connstats_completo.xlsx\n');

save('connstats_completo.mat', 'T_conn_full', '-v7.3');
fprintf('✔ connstats_completo.mat\n');

fprintf('\n╔══════════════════════════════════════════════════════╗\n');
fprintf('║                EXPORTAÇÃO CONCLUÍDA                 ║\n');
fprintf('╠══════════════════════════════════════════════════════╣\n');
fprintf('║  Sessões exportadas: %3d                            ║\n', length(all_rows));
fprintf('║  Total linhas:  %6d                             ║\n', height(T_conn_full));
fprintf('╚══════════════════════════════════════════════════════╝\n');