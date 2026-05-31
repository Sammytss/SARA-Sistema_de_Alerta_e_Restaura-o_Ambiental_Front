import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';

/// Tela de educação ambiental pública do SARA APP.
/// Conteúdo educativo sobre restauração ambiental, sem dados sensíveis.
class EnvironmentalEducationScreen extends StatelessWidget {
  const EnvironmentalEducationScreen({super.key});

  static const List<_EducationTopic> _topics = [
    _EducationTopic(
      icon: Icons.forest_rounded,
      color: AppColors.statusRecuperacao,
      title: 'O que é Restauração Ambiental?',
      summary: 'Processo de assistir na recuperação de um ecossistema degradado, danificado ou destruído.',
      body: 'A restauração ambiental é o processo de assistir na recuperação de um ecossistema que foi degradado, danificado ou destruído. Ela envolve ações como plantio de espécies nativas, controle de espécies invasoras, proteção do solo e manejo da água. O objetivo é reestabelecer a estrutura, função e dinâmica do ecossistema original.',
    ),
    _EducationTopic(
      icon: Icons.assignment_turned_in_rounded,
      color: AppColors.accent,
      title: 'PRAD — Plano de Recuperação',
      summary: 'Instrumento técnico legal que orienta ações de restauração com metas e cronogramas definidos.',
      body: 'O Plano de Recuperação de Área Degradada (PRAD) é elaborado por profissional habilitado e aprovado pelo órgão ambiental competente. Ele deve conter: diagnóstico da área, metodologia de recuperação, espécies a plantar, cronograma de atividades, indicadores de monitoramento e responsável técnico.',
    ),
    _EducationTopic(
      icon: Icons.grass_rounded,
      color: AppColors.primaryLight,
      title: 'Espécies Nativas do Cerrado',
      summary: 'O Cerrado possui mais de 12.000 espécies de plantas, muitas com papel fundamental na restauração.',
      body: 'O Cerrado é um dos biomas mais biodiversos do planeta. Espécies como o Pequi (Caryocar brasiliense), o Buriti (Mauritia flexuosa), o Jatobá (Hymenaea courbaril) e o Ipê-amarelo (Tabebuia aurea) são fundamentais para a restauração ambiental no Tocantins, pois atraem fauna, fixam carbono e protegem o solo.',
    ),
    _EducationTopic(
      icon: Icons.monitor_heart_rounded,
      color: AppColors.secondary,
      title: 'Como é feito o Monitoramento?',
      summary: 'Vistorias de campo com checklist técnico, fotos georreferenciadas e análise de indicadores.',
      body: 'O monitoramento é realizado por técnicos habilitados que visitam as áreas periodicamente. Durante a vistoria, são avaliados: taxa de sobrevivência das mudas plantadas, cobertura vegetal, presença de espécies invasoras, erosão do solo, qualidade da água e fauna associada. Os dados são registrados digitalmente via aplicativo móvel.',
    ),
    _EducationTopic(
      icon: Icons.warning_amber_rounded,
      color: AppColors.error,
      title: 'Impactos do Desmatamento',
      summary: 'O desmatamento causa erosão, perda de biodiversidade, alteração do regime hídrico e aquecimento local.',
      body: 'No Tocantins, o desmatamento ilegal é uma das principais ameaças ao Cerrado. Suas consequências incluem: erosão e assoreamento de rios, desaparecimento de nascentes, perda de espécies endêmicas, redução da polinização agrícola, aumento da temperatura local e contribuição para as mudanças climáticas globais.',
    ),
    _EducationTopic(
      icon: Icons.report_rounded,
      color: AppColors.roleAuditor,
      title: 'Como Denunciar Irregularidades?',
      summary: 'Denúncias podem ser feitas ao NATURATINS, IBAMA ou pelo aplicativo de ouvidoria do governo.',
      body: 'Suspeitas de desmatamento ilegal, queimadas não autorizadas ou descumprimento de PRAD podem ser denunciadas: via telefone 0800 061 7800 (NATURATINS), pelo portal do IBAMA, pelo aplicativo "Olho Verde" do Ministério do Meio Ambiente, ou presencialmente nas delegacias do meio ambiente. Denúncias anônimas são aceitas.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educação Ambiental'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Banner ───────────────────────────────────────────
          _buildBanner(context),

          // ── Lista de tópicos ─────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              itemCount: _topics.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingSm),
              itemBuilder: (context, index) {
                return _buildTopicCard(context, _topics[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.08),
      child: Row(
        children: [
          Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aprenda sobre restauração ambiental e conservação do Cerrado',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, _EducationTopic topic) {
    return _ExpandableTopicCard(topic: topic);
  }
}

class _ExpandableTopicCard extends StatefulWidget {
  final _EducationTopic topic;

  const _ExpandableTopicCard({required this.topic});

  @override
  State<_ExpandableTopicCard> createState() => _ExpandableTopicCardState();
}

class _ExpandableTopicCardState extends State<_ExpandableTopicCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topic = widget.topic;

    return SaraCard(
      onTap: _toggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: topic.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(topic.icon, size: 22, color: topic.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic.summary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
              ),
            ],
          ),

          // Conteúdo expandível
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  topic.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationTopic {
  final IconData icon;
  final Color color;
  final String title;
  final String summary;
  final String body;

  const _EducationTopic({
    required this.icon,
    required this.color,
    required this.title,
    required this.summary,
    required this.body,
  });
}
