import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/purchasable.dart';
import 'package:pochi_trim/data/service/revenue_cat_service.dart';
import 'package:pochi_trim/ui/feature/pro/pro_purchase_presenter.dart';
import 'package:pochi_trim/ui/feature/pro/purchase_exception.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UpgradeToProScreen extends ConsumerStatefulWidget {
  const UpgradeToProScreen({super.key});

  static const name = 'UpgradeToProScreen';

  static MaterialPageRoute<UpgradeToProScreen> route() =>
      MaterialPageRoute<UpgradeToProScreen>(
        builder: (_) => const UpgradeToProScreen(),
        settings: const RouteSettings(name: name),
        fullscreenDialog: true,
      );

  @override
  ConsumerState<UpgradeToProScreen> createState() => _UpgradeToProScreenState();
}

class _UpgradeToProScreenState extends ConsumerState<UpgradeToProScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pro版にアップグレード')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24 + MediaQuery.of(context).viewPadding.left,
          top: 24,
          right: 24 + MediaQuery.of(context).viewPadding.right,
          bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.workspace_premium,
                size: 80,
                color: Colors.amber,
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                'Pro版の特典',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 32),
            _FeatureItem(
              icon: Icons.check_circle,
              title: '家事の種類が無制限に',
              description: 'フリー版では最大10種類までの家事しか登録できませんが、Pro版では無制限に登録できます。',
            ),
            SizedBox(height: 16),
            _FeatureItem(
              icon: Icons.check_circle,
              title: '分析期間が最大1ヶ月に',
              description:
                  'フリー版では2週間までの期間しか選択できませんが、Pro版では1ヶ月までの期間で家事の実行状況を分析できます。',
            ),
            SizedBox(height: 32),
            _PurchasablesPanel(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchasablesPanel extends ConsumerStatefulWidget {
  const _PurchasablesPanel();

  @override
  ConsumerState<_PurchasablesPanel> createState() => _PurchasablesPanelState();
}

class _PurchasablesPanelState extends ConsumerState<_PurchasablesPanel> {
  @override
  Widget build(BuildContext context) {
    final purchasablesFuture = ref.watch(currentPurchasablesProvider.future);
    final purchaseStatus = ref.watch(currentPurchaseStatusProvider);

    return FutureBuilder(
      future: purchasablesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PriceError(message: snapshot.error.toString());
        }

        final purchasables = snapshot.data;
        final Widget priceTile;
        if (purchasables == null) {
          priceTile = const _PriceTile(
            title: 'Pro版',
            price: '400',
            effectivePeriod: EffectivePeriod.lifetime,
            description: '全ての機能が利用できるようになります。',
          );
        } else {
          final purchasable = purchasables.first;
          priceTile = _PriceTile(
            title: purchasable.title,
            price: purchasable.price,
            effectivePeriod: purchasable.effectivePeriod,
            description: purchasable.description,
          );
        }

        final purchaseButton = ElevatedButton(
          onPressed:
              (purchasables == null || purchaseStatus != PurchaseStatus.none)
              ? null
              : () => _purchase(purchasables.first),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (purchaseStatus == PurchaseStatus.inPurchasing) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    semanticsLabel: '購入しています',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '購入中...',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ] else
                Text(
                  '購入する',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        );

        final restoreButton = TextButton(
          onPressed: purchaseStatus != PurchaseStatus.none
              ? null
              : _restorePurchases,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (purchaseStatus == PurchaseStatus.inRestoring) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    semanticsLabel: '購入履歴を復元しています',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '復元中...',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary.withAlpha(150),
                  ),
                ),
              ] else
                Text(
                  '購入履歴を復元する',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        );

        return Skeletonizer(
          enabled: purchasables == null,
          child: Column(
            spacing: 16,
            children: [
              priceTile,
              const SizedBox(height: 20),
              purchaseButton,
              restoreButton,
            ],
          ),
        );
      },
    );
  }

  Future<void> _purchase(Purchasable productInfo) async {
    try {
      await ref
          .read(currentPurchaseStatusProvider.notifier)
          .purchase(productInfo);
    } on PurchaseException catch (e) {
      switch (e) {
        case PurchaseExceptionCancelled():
          return;

        case PurchaseExceptionUncategorized():
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('購入中にエラーが発生しました。しばらくしてから再度お試しください。')),
          );
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('購入が完了しました')));

    Navigator.of(context).pop();
  }

  Future<void> _restorePurchases() async {
    try {
      await ref.read(currentPurchaseStatusProvider.notifier).restore();
    } on RestorePurchaseException catch (e) {
      switch (e) {
        case RestorePurchaseExceptionNotFound():
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('購入履歴が見つかりませんでした。')));
          return;

        case RestorePurchaseExceptionUncategorized():
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('購入履歴の復元中にエラーが発生しました。しばらくしてから再度お試しください。'),
            ),
          );
          return;
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('購入履歴の復元が完了しました。')));

    Navigator.of(context).pop();
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.title,
    required this.price,
    required this.effectivePeriod,
    required this.description,
  });

  final String title;
  final String price;
  final EffectivePeriod effectivePeriod;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            spacing: 16,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(price, style: Theme.of(context).textTheme.titleLarge),
              if (effectivePeriod == EffectivePeriod.lifetime)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '買い切り',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PriceError extends ConsumerWidget {
  const _PriceError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
