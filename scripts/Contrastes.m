n = length(GroupStats.conditions);  % = 20

%% Contraste 1 — Acelerado: ac_09 vs calibracao
c1 = zeros(1, n);
c1(9)  =  1;   % acelerado ac_09
c1(10) = -1;   % acelerado calibracao
result1 = GroupStats.ttest(c1);
result1.draw('tstat', [-5 5], 'q<0.05');
title('Acelerado: ac\_09 vs baseline');

%% Contraste 2 — Não acelerado: ac_09 vs calibracao
c2 = zeros(1, n);
c2(19) =  1;   % nao_acelerado ac_09
c2(20) = -1;   % nao_acelerado calibracao
result2 = GroupStats.ttest(c2);
result2.draw('tstat', [-5 5], 'q<0.05');
title('Não acelerado: ac\_09 vs baseline');

%% Contraste 3 — Interação grupo × tempo (contraste principal)
c3 = zeros(1, n);
c3(9)  =  1;   % acelerado ac_09
c3(10) = -1;   % acelerado calibracao
c3(19) = -1;   % nao_acelerado ac_09
c3(20) =  1;   % nao_acelerado calibracao
result3 = GroupStats.ttest(c3);
result3.draw('tstat', [-5 5], 'q<0.05');
title('Interação grupo × tempo vs baseline');

%% Trajetória completa — todas as sessões vs calibração
% índices: acelerado ac_01..09 = 1..9 | calibracao = 10
%          nao_acelerado ac_01..09 = 11..19 | calibracao = 20
sessoes_idx_acel    = 1:9;
sessoes_idx_naoacel = 11:19;
nomes_sessoes = {'ac\_01','ac\_02','ac\_03','ac\_04','ac\_05',...
                 'ac\_06','ac\_07','ac\_08','ac\_09'};

figure('Position', [100 100 1800 800]);
for s = 1:9
    c_s = zeros(1, n);
    c_s(sessoes_idx_acel(s))    =  1;   % acelerado ac_s
    c_s(10)                     = -1;   % acelerado calibracao
    c_s(sessoes_idx_naoacel(s)) = -1;   % nao_acelerado ac_s
    c_s(20)                     =  1;   % nao_acelerado calibracao

    subplot(2, 5, s);
    GroupStats.ttest(c_s).draw('tstat', [-5 5], 'q<0.05');
    title(nomes_sessoes{s}, 'FontSize', 8);
end
sgtitle('Interação grupo × tempo por sessão vs baseline');

%% Exporta tabelas
T1 = result1.table();
T2 = result2.table();
T3 = result3.table();
writetable(T1, 'resultado_acelerado_vs_baseline.xlsx');
writetable(T2, 'resultado_nao_acelerado_vs_baseline.xlsx');
writetable(T3, 'resultado_interacao_grupo_tempo.xlsx');
fprintf('Tabelas exportadas.\n');