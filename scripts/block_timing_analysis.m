%% EXTRAÇÃO DE TEMPOS DOS BLOCOS — versão corrigida
fprintf('╔══════════════════════════════════════════════════════╗\n');
fprintf('║        TEMPOS DOS BLOCOS — ANÁLISE DESCRITIVA       ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n\n');

NstimPerBlock = 5;

% Arrays separados — evita problema do cell2mat
v_subj    = {};
v_exp     = {};
v_grp     = {};
v_sessnum = [];
v_bloco   = [];
v_onset   = [];
v_dur     = [];
v_tpe     = [];
v_nestim  = [];

for i = 1:length(hb)

    subj = hb(i).demographics('subject');
    exp  = hb(i).demographics('experiment');
    grp  = hb(i).demographics('group');

    if strcmp(exp,'calibracao')
        sess_num = 0;
    else
        sess_num = str2double(exp(end-1:end));
    end

    if isempty(hb(i).stimulus.values), continue; end

    onsets = hb(i).stimulus.values{1}.onset;
    durs   = hb(i).stimulus.values{1}.dur;
    n_bl   = length(onsets);

    for b = 1:n_bl
        v_subj{end+1}  = subj;
        v_exp{end+1}   = exp;
        v_grp{end+1}   = grp;
        v_sessnum(end+1) = sess_num;
        v_bloco(end+1)   = b;
        v_onset(end+1)   = onsets(b);
        v_dur(end+1)     = durs(b);
        v_tpe(end+1)     = durs(b) / NstimPerBlock;
        v_nestim(end+1)  = NstimPerBlock;
    end
end

%% Monta tabela diretamente
T_blocos = table( ...
    v_subj(:), v_exp(:), v_grp(:), ...
    v_sessnum(:), v_bloco(:), v_onset(:), ...
    v_dur(:), v_tpe(:), v_nestim(:), ...
    'VariableNames', { ...
    'subject','experiment','group', ...
    'sessao_num','bloco','onset_s', ...
    'duracao_s','tempo_por_estimulo_s','n_estimulos'});

fprintf('Tabela de blocos: %d linhas × %d colunas\n', ...
    height(T_blocos), width(T_blocos));
disp(T_blocos(1:3,:))

%% Estatísticas descritivas por sujeito × sessão
fprintf('\nCalculando estatísticas descritivas...\n');

subjects_uniq = unique(T_blocos.subject);
exps_uniq     = unique(T_blocos.experiment);

v2_subj    = {};  v2_exp  = {};  v2_grp  = {};
v2_sessnum = [];  v2_nblocos = [];
v2_dur_med = [];  v2_dur_dp  = [];
v2_dur_min = [];  v2_dur_max = [];
v2_dur_med2= [];  v2_cv      = [];
v2_tpe_med = [];  v2_tpe_dp  = [];
v2_slope   = [];  v2_dur_tot = [];

for s = 1:length(subjects_uniq)
    subj = subjects_uniq{s};

    for e = 1:length(exps_uniq)
        exp = exps_uniq{e};

        mask = strcmp(T_blocos.subject, subj) & ...
               strcmp(T_blocos.experiment, exp);
        T_sub = T_blocos(mask,:);
        if height(T_sub) == 0, continue; end

        durs = T_sub.duracao_s;
        tpe  = T_sub.tempo_por_estimulo_s;

        % Tendência intra-sessão
        if height(T_sub) > 2
            x_bl = (1:height(T_sub))';
            p    = polyfit(x_bl, durs, 1);
            slope_intra = p(1);
        else
            slope_intra = NaN;
        end

        v2_subj{end+1}    = subj;
        v2_exp{end+1}     = exp;
        v2_grp{end+1}     = T_sub.group{1};
        v2_sessnum(end+1) = T_sub.sessao_num(1);
        v2_nblocos(end+1) = height(T_sub);
        v2_dur_med(end+1) = mean(durs);
        v2_dur_dp(end+1)  = std(durs);
        v2_dur_min(end+1) = min(durs);
        v2_dur_max(end+1) = max(durs);
        v2_dur_med2(end+1)= median(durs);
        v2_cv(end+1)      = std(durs)/mean(durs)*100;
        v2_tpe_med(end+1) = mean(tpe);
        v2_tpe_dp(end+1)  = std(tpe);
        v2_slope(end+1)   = slope_intra;
        v2_dur_tot(end+1) = sum(durs);
    end
end

T_desc = table( ...
    v2_subj(:), v2_exp(:), v2_grp(:), v2_sessnum(:), v2_nblocos(:), ...
    v2_dur_med(:), v2_dur_dp(:), v2_dur_min(:), v2_dur_max(:), ...
    v2_dur_med2(:), v2_cv(:), v2_tpe_med(:), v2_tpe_dp(:), ...
    v2_slope(:), v2_dur_tot(:), ...
    'VariableNames', { ...
    'subject','experiment','group','sessao_num','n_blocos', ...
    'duracao_media_s','duracao_dp_s', ...
    'duracao_min_s','duracao_max_s','duracao_mediana_s', ...
    'CV_pct','tempo_estimulo_medio_s','tempo_estimulo_dp_s', ...
    'slope_intra_sessao','duracao_total_sessao_s'});

