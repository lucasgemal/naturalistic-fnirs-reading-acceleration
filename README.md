# Neurobiological Foundations of Reading Acceleration: A Naturalistic fNIRS Brain Imaging Study

**Status:** Manuscrito em preparação

## Visão geral

Estudo fNIRS sobre os mecanismos neurais da aceleração da leitura em crianças do 3º e 4º ano do
Ensino Fundamental (8–9 anos) treinadas com o software ACELETRA®. Delineamento longitudinal
randomizado (10 sessões em 3 semanas), com fNIRS portátil (NIRSport2) em ambiente escolar naturalístico.

**Hipóteses principais:**
1. O treinamento com ACELETRA® acelera a automatização dos mecanismos neurais da leitura (menor HbO ao longo das sessões = ganho de eficiência neural).
2. O treinamento aumenta a conectividade funcional entre os córtices temporal e frontal esquerdos.

## Escopo deste repositório

Este repositório disponibiliza **exclusivamente o código-fonte** utilizado nas
análises de dados fNIRS deste estudo (MATLAB/NIRS Toolbox e Python/statsmodels).
Seu propósito é a **transparência metodológica**: permitir que qualquer leitor
audite a lógica de processamento, os modelos estatísticos e os parâmetros
utilizados na pesquisa.

Por decisão do autor, este repositório **não inclui**:
- Dados brutos, processados ou derivados (arquivos `.xlsx`, `.csv`, `.mat`, `.snirf`)
- Resultados numéricos ou figuras geradas pelas análises (`.png`)
- O manuscrito ou suas versões preliminares (`.docx`, `.pdf`)

Essa exclusão é **intencional** e não decorre de omissão ou de limitação técnica.
Os scripts aqui publicados não são executáveis de ponta a ponta sem os dados de
entrada correspondentes, que não são disponibilizados neste momento. Pesquisadores
interessados em detalhes metodológicos adicionais, dados anonimizados ou
colaboração podem entrar em contato diretamente com o autor.

## Como este repositório deve ser lido

Os scripts estão organizados por etapa do pipeline (pré-processamento, modelagem
estatística, eficiência neural, conectividade, análises por canal). Recomenda-se
a leitura na ordem descrita abaixo, acompanhando os comentários de
cabeçalho de cada arquivo, que documentam a lógica de cada etapa mesmo sem os
dados de entrada.

```
1. contagem_nova.m            # Eventos/blocos de estímulo
2. pre_processamento.m        # Pré-processamento fNIRS + GLM 1º nível (SubjStats)
3. MixedEffects.m             # GLM 2º nível (GroupStats)
4. Contrastes.m               # Contrastes sobre GroupStats
5. conectividade_funcional.m  # Conectividade funcional

6.  fnirs_neural_efficiency.ipynb    # Índice de eficiência neural
7.  lmm_neural_efficiency.ipynb      # LMM de NE por ROI
8.  individual_ne_regressions.ipynb  # Slopes individuais de NE
9.  beta_activation_lmm.ipynb        # LMM de ativação β
10. connectivity_lmm_raincloud.ipynb # LMM de conectividade
11. channel_lmm_anatomical.ipynb     # LMM canal a canal + FDR
12. corr_hbo_velmed.ipynb            # Correlações neural × comportamento
13. analise_velmed.ipynb / analise_acuracia.ipynb  # LMMs comportamentais
```

## Scripts (`scripts/`)

### MATLAB — pré-processamento e GLM (NIRS Toolbox)

| Script | Objetivo | Inputs esperados | Outputs produzidos |
|---|---|---|---|
| `contagem_nova.m` | Reconstrói os blocos de estímulo a partir dos triggers ACELETRA por participante (calibração = 4 blocos, treino = 7; 5 estímulos/bloco) | Dados fNIRS brutos + triggers | Eventos de estímulo por sessão |
| `pre_processamento.m` | Resample 4 Hz → TrimBaseline → OD → Beer-Lambert → HbT → passa-banda 0,01–0,10 Hz → filtro wavelet → GLM 1º nível (short-separation) | Dados fNIRS brutos com eventos | `SubjStats` |
| `MixedEffects.m` | GLM 2º nível: `beta ~ -1 + group:experiment + (1\|subject)` (robusto) | `SubjStats` | `GroupStats` |
| `conectividade_funcional.m` | Conectividade AR-correlation (4×Fs) inter-canais; Fisher-z | Dados pré-processados | R, Z, p, q em planilha Excel |
| `relatorio_geral.m` | Controle de qualidade: nº de sessões, Fs, cromóforos, canais, NaN, estímulos, demográficos | Dados pré-processados + `SubjStats` | Relatório no console |
| `Contrastes.m` | Contrastes do GLM 2º nível: (1) acelerado ac_09 vs calibração, (2) não-acelerado ac_09 vs calibração, (3) interação grupo × tempo | `GroupStats` | Figuras de t-stat por canal e tabelas de contraste (100 linhas: 25 canais × 4 cromóforos) |
| `block_timing_analysis.m` | Estatísticas de temporização dos blocos (onset, duração, tempo por estímulo, média/DP/CV%/slope intra-sessão) por sujeito × sessão | Objeto `hb` (dados pré-processados com estímulos) | Tabelas individuais e descritivas de blocos, `.mat` e figura de trajetória |
| `Hemodynamic Response Function.m` | Extrai e visualiza a HRF por ROI e grupo (−10 a +40 s, 4 Hz): HRF canônica, evolução longitudinal (baseline, S1, S3, S5, S7, S9), painel grupos × ROIs; verifica acoplamento HbO/HbR | Objeto `hb` | Figuras de HRF |
| `block_average.m` | Block average (`nirs.modules.BlockAverage`, −5 a +30 s); HRF de HbO e HbR do canal S2-D3 por grupo | Objeto `hb` | Figura de HRF canônica |

