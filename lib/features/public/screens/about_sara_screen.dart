import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';

/// Tela "Sobre o SARA" — informações institucionais públicas.
class AboutSaraScreen extends StatelessWidget {
  const AboutSaraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeroHeader(context),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(
                  context,
                  icon: Icons.eco_rounded,
                  iconColor: AppColors.primary,
                  title: 'O que é o SARA?',
                  body:
                      'O Sistema de Acompanhamento da Restauração Ambiental (SARA) é uma plataforma digital desenvolvida para monitorar e promover a recuperação de áreas degradadas no Estado do Tocantins, integrando dados de campo, laudos técnicos e indicadores de evolução em tempo real.',
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildInfoCard(
                  context,
                  icon: Icons.assignment_rounded,
                  iconColor: AppColors.accent,
                  title: 'O que é o PRAD?',
                  body:
                      'O Plano de Recuperação de Área Degradada (PRAD) é o instrumento técnico legal que orienta as ações de restauração ambiental. Ele define metas, cronogramas, espécies a plantar e indicadores de sucesso para cada área monitorada.',
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildInfoCard(
                  context,
                  icon: Icons.account_balance_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Quem é a NATURATINS?',
                  body:
                      'O Instituto Natureza do Tocantins (NATURATINS) é o órgão estadual responsável pelo controle, proteção, preservação e conservação do meio ambiente no Estado do Tocantins. É o gestor do sistema SARA.',
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildInfoCard(
                  context,
                  icon: Icons.monitor_heart_rounded,
                  iconColor: AppColors.primaryLight,
                  title: 'Como funciona o monitoramento?',
                  body:
                      'Técnicos de campo realizam vistorias periódicas nas áreas cadastradas, registrando fotos, checklist ambiental e dados de GPS. Os dados são sincronizados com o sistema e analisados para calcular o percentual de recuperação de cada área.',
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildInfoCard(
                  context,
                  icon: Icons.shield_rounded,
                  iconColor: AppColors.success,
                  title: 'Privacidade dos dados',
                  body:
                      'O SARA protege informações sensíveis dos produtores rurais. O acesso público exibe apenas dados agregados por município, sem revelar a identidade dos proprietários, coordenadas exatas ou informações particulares das propriedades.',
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildContactCard(context),
                const SizedBox(height: AppTheme.spacingXl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkHeroGradient : AppColors.heroGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sobre o SARA',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Sistema de Acompanhamento da Restauração Ambiental',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text(
          'Sobre o SARA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SaraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return SaraCard(
      gradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_support_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Contato',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactRow(Icons.language_rounded, 'naturatins.to.gov.br'),
          const SizedBox(height: 6),
          _buildContactRow(Icons.email_outlined, 'sara@naturatins.to.gov.br'),
          const SizedBox(height: 6),
          _buildContactRow(Icons.location_city_rounded, 'Palmas — Tocantins — Brasil'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
