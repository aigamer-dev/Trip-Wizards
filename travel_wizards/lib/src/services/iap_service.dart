// ignore_for_file: undefined_import, undefined_class, undefined_identifier
// Google Play Billing (subscriptions) integration using in_app_purchase.
// Note: Requires adding `in_app_purchase` to pubspec and running `flutter pub get`.
import 'dart:async';
import 'dart:io' show Platform;
import 'package:in_app_purchase/in_app_purchase.dart';

/// Simple wrapper around in_app_purchase for Google Play subscriptions.
class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  // Configure your product IDs (managed on Play Console).
  // These should exist in Google Play and match app signing.
  static const String skuProMonthly = 'pro_monthly';
  static const String skuEnterpriseMonthly = 'enterprise_monthly';

  Future<bool> init() async {
    if (!Platform.isAndroid) return false; // Google Play only per request
    final isAvailable = await _iap.isAvailable();
    return isAvailable;
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetails?> getProduct(String sku) async {
    final resp = await queryProducts({sku});
    if (resp.productDetails.isEmpty) return null;
    return resp.productDetails.first;
  }

  Future<ProductDetailsResponse> queryProducts(Set<String> ids) {
    return _iap.queryProductDetails(ids);
  }

  Future<bool> buySubscriptionWithResult(
    ProductDetails product, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final completer = Completer<bool>();
    late final StreamSubscription<List<PurchaseDetails>> sub;
    sub = _iap.purchaseStream.listen(
      (purchases) async {
        for (final p in purchases) {
          if (p.productID == product.id) {
            if (p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored) {
              try {
                await _iap.completePurchase(p);
              } catch (_) {}
              if (!completer.isCompleted) completer.complete(true);
              await sub.cancel();
            } else if (p.status == PurchaseStatus.error ||
                p.status == PurchaseStatus.canceled) {
              if (!completer.isCompleted) completer.complete(false);
              await sub.cancel();
            }
          }
        }
      },
      onError: (Object error) async {
        if (!completer.isCompleted) completer.complete(false);
        await sub.cancel();
      },
    );

    final param = PurchaseParam(productDetails: product);
    final ok = await _iap.buyNonConsumable(purchaseParam: param);
    if (!ok) {
      await sub.cancel();
      return false;
    }
    return completer.future.timeout(
      timeout,
      onTimeout: () async {
        await sub.cancel();
        return false;
      },
    );
  }
}
