import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../data/models/area_monitorada.dart';
import '../areas_provider.dart';

/// Corpo da lista de áreas (sem Scaffold) — usado pelas home screens
/// dentro do ShellRoute. Para uso standalone, veja AreasListScreen.
class AreasListBody extends ConsumerStatefulWidget {
  const AreasListBody({super.key});

  @override
  ConsumerState<AreasListBody> createState() => _AreasListBodyState();
}

class _AreasListBodyState extends ConsumerState<AreasListBody> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(areasDoUsuarioProvider);

    return areasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Erro ao carregar áreas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(areasDoUsuarioProvider),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (areas) {
        if (areas.isEmpty) return _buildEmpty(context);
        final filtradas = _busca.isEmpty
            ? areas
            : areas
                .where((a) =>
                    a.nome.toLowerCase().contains(_busca.toLowerCase()) ||
                    a.municipio.toLowerCase().contains(_busca.toLowerCase()))
                .toList();
        return Column(
          children: [
            _buildSearch(),
            _buildCount(context, filtradas.length),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(areasDoUsuarioProvider),
                child: filtradas.isEmpty
                    ? ListView(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                'Nenhuma área encontrada para "$_busca"',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        itemCount: filtradas.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingSm),
                        itemBuilder: (_, i) => _buildAreaCard(context, filtradas[i]),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd, AppTheme.spacingSm, AppTheme.spacingMd, 0),
      child: TextField(
        onChanged: (v) => setState(() => _busca = v),
        decoration: InputDecoration(
          hintText: 'Buscar área ou município...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _busca.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => setState(() => _busca = ''),
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCount(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'área' : 'áreas'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard(BuildContext context, AreaMonitorada area) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = switch (area.status) {
      AreaStatus.regular => AppColors.statusRecuperacao,
      AreaStatus.atencao => AppColors.statusAtencao,
      AreaStatus.critica => AppColors.statusCritica,
    };

    return SaraCard(
      onTap: () => context.push('/area/${area.id}'),
      border: Border(left: BorderSide(color: statusColor, width: 4)),
      borderRadius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.nome,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text(
                          area.municipio,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  area.status.displayName,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${area.percentualRegeneracao.toStringAsFixed(1)}% regeneração',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: area.percentualRegeneracao / 100,
                        minHeight: 5,
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Icon(Icons.photo_camera_outlined, size: 14,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                  const SizedBox(width: 3),
                  Text(
                    '${area.totalEvidencias}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape_outlined, size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Nenhuma área atribuída',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Entre em contato com o gestor',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
