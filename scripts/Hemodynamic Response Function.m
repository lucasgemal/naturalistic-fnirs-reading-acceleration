%% =========================================================================
%% HRF — Hemodynamic Response Function
%% Projeto SESI — fNIRS
%% =========================================================================

fprintf('╔══════════════════════════════════════════════════════╗\n');
fprintf('║        HRF — Hemodynamic Response Function          ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n\n');

%% Parâmetros
t_pre  = 10;
t_post = 40;
Fs     = 4;
n_pre   = round(t_pre  * Fs);
n_post  = round(t_post * Fs);
n_total = n_pre + n_post + 1;
t_eixo  = linspace(-t_pre, t_post, n_total);
grupos  = {'acelerado','nao_acelerado'};
labels  = {'Acelerado','Não acelerado'};

%% Diagnóstico: duração dos blocos
dur_media = [];
for i = 1:length(hb)
    if isempty(hb(i).stimulus.values), continue; end
    dur_media = [dur_media; hb(i).stimulus.values{1}.dur];
end
fprintf('Duração dos blocos:\n');
fprintf('  Média:  %.1fs (±%.1fs)\n', mean(dur_media), std(dur_media));
fprintf('  Mínima: %.1fs\n', min(dur_media));
fprintf('  Máxima: %.1fs\n\n', max(dur_media));

%% Define ROIs
canais_frontal  = [1,1; 2,1; 2,3; 1,2; 3,3; 3,1];
canais_temporal = [8,7; 8,4; 7,7; 7,4; 7,6; 6,5; 6,4; 5,5; 5,6; 5,4];

link = hb(1).probe.link;

idx_frontal_hbo  = get_roi_idx(link, canais_frontal,  'hbo');
idx_frontal_hbr  = get_roi_idx(link, canais_frontal,  'hbr');
idx_temporal_hbo = get_roi_idx(link, canais_temporal, 'hbo');
idx_temporal_hbr = get_roi_idx(link, canais_temporal, 'hbr');

fprintf('ROI frontal:  hbo=%d | hbr=%d\n', length(idx_frontal_hbo),  length(idx_frontal_hbr));
fprintf('ROI temporal: hbo=%d | hbr=%d\n\n', length(idx_temporal_hbo), length(idx_temporal_hbr));

%% =========================================================================
%% FIGURA 1 — HRF Canônica ROI Frontal
%% =========================================================================
fprintf('Extraindo epochs — ROI Frontal...\n');
epochs_frontal = struct();
for g = 1:2
    [hbo, hbr] = extrair_epochs(hb, grupos(g), ...
        idx_frontal_hbo, idx_frontal_hbr, n_pre, n_post, true);
    epochs_frontal.(grupos{g}).hbo = hbo;
    epochs_frontal.(grupos{g}).hbr = hbr;
    fprintf('  %s: %d epochs\n', grupos{g}, size(hbo,2));
end

figure('Position',[100 100 1200 500],'Color','white');
for g = 1:2
    ax = subplot(1,2,g);
    plotar_hrf(ax, t_eixo, ...
        epochs_frontal.(grupos{g}).hbo, ...
        epochs_frontal.(grupos{g}).hbr, ...
        sprintf('%s | ROI Frontal (6 canais)', labels{g}), ...
        t_pre, t_post);
end
sgtitle('HRF Canônica — ROI Frontal','FontSize',14,'FontWeight','bold');
exportgraphics(gcf,'hrf_frontal_canonico.png','Resolution',300);
fprintf('✔ hrf_frontal_canonico.png\n\n');

%% =========================================================================
%% FIGURA 2 — HRF Canônica ROI Temporal
%% =========================================================================
fprintf('Extraindo epochs — ROI Temporal...\n');
epochs_temporal = struct();
for g = 1:2
    [hbo, hbr] = extrair_epochs(hb, grupos(g), ...
        idx_temporal_hbo, idx_temporal_hbr, n_pre, n_post, true);
    epochs_temporal.(grupos{g}).hbo = hbo;
    epochs_temporal.(grupos{g}).hbr = hbr;
    fprintf('  %s: %d epochs\n', grupos{g}, size(hbo,2));
end

figure('Position',[100 100 1200 500],'Color','white');
for g = 1:2
    ax = subplot(1,2,g);
    plotar_hrf(ax, t_eixo, ...
        epochs_temporal.(grupos{g}).hbo, ...
        epochs_temporal.(grupos{g}).hbr, ...
        sprintf('%s | ROI Temporal (10 canais)', labels{g}), ...
        t_pre, t_post);
end
sgtitle('HRF Canônica — ROI Temporal','FontSize',14,'FontWeight','bold');
exportgraphics(gcf,'hrf_temporal_canonico.png','Resolution',300);
fprintf('✔ hrf_temporal_canonico.png\n\n');

%% =========================================================================
%% FIGURA 3 — HRF Longitudinal
%% =========================================================================
fprintf('Extraindo epochs — evolução longitudinal...\n');

