import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../data/models/registro_evidencia.dart';
import '../../areas/areas_provider.dart';
import '../sync_service.dart';

/// Tela de fila de sincronização — evidências pendentes de envio.
class SyncQueueScreen extends ConsumerWidget {
  const SyncQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final filaAsync = ref.watch(filaSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendências de Envio'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          filaAsync.when(
            data: (fila) => fila.isNotEmpty
                ? TextButton.icon(
                    onPressed: syncState.isRunning
                        ? null
                        : () => _sincronizar(ref, context),
                    icon: syncState.isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Enviar tudo'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: filaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (fila) {
          if (fila.isEmpty) return _buildEmpty(context);
          return Column(
            children: [
              _buildSummaryBanner(context, fila, syncState.isRunning),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: fila.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (_, i) => _buildCard(context, fila[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sincronizar(WidgetRef ref, BuildContext context) async {
    final result =
        await ref.read(syncNotifierProvider.notifier).syncNow();

    ref.invalidate(filaSyncProvider);
    ref.invalidate(pendenciasCountProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success > 0
              ? '${result.success} evidência(s) enviada(s) com sucesso!'
              : 'Nenhuma evidência foi enviada.'),
          backgroundColor: result.success > 0
              ? AppColors.statusRecuperacao
              : AppColors.warning,
        ),
      );
    }
  }

  Widget _buildSummaryBanner(
      BuildContext context, List<RegistroEvidencia> fila, bool syncing) {
    final erros =
        fila.where((e) => e.statusSync == StatusSincronizacao.erro).length;
    final pendentes =
        fila.where((e) => e.statusSync == StatusSincronizacao.pendente).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.warningLight,
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pendentes pendente(s)${erros > 0 ? ' • $erros com erro' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (syncing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.warning),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, RegistroEvidencia e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isErro = e.statusSync == StatusSincronizacao.erro;
    final borderColor = isErro ? AppColors.error : AppColors.warning;
    final primeiraFoto = e.fotos.isNotEmpty ? e.fotos.first : null;

    return SaraCard(
      border: Border(left: BorderSide(color: borderColor, width: 3)),
      child: Row(
        children: [
          if (primeiraFoto != null && primeiraFoto.pathLocal.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Image.file(
                  File(primeiraFoto.pathLocal),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported_outlined,
                        size: 20),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.textTertiary),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.tipo.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  'Área: ${e.areaId} • ${e.fotos.length} foto(s)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                ),
                Text(
                  _formatDate(e.dataRegistro),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              isErro ? 'ERRO' : 'PENDENTE',
              style: TextStyle(
                  color: borderColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
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
          Icon(Icons.cloud_done_rounded,
              size: 64,
              color: AppColors.statusRecuperacao.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Tudo sincronizado!',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Nenhuma evidência pendente de envio',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
