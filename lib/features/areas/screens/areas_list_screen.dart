import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../core/widgets/sara_loading.dart';
import '../../../data/models/area_monitorada.dart';
import '../areas_provider.dart';

/// Tela "Minhas Áreas" — lista de áreas filtrada por perfil.
/// Técnico: áreas atribuídas. Produtor: propriedades. Gestor: todas.
class AreasListScreen extends ConsumerStatefulWidget {
  const AreasListScreen({super.key});

  @override
  ConsumerState<AreasListScreen> createState() => _AreasListScreenState();
}

class _AreasListScreenState extends ConsumerState<AreasListScreen> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(areasDoUsuarioProvider);
    final pendenciasAsync = ref.watch(pendenciasCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Áreas'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Badge de pendências de sync
          pendenciasAsync.when(
            data: (count) => count > 0
                ? Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync_rounded),
                        onPressed: () => context.push('/sync'),
                        tooltip: 'Pendências de envio',
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.sync_rounded),
                    onPressed: () => context.push('/sync'),
                    tooltip: 'Sincronização',
                  ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: areasAsync.when(
        loading: () => const SaraLoading(message: 'Carregando áreas...'),
        error: (e, _) => _buildError(context, e.toString()),
        data: (areas) => _buildList(context, areas),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AreaMonitorada> areas) {
    if (areas.isEmpty) {
      return _buildEmpty(context);
    }

    final filtradas = _busca.isEmpty
        ? areas
        : areas
            .where((a) =>
                a.nome.toLowerCase().contains(_busca.toLowerCase()) ||
                a.municipio.toLowerCase().contains(_busca.toLowerCase()))
            .toList();

    return Column(
      children: [
        // ── Barra de busca ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            0,
          ),
          child: TextField(
            onChanged: (v) => setState(() => _busca = v),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou município...',
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
        ),

        // ── Contagem ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Text(
                '${filtradas.length} ${filtradas.length == 1 ? 'área' : 'áreas'}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // ── Lista ─────────────────────────────────────────────
        Expanded(
          child: filtradas.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma área encontrada para "$_busca"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(areasDoUsuarioProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: filtradas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppTheme.spacingSm),
                    itemBuilder: (context, index) =>
                        _buildAreaCard(context, filtradas[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAreaCard(BuildContext context, AreaMonitorada area) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(area.status);

    return SaraCard(
      onTap: () => context.go('/area/${area.id}'),
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
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          area.municipio,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  area.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Barra de progresso de regeneração
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regeneração: ${area.percentualRegeneracao.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: area.percentualRegeneracao / 100,
                        minHeight: 6,
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Contador de evidências
              Column(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 16,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
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

          if (area.ultimaEvidencia != null) ...[
            const SizedBox(height: 6),
            Text(
              'Última evidência: ${_formatDate(area.ultimaEvidencia!)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Nenhuma evidência registrada',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.warning,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape_outlined,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma área atribuída',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entre em contato com o gestor',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Erro ao carregar áreas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(msg, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(areasDoUsuarioProvider),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AreaStatus status) {
    return switch (status) {
      AreaStatus.regular => AppColors.statusRecuperacao,
      AreaStatus.atencao => AppColors.statusAtencao,
      AreaStatus.critica => AppColors.statusCritica,
    };
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