fprintf('Tabela descritiva: %d linhas × %d colunas\n', ...
    height(T_desc), width(T_desc));

%% Resumo por grupo
fprintf('\n━━━ RESUMO POR GRUPO (excluindo calibracao) ━━━━━━━━━━\n');
T_sem_cal = T_desc(T_desc.sessao_num > 0, :);

for g = {'acelerado','nao_acelerado'}
    mask = strcmp(T_sem_cal.group, g{1});
    T_g  = T_sem_cal(mask,:);
    fprintf('\n[%s]\n', g{1});
    fprintf('  Duração média dos blocos:  %.1fs (±%.1fs)\n', ...
        mean(T_g.duracao_media_s), std(T_g.duracao_media_s));
    fprintf('  Tempo por estímulo:        %.1fs (±%.1fs)\n', ...
        mean(T_g.tempo_estimulo_medio_s), std(T_g.tempo_estimulo_medio_s));
    fprintf('  CV médio:                  %.1f%%\n', mean(T_g.CV_pct));
    fprintf('  Slope intra-sessão:        %.2fs/bloco (±%.2f)\n', ...
        mean(T_g.slope_intra_sessao,'omitnan'), ...
        std(T_g.slope_intra_sessao,'omitnan'));
end

%% Trajetória longitudinal
fprintf('\n━━━ TRAJETÓRIA LONGITUDINAL ━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('%-12s  %10s  %10s  %10s\n','Sessão','Acelerado','Não acel.','Diferença');
fprintf('%s\n', repmat('-',1,50));

for s = 0:9
    mask_a = strcmp(T_desc.group,'acelerado')     & T_desc.sessao_num==s;
    mask_n = strcmp(T_desc.group,'nao_acelerado') & T_desc.sessao_num==s;
    m_a = mean(T_desc.duracao_media_s(mask_a));
    m_n = mean(T_desc.duracao_media_s(mask_n));
    idx_exp = find(T_desc.sessao_num==s,1);
    exp_nome = T_desc.experiment{idx_exp};
    fprintf('%-12s  %8.1fs    %8.1fs    %+8.1fs\n', ...
        exp_nome, m_a, m_n, m_a-m_n);
end

%% Exporta
writetable(T_blocos, 'blocos_individuais.xlsx');
writetable(T_desc,   'blocos_descritivas.xlsx');
save('T_blocos.mat', 'T_blocos','T_desc','-v7.3');

fprintf('\n✔ blocos_individuais.xlsx  (%d linhas)\n', height(T_blocos));
fprintf('✔ blocos_descritivas.xlsx  (%d linhas)\n', height(T_desc));
fprintf('✔ T_blocos.mat\n');

%% Figura
figure('Position',[100 100 900 500],'Color','white');
hold on;
cores  = {'r','b'};
labels = {'Acelerado','Não acelerado'};
grupos = {'acelerado','nao_acelerado'};
x_vals = 0:9;
x_labs = {'Baseline','S1','S2','S3','S4','S5','S6','S7','S8','S9'};

for g = 1:2
    media = arrayfun(@(s) mean(T_desc.duracao_media_s( ...
        strcmp(T_desc.group,grupos{g}) & T_desc.sessao_num==s)), x_vals);
    ep    = arrayfun(@(s) std(T_desc.duracao_media_s( ...
        strcmp(T_desc.group,grupos{g}) & T_desc.sessao_num==s)) / ...
        max(1,sqrt(sum(strcmp(T_desc.group,grupos{g}) & ...
        T_desc.sessao_num==s))), x_vals);

    hf = fill([x_vals fliplr(x_vals)],[media+ep fliplr(media-ep)], ...
         cores{g},'FaceAlpha',0.15,'EdgeColor','none');
    hf.Annotation.LegendInformation.IconDisplayStyle = 'off';
    plot(x_vals, media,[cores{g} 'o-'],'LineWidth',2.5, ...
         'MarkerSize',7,'MarkerFaceColor',cores{g}, ...
         'MarkerEdgeColor','white','DisplayName',labels{g});
end

xline(0,'--k','Baseline','LabelVerticalAlignment','bottom','Alpha',0.5);
xticks(x_vals); xticklabels(x_labs);
xlabel('Sessão','FontSize',12);
ylabel('Duração média do bloco (s)','FontSize',12);
title({'Duração dos Blocos de Leitura ao Longo do Treinamento', ...
       'Média ± EP por grupo'},'FontSize',13,'FontWeight','bold');
legend('Location','best','Box','off','FontSize',11);
grid on; hold off;

exportgraphics(gcf,'blocos_trajetoria.png','Resolution',300);
fprintf('✔ blocos_trajetoria.png\n');