import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/services/play_billing_service.dart';
import '../../data/services/play_purchase_verifier.dart';
import '../../domain/entities/subscription_tier.dart';
import 'subscription_providers.dart';

final playBillingServiceProvider = Provider<PlayBillingService>((ref) {
  return PlayBillingService();
});

final playPurchaseVerifierProvider = Provider<PlayPurchaseVerifier?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PlayPurchaseVerifier(client);
});

class PlayBillingState {
  const PlayBillingState({
    this.available = false,
    this.loading = true,
    this.processing = false,
    this.products = const {},
    this.error,
  });

  final bool available;
  final bool loading;
  final bool processing;
  final Map<String, ProductDetails> products;
  final String? error;

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  PlayBillingState copyWith({
    bool? available,
    bool? loading,
    bool? processing,
    Map<String, ProductDetails>? products,
    String? error,
    bool clearError = false,
  }) {
    return PlayBillingState(
      available: available ?? this.available,
      loading: loading ?? this.loading,
      processing: processing ?? this.processing,
      products: products ?? this.products,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final playBillingControllerProvider =
    NotifierProvider<PlayBillingController, PlayBillingState>(
  PlayBillingController.new,
);

class PlayBillingController extends Notifier<PlayBillingState> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  @override
  PlayBillingState build() {
    ref.onDispose(() => _purchaseSub?.cancel());
    Future.microtask(_bootstrap);
    return const PlayBillingState();
  }

  Future<void> _bootstrap() async {
    if (!state.isAndroid || ref.read(supabaseClientProvider) == null) {
      state = state.copyWith(loading: false, available: false);
      return;
    }

    final billing = ref.read(playBillingServiceProvider);
    try {
      final available = await billing.isAvailable();
      if (!available) {
        state = state.copyWith(loading: false, available: false);
        return;
      }

      _purchaseSub ??= billing.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          state = state.copyWith(processing: false, error: e.toString());
        },
      );

      final products = await billing.queryProducts(SubscriptionTier.playProductIds);
      state = state.copyWith(
        loading: false,
        available: true,
        products: products,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> purchase(SubscriptionTier tier) async {
    final productId = tier.playProductId;
    final userId = ref.read(currentUserProvider)?.id;
    final product = productId == null ? null : state.products[productId];
    if (productId == null || userId == null || product == null) {
      state = state.copyWith(error: 'Achat indisponible pour cette offre.');
      return;
    }

    state = state.copyWith(processing: true, clearError: true);
    try {
      await ref.read(playBillingServiceProvider).buySubscription(product, userId);
    } catch (e) {
      state = state.copyWith(processing: false, error: e.toString());
    }
  }

  Future<void> restorePurchases() async {
    if (!state.available) return;
    state = state.copyWith(processing: true, clearError: true);
    try {
      await ref.read(playBillingServiceProvider).restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 2));
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      if (state.processing) {
        state = state.copyWith(processing: false);
      }
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final billing = ref.read(playBillingServiceProvider);
    final verifier = ref.read(playPurchaseVerifierProvider);
    if (verifier == null) return;

    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(
          processing: false,
          error: purchase.error?.message ?? 'Achat annulé ou échoué.',
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(processing: false, clearError: true);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await verifier.verify(
            purchaseToken: purchase.verificationData.serverVerificationData,
            productId: purchase.productID,
          );
          ref.invalidate(subscriptionTierProvider);
          state = state.copyWith(processing: false, clearError: true);
        } catch (e) {
          state = state.copyWith(processing: false, error: e.toString());
        }
      }

      await billing.completePurchase(purchase);
    }
  }
}
