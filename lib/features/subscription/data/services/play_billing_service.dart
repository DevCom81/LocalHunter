import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Encapsule le SDK Google Play Billing (Android uniquement).
class PlayBillingService {
  PlayBillingService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<Map<String, ProductDetails>> queryProducts(Set<String> productIds) async {
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    return {for (final p in response.productDetails) p.id: p};
  }

  Future<void> buySubscription(ProductDetails product, String userId) {
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      ),
    );
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }
}