sessoes_plot  = {'calibracao','ac_01','ac_03','ac_05','ac_07','ac_09'};
labels_sessao = {'Baseline','S1','S3','S5','S7','S9'};
rois_plot     = {'frontal','temporal'};
idx_hbo_rois  = {idx_frontal_hbo, idx_temporal_hbo};
idx_hbr_rois  = {idx_frontal_hbr, idx_temporal_hbr};
cmap          = parula(length(sessoes_plot));

for roi_idx = 1:2
    figure('Position',[100 100 1600 400],'Color','white');

    for s = 1:length(sessoes_plot)
        hbo_sess = [];
        for i = 1:length(hb)
            if ~strcmp(hb(i).demographics('experiment'), sessoes_plot{s}), continue; end
            if isempty(hb(i).stimulus.values), continue; end
            onsets    = hb(i).stimulus.values{1}.onset;
            sinal_hbo = mean(hb(i).data(:, idx_hbo_rois{roi_idx}), 2);
            t_sinal   = hb(i).time;
            for b = 1:length(onsets)
                [~, idx_onset] = min(abs(t_sinal - onsets(b)));
                idx_inicio = idx_onset - n_pre;
                idx_fim    = idx_onset + n_post;
                if idx_inicio < 1 || idx_fim > length(sinal_hbo), continue; end
                ep_hbo = sinal_hbo(idx_inicio:idx_fim) - ...
                         mean(sinal_hbo(idx_inicio:idx_onset-1));
                hbo_sess = [hbo_sess, ep_hbo];
            end
        end

        ax = subplot(1, length(sessoes_plot), s);
        hold(ax,'on');
        if ~isempty(hbo_sess)
            media = mean(hbo_sess,2);
            ep    = std(hbo_sess,0,2) / sqrt(size(hbo_sess,2));
            hf = fill(ax,[t_eixo fliplr(t_eixo)], ...
                 [media+ep; flipud(media-ep)]', ...
                 'r','FaceAlpha',0.15,'EdgeColor','none');
            hf.Annotation.LegendInformation.IconDisplayStyle = 'off';
            plot(ax, t_eixo, media,'-','Color',cmap(s,:),'LineWidth',2.5);
        end
        hx = xline(ax,0,'--k','Alpha',0.4);
        hy = yline(ax,0,'-k','LineWidth',0.5,'Alpha',0.3);
        hx.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hy.Annotation.LegendInformation.IconDisplayStyle = 'off';
        title(ax, labels_sessao{s},'FontSize',10,'FontWeight','bold');
        xlabel(ax,'Tempo (s)','FontSize',9);
        if s==1
            ylabel(ax, sprintf('HbO (μM)\nROI %s', upper(rois_plot{roi_idx})),'FontSize',9);
        end
        xlim(ax,[-t_pre t_post]); grid(ax,'on'); hold(ax,'off');
    end

    sgtitle(sprintf('Evolução HRF — HbO | ROI %s', upper(rois_plot{roi_idx})), ...
        'FontSize',13,'FontWeight','bold');
    exportgraphics(gcf, sprintf('hrf_longitudinal_%s.png', rois_plot{roi_idx}),'Resolution',300);
    fprintf('✔ hrf_longitudinal_%s.png\n', rois_plot{roi_idx});
end

%% =========================================================================
%% FIGURA 4 — Painel completo 2×2
%% =========================================================================
rois_nomes = {'Frontal','Temporal'};
epochs_all = {epochs_frontal, epochs_temporal};

figure('Position',[100 100 1400 900],'Color','white');
for roi_idx = 1:2
    for g = 1:2
        ax = subplot(2,2,(roi_idx-1)*2+g);
        plotar_hrf(ax, t_eixo, ...
            epochs_all{roi_idx}.(grupos{g}).hbo, ...
            epochs_all{roi_idx}.(grupos{g}).hbr, ...
            sprintf('%s | ROI %s', labels{g}, rois_nomes{roi_idx}), ...
            t_pre, t_post);
    end
end
sgtitle('HRF — Comparação Grupos × ROIs','FontSize',14,'FontWeight','bold');
exportgraphics(gcf,'hrf_painel_completo.png','Resolution',300);
fprintf('✔ hrf_painel_completo.png\n');

%% Relatório final
fprintf('\n╔══════════════════════════════════════════════════════╗\n');
fprintf('║                  HRF CONCLUÍDA                      ║\n');
fprintf('╠══════════════════════════════════════════════════════╣\n');
fprintf('║  pre=%ds | post=%ds | Fs=%dHz                       ║\n', t_pre, t_post, Fs);
fprintf('║  Dur. blocos: %.1fs (±%.1fs)                        ║\n', mean(dur_media), std(dur_media));
fprintf('╚══════════════════════════════════════════════════════╝\n');

%% =========================================================================
%% FUNÇÕES LOCAIS — devem ficar no final do script
%% =========================================================================

function idx = get_roi_idx(link, canais, tipo)
    idx = [];
    for r = 1:size(canais,1)
        k = find(link.source   == canais(r,1) & ...
                 link.detector == canais(r,2) & ...
                 strcmp(link.type, tipo));
        if ~isempty(k), idx(end+1) = k; end
    end
end

function [hbo_all, hbr_all] = extrair_epochs(hb, grupos_filtro, ...
        idx_hbo, idx_hbr, n_pre, n_post, excluir_calibracao)
    hbo_all = [];
    hbr_all = [];
    for i = 1:length(hb)
        grp = hb(i).demographics('group');
        exp = hb(i).demographics('experiment');
        if ~isempty(grupos_filtro) && ~ismember(grp, grupos_filtro), continue; end
        if excluir_calibracao && strcmp(exp,'calibracao'), continue; end
        if isempty(hb(i).stimulus.values), continue; end
        onsets    = hb(i).stimulus.values{1}.onset;
        sinal_hbo = mean(hb(i).data(:, idx_hbo), 2);
        sinal_hbr = mean(hb(i).data(:, idx_hbr), 2);
        t_sinal   = hb(i).time;
        for b = 1:length(onsets)
            [~, idx_onset] = min(abs(t_sinal - onsets(b)));
            idx_inicio = idx_onset - n_pre;
            idx_fim    = idx_onset + n_post;
            if idx_inicio < 1 || idx_fim > length(sinal_hbo), continue; end
            ep_hbo = sinal_hbo(idx_inicio:idx_fim) - ...
                     mean(sinal_hbo(idx_inicio:idx_onset-1));
            ep_hbr = sinal_hbr(idx_inicio:idx_fim) - ...
                     mean(sinal_hbr(idx_inicio:idx_onset-1));
            hbo_all = [hbo_all, ep_hbo];
            hbr_all = [hbr_all, ep_hbr];
        end
    end
end

function [coupling, cor_txt] = checar_acoplamento(hbo_mean, hbr_mean, t_eixo)
    mask     = t_eixo > 0 & t_eixo < 20;
    pico_hbo = max(hbo_mean(mask));
    min_hbr  = min(hbr_mean(mask));
    dif      = pico_hbo - max(hbr_mean(mask));
    if pico_hbo > 0 && min_hbr < 0
        coupling = '✓ Canônico (HbO↑ HbR↓)';  cor_txt = [0 0.5 0];
    elseif pico_hbo > 0.5 && dif > 0
        coupling = '~ HbO dominante';           cor_txt = [0.8 0.5 0];
    elseif pico_hbo > 0
        coupling = '~ HbO positivo';            cor_txt = [0.8 0.5 0];
    else
        coupling = '✗ Não canônico';            cor_txt = [0.8 0 0];
    end
end

function plotar_hrf(ax, t_eixo, hbo_data, hbr_data, titulo, t_pre, t_post)
    hbo_mean = mean(hbo_data,2);
    hbo_ep   = std(hbo_data,0,2)  / sqrt(size(hbo_data,2));
    hbr_mean = mean(hbr_data,2);
    hbr_ep   = std(hbr_data,0,2)  / sqrt(size(hbr_data,2));
    [coupling, cor_txt] = checar_acoplamento(hbo_mean, hbr_mean, t_eixo);
    hold(ax,'on');
    h1 = fill(ax,[t_eixo fliplr(t_eixo)], ...
         [hbo_mean+hbo_ep; flipud(hbo_mean-hbo_ep)]', ...
         'r','FaceAlpha',0.15,'EdgeColor','none');
    h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
    plot(ax, t_eixo, hbo_mean,'r-','LineWidth',2.5,'DisplayName','HbO_2');
    h2 = fill(ax,[t_eixo fliplr(t_eixo)], ...
         [hbr_mean+hbr_ep; flipud(hbr_mean-hbr_ep)]', ...
         'b','FaceAlpha',0.15,'EdgeColor','none');
    h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
    plot(ax, t_eixo, hbr_mean,'b-','LineWidth',2.5,'DisplayName','HHb');
    hx = xline(ax,0,'--k','Onset','LabelVerticalAlignment','bottom','Alpha',0.6);
    hy = yline(ax,0,'-k','LineWidth',0.5,'Alpha',0.3);
    hx.Annotation.LegendInformation.IconDisplayStyle = 'off';
    hy.Annotation.LegendInformation.IconDisplayStyle = 'off';
    [pico_val, pico_idx] = max(hbo_mean(t_eixo > 0));
    t_pico = t_eixo(find(t_eixo > 0,1) + pico_idx - 1);
    plot(ax, t_pico, pico_val,'rv','MarkerSize',8,'MarkerFaceColor','r');
    text(ax, t_pico+0.5, pico_val, sprintf('%.1fs',t_pico),'FontSize',8,'Color','r');
    xlabel(ax,'Tempo relativo ao onset (s)','FontSize',11);
    ylabel(ax,'Concentração (μM)',          'FontSize',11);
    title(ax, sprintf('%s\nN=%d epochs | %s', titulo, size(hbo_data,2), coupling), ...
        'FontSize',11,'FontWeight','bold','Color',cor_txt);
    legend(ax,'Location','northeast','Box','off','FontSize',10);
    xlim(ax,[-t_pre t_post]); grid(ax,'on'); hold(ax,'off');
end