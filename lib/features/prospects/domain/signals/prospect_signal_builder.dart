import '../entities/prospect.dart';
import 'prospect_signal.dart';

/// Construit la liste de [ProspectSignal] à partir des champs déjà sur [Prospect].
///
/// Phase 4 : mapping déterministe uniquement — aucune inférence IA.
class ProspectSignalBuilder {
  const ProspectSignalBuilder();

  List<ProspectSignal> build(Prospect p) {
    final out = <ProspectSignal>[];

    void fact(
      String type,
      String label,
      Object value,
      String source, {
      DateTime? at,
      double confidence = 1.0,
    }) {
      out.add(
        ProspectSignal(
          type: type,
          label: label,
          value: value,
          source: source,
          kind: SignalKind.fact,
          confidence: confidence,
          observedAt: at,
        ),
      );
    }

    void signal(
      String type,
      String label,
      Object value,
      String source, {
      DateTime? at,
      double confidence = 1.0,
    }) {
      out.add(
        ProspectSignal(
          type: type,
          label: label,
          value: value,
          source: source,
          kind: SignalKind.signal,
          confidence: confidence,
          observedAt: at,
        ),
      );
    }

    if (p.siren != null && p.siren!.isNotEmpty) {
      fact('SIREN', 'SIREN', p.siren!, 'SIRENE');
    }
    if (p.siret != null && p.siret!.isNotEmpty) {
      fact('SIRET', 'SIRET', p.siret!, 'SIRENE');
    }
    if (p.nafCode != null && p.nafCode!.isNotEmpty) {
      fact('ACTIVITY_CODE', 'Code NAF', p.nafCode!, 'SIRENE');
    }
    if (p.legalForm != null && p.legalForm!.isNotEmpty) {
      fact('LEGAL_FORM', 'Forme juridique', p.legalForm!, 'SIRENE');
    }
    if (p.creationDate != null) {
      fact(
        'COMPANY_CREATED_AT',
        'Date de création',
        _fmtDate(p.creationDate!),
        'SIRENE',
        at: p.creationDate,
      );
      final years =
          DateTime.now().difference(p.creationDate!).inDays / 365.25;
      signal(
        'COMPANY_AGE',
        'Ancienneté (années)',
        years.toStringAsFixed(1),
        'SIRENE',
        at: p.creationDate,
      );
    }

    if (p.annualRevenue != null) {
      fact(
        'REVENUE',
        'Chiffre d\'affaires',
        '${p.annualRevenue}${p.annualRevenueYear != null ? ' (${p.annualRevenueYear})' : ''}',
        'COMPANY',
      );
    }
    if (p.netIncome != null) {
      fact('NET_INCOME', 'Résultat net', p.netIncome!, 'COMPANY');
    }
    if (p.managerName != null && p.managerName!.trim().isNotEmpty) {
      fact('MANAGER_NAME', 'Dirigeant', p.managerName!, 'COMPANY');
    }

    if (p.googleRating != null) {
      fact('GOOGLE_RATING', 'Note Google', p.googleRating!, 'PLACES');
    }
    if (p.googleReviews > 0) {
      fact('GOOGLE_REVIEWS', 'Avis Google', p.googleReviews, 'PLACES');
    }
    if (p.category != null && p.category!.isNotEmpty) {
      fact('BUSINESS_CATEGORY', 'Catégorie', p.category!, 'PLACES');
    }
    if (p.hasWebsite) {
      fact('WEBSITE_EXISTS', 'Site web', true, 'PLACES');
    }
    if (p.pagespeedScore != null) {
      fact(
        'WEBSITE_PERFORMANCE',
        'Score PageSpeed',
        p.pagespeedScore!,
        'PAGESPEED',
      );
    }

    if (p.hasSocialCheck) {
      final at = p.socialCheckedAt;
      // Non détecté ≠ absence absolue de réseaux sociaux.
      signal(
        'SOCIAL_PRESENCE_FROM_SITE',
        (p.socialNetworkCount ?? 0) > 0
            ? 'Réseaux détectés sur le site'
            : 'Aucun réseau social détecté depuis le site analysé',
        (p.socialNetworkCount ?? 0) > 0,
        'WEBSITE',
        at: at,
        confidence: 0.75,
      );
      signal(
        'SOCIAL_NETWORK_COUNT',
        'Nombre de réseaux détectés (site)',
        p.socialNetworkCount ?? 0,
        'WEBSITE',
        at: at,
        confidence: 0.75,
      );
      void socialUrl(String type, String label, String? url) {
        if (url == null || url.isEmpty) return;
        fact(type, label, url, 'WEBSITE', at: at, confidence: 0.75);
      }
      socialUrl('FACEBOOK_URL', 'Facebook (site)', p.facebookUrl);
      socialUrl('INSTAGRAM_URL', 'Instagram (site)', p.instagramUrl);
      socialUrl('LINKEDIN_URL', 'LinkedIn (site)', p.linkedinUrl);
      socialUrl('TIKTOK_URL', 'TikTok (site)', p.tiktokUrl);
      socialUrl('YOUTUBE_URL', 'YouTube (site)', p.youtubeUrl);
      socialUrl('X_URL', 'X / Twitter (site)', p.xUrl);
    }

    if (p.hasBodaccEnrichment && p.bodaccNoResults != true) {
      final conf = double.tryParse(p.bodaccSignalConfidence ?? '') ?? 1.0;
      final at = p.bodaccLastEventAt;
      void bodacc(String type, String label, bool? flag) {
        if (flag == null) return;
        signal(
          type,
          label,
          flag,
          'BODACC',
          at: at,
          confidence: conf.clamp(0.0, 1.0),
        );
      }

      bodacc('BODACC_HAS_CREATION', 'Création (BODACC)', p.bodaccHasCreation);
      bodacc(
        'BODACC_HAS_ACCOUNTS_FILING',
        'Dépôt de comptes',
        p.bodaccHasAccountsFiling,
      );
      bodacc('BODACC_HAS_SALE', 'Vente / cession', p.bodaccHasSale);
      bodacc(
        'BODACC_HAS_MANAGER_CHANGE',
        'Changement de dirigeant',
        p.bodaccHasManagerChange,
      );
      bodacc(
        'BODACC_HAS_ADDRESS_CHANGE',
        'Changement d\'adresse',
        p.bodaccHasAddressChange,
      );
      bodacc(
        'BODACC_HAS_MODIFICATION',
        'Modification',
        p.bodaccHasModification,
      );
      bodacc(
        'BODACC_HAS_COLLECTIVE',
        'Procédure collective',
        p.bodaccHasCollectiveProceeding,
      );
      bodacc('BODACC_HAS_LIQUIDATION', 'Liquidation', p.bodaccHasLiquidation);
      bodacc('BODACC_HAS_RADIATION', 'Radiation', p.bodaccHasRadiation);
    }

    return out;
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