### Python — modelos estatísticos e visualizações (Jupyter)

| Notebook | Objetivo | Inputs esperados | Outputs produzidos |
|---|---|---|---|
| `fnirs_neural_efficiency.ipynb` | NE = (−z_TimeRm − z_β) / √2, com z_β por ROI | SubjStats exportado + dados comportamentais | Tabela de NE por sujeito × sessão × ROI |
| `lmm_neural_efficiency.ipynb` | LMM: `NE ~ group × sessao_num + TimeRm_baseline + (1\|subject)`, por ROI | Tabela de NE | Coeficientes do LMM |
| `individual_ne_regressions.ipynb` | OLS individual de NE; Fisher exact + t-test entre grupos | Tabela de NE | Slopes individuais |
| `beta_activation_lmm.ipynb` | LMM: `beta ~ group × sessao_num + roi + (1\|subject)` (ML) | β do GLM 1º nível | Coeficientes do LMM (por cromóforo) |
| `connectivity_lmm_raincloud.ipynb` | LMM: `conexao_inter ~ group × session + conn_baseline + (1\|subject)`; Mann-Whitney; raincloud | Tabela de conectividade | Coeficientes do LMM e figuras |
| `channel_lmm_anatomical.ipynb` | LMM canal a canal com FDR (BH); mapeamento anatômico 10-10 | β por canal e sessão | Tabela de LMM por canal |
| `corr_hbo_velmed.ipynb` | Spearman: slope de HbO × slope de TimeRm por canal FDR-significativo | Slopes de HbO e TimeRm | Correlações |
| `ne_mannwhitney_raincloud.ipynb` | Mann-Whitney U + raincloud de NE | Tabela de NE | Testes e figuras |
| `ne_trajectory_plot.ipynb` | Trajetória de NE (média ± EPM) por grupo e ROI | Tabela de NE | Figura |
| `lmm_roi_interaction.ipynb` | LMM de NE com interação grupo × sessão × ROI | Tabela de NE | Coeficientes do LMM |
| `analise_velmed.ipynb` | LMM comportamental de velocidade de leitura: `VELmed ~ session × grupo + (1\|SUBJID)` (REML) | `sessao_stats.xlsx` (VELmed, ms/char ≡ TimeRm) | Tabelas do LMM e gráfico por grupo/sessão |
| `analise_acuracia.ipynb` | LMM de acurácia (%) = ACERTOSnum / (ACERTOSnum + ERROSnum) × 100: `acuracia ~ session × grupo + (1\|subject)` (REML) | `sessao_stats.xlsx` (ACERTOSnum, ERROSnum) | Tabelas do LMM e gráfico por grupo/sessão |
| `Calculo_eficiencia.ipynb` | Rascunho inicial (versão canônica: `fnirs_neural_efficiency.ipynb`) | — | — |

## Ambiente de referência

Os scripts em Python foram desenvolvidos com Python 3.12 e a biblioteca
statsmodels (v. 0.14.6). Os scripts em MATLAB dependem do NIRS Toolbox
(https://github.com/huppertt/NIRS-Toolbox). Esta informação é fornecida como
referência de contexto, não como garantia de execução sem os dados originais.

## Parâmetros de aquisição fNIRS

| Parâmetro | Valor |
|---|---|
| Equipamento | NIRSport2 8-8 Core Unit (Brain Products) |
| Comprimentos de onda | 760 e 850 nm |
| Taxa de amostragem | 4,36 Hz (reamostrada para 4 Hz) |
| Cromóforos | HbO, HbR, HbT, StO2 |
| ROI frontal esquerdo | S1-D1, S2-D1, S2-D3, S1-D2, S3-D3, S4-D1, S3-D1 (7 canais) |
| ROI temporal esquerdo | S8-D7, S8-D4, S7-D7, S7-D4, S7-D6, S6-D4, S5-D5, S5-D6, S5-D4 (9 canais) |

## Citação

> Gemal L. (em preparação). *Neurobiological Foundations of Reading Acceleration: A Naturalistic fNIRS Brain Imaging Study.*

## Autor

Lucas Gemal — IDOR / UFRJ
lucasgemal@gmail.com
