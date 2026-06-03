%% HRF — Block Average (equivalente ao ERP)
%% Projeto SESI

%% Parâmetros
t_pre  = 5;    % segundos antes do onset
t_post = 30;   % segundos após o onset

%% Calcula o block average
jobs_ba = nirs.modules.BlockAverage();
jobs_ba.preBaseline  = t_pre;
jobs_ba.postBaseline = t_post;
BlockAvg = jobs_ba.run(hb);

fprintf('BlockAverage gerado: %d sessões\n', length(BlockAvg));

%% Visualiza HRF canônica — média de todos os sujeitos
% Escolhe um canal frontal de interesse (ex: S2-D3)
canal_interesse = 'S2-D3';
link = BlockAvg(1).probe.link;

idx_hbo = find(link.source == 2 & link.detector == 3 & ...
               strcmp(link.type, 'hbo'));
idx_hbr = find(link.source == 2 & link.detector == 3 & ...
               strcmp(link.type, 'hbr'));

%% Agrega por grupo
figure('Position',[100 100 1200 500],'Color','white');

grupos    = {'acelerado','nao_acelerado'};
cores_hbo = {'r','b'};
cores_hbr = {'#FF9999','#9999FF'};
labels    = {'Acelerado','Não acelerado'};

for g = 1:2
    % Coleta HRF de todos os sujeitos do grupo
    hrf_hbo_grupo = [];
    hrf_hbr_grupo = [];

    for i = 1:length(BlockAvg)
        grp = BlockAvg(i).demographics('group');
        if ~strcmp(grp, grupos{g}), continue; end
        if isempty(BlockAvg(i).data),  continue; end

        hrf_hbo_grupo = [hrf_hbo_grupo, BlockAvg(i).data(:, idx_hbo)];
        hrf_hbr_grupo = [hrf_hbr_grupo, BlockAvg(i).data(:, idx_hbr)];
    end

    t = BlockAvg(1).time;

    % Média e EP
    hbo_mean = mean(hrf_hbo_grupo, 2);
    hbo_ep   = std(hrf_hbo_grupo, 0, 2) / sqrt(size(hrf_hbo_grupo, 2));
    hbr_mean = mean(hrf_hbr_grupo, 2);
    hbr_ep   = std(hrf_hbr_grupo, 0, 2) / sqrt(size(hrf_hbr_grupo, 2));

    subplot(1,2,g);
    hold on;

    % HbO
    fill([t; flipud(t)], [hbo_mean+hbo_ep; flipud(hbo_mean-hbo_ep)], ...
         'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(t, hbo_mean, 'r-', 'LineWidth', 2.5, 'DisplayName', 'HbO_2');

    % HbR
    fill([t; flipud(t)], [hbr_mean+hbr_ep; flipud(hbr_mean-hbr_ep)], ...
         'b', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(t, hbr_mean, 'b-', 'LineWidth', 2.5, 'DisplayName', 'HHb');

    % Linha de onset
    xline(0, '--k', 'Onset', 'LabelVerticalAlignment', 'bottom', 'Alpha', 0.6);
    yline(0, '-k',  'LineWidth', 0.5, 'Alpha', 0.3);

    xlabel('Tempo relativo ao onset (s)', 'FontSize', 11);
    ylabel('Concentração (μM)',           'FontSize', 11);
    title(sprintf('HRF — %s\nCanal %s', labels{g}, canal_interesse), ...
          'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'northeast', 'Box', 'off');
    grid on;
    hold off;
end

sgtitle('Hemodynamic Response Function (HRF) — Resposta Canônica', ...
    'FontSize', 14, 'FontWeight', 'bold');

exportgraphics(gcf, 'hrf_canonico.png', 'Resolution', 300);
fprintf('Figura salva: hrf_canonico.png\n');