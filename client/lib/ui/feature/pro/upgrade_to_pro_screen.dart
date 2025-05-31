import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/pro_product_info.dart';
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
              title: '家事の登録件数が無制限に',
              description: 'フリー版では最大10件までの家事しか登録できませんが、Pro版では無制限に登録できます。',
            ),
            SizedBox(height: 16),
            _FeatureItem(
              icon: Icons.lock_clock,
              title: '今後追加される機能も使い放題',
              description: '今後追加される有料機能もすべて使えるようになります。',
              isComingSoon: true,
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
    this.isComingSoon = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color:
              isComingSoon
                  ? Theme.of(context).colorScheme.onSurface.withAlpha(100)
                  : Colors.green,
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
                        color:
                            isComingSoon
                                ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(100)
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isComingSoon) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '近日公開',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isComingSoon
                          ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100)
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchasablesPanel extends ConsumerWidget {
  const _PurchasablesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasablesFuture = ref.watch(purchasableProductsProvider.future);

    return FutureBuilder(
      future: purchasablesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PriceError(message: snapshot.error.toString());
        }

        final purchasables = snapshot.data;
        if (purchasables == null) {
          return const _PriceError(message: 'Pro版の価格情報が取得できませんでした。');
        }

        final contents =
            purchasables.map((product) {
              return _PriceContent(productInfo: product, onTap: purchase);
            }).toList();

        return Column(spacing: 4, children: contents);
      },
    );
  }

  Future<void> purchase(ProProductInfo productInfo) async {
    try {
      await ref.read(purchaseResultProvider(productInfo).future);
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
  }
}

class _PriceContent extends StatelessWidget {
  const _PriceContent({required this.productInfo, required this.onTap});

  final ProProductInfo productInfo;
  final void Function(ProProductInfo) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(productInfo),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 16,
              children: [
                Text(
                  productInfo.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  productInfo.price,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            Text(
              productInfo.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceLoadingSkeleton extends StatelessWidget {
  const _PriceLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
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
