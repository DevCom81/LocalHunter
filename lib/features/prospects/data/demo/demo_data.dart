import '../../../../core/constants/prospect_status.dart';
import '../../domain/entities/prospect.dart';

class DemoData {
  static const campaignId = 'demo-campaign-albi';
  static const userId = 'demo-user';

  static List<Prospect> albiProspects() {
    return [
      _p('1', 'Le Bistrot d\'Albi', 'Restaurant', null, '05 63 00 01 01',
          'contact@bistrot-albi.fr', 4.2, 87, false),
      _p('2', 'Casa Pizz\'Albi', 'Pizzeria', 'http://casapizz.wix.com', '05 63 00 02 02',
          null, 3.8, 45, false),
      _p('3', 'Bar Le Pont', 'Bar', null, '05 63 00 03 03', null, 4.0, 32, false),
      _p('4', 'Snack du Centre', 'Snack', null, '05 63 00 04 04',
          'snack@albi.fr', 3.5, 18, false),
      _p('5', 'McDonald\'s Albi', 'Restauration rapide', 'https://mcdonalds.fr', null,
          null, 3.2, 420, true, reason: 'Chaîne connue'),
      _p('6', 'Brasserie du Tarn', 'Brasserie', 'http://brasserie-tarn.fr', '05 63 00 06 06',
          'info@brasserie-tarn.fr', 4.1, 112, false),
      _p('7', 'Restaurant Zelty Demo', 'Restaurant', 'https://zelty.co', '05 63 00 07 07',
          null, 4.5, 95, false),
      _p('8', 'L\'Ambassade', 'Restaurant gastronomique',
          'https://ambassade-albi.fr', '05 63 00 08 08', 'reservation@ambassade.fr',
          4.7, 210, false),
      _p('9', 'Hôtel Mercure Albi', 'Hôtel-restaurant', 'https://mercure.com/albi', null,
          'contact@corp.mercure.com', 4.0, 380, true, reason: 'Groupe hôtelier'),
      _p('10', 'Taverne du Vieil Alby', 'Restaurant', 'http://taverne-albi.wordpress.com',
          '05 63 00 10 10', null, 3.9, 56, false),
      _p('11', 'Le Comptoir', 'Bar', null, '05 63 00 11 11', 'comptoir@albi.fr',
          4.3, 28, false),
      _p('12', 'Pizza Express Albi', 'Pizzeria', 'http://pizza-express-albi.fr', '05 63 00 12 12',
          null, 3.6, 22, false),
      _p('13', 'Buffalo Grill Albi', 'Grill', 'https://buffalo-grill.fr', null,
          null, 3.4, 890, true, reason: 'Franchise nationale'),
      _p('14', 'Creperie du Castelnau', 'Crêperie', null, '05 63 00 14 14',
          'crepe@albi.fr', 4.4, 67, false),
      _p('15', 'Café de la Madeleine', 'Café', 'https://cafemadeleine-albi.fr', '05 63 00 15 15',
          'hello@cafemadeleine-albi.fr', 4.6, 145, false),
    ];
  }

  static Prospect _p(
    String id,
    String name,
    String category,
    String? website,
    String? phone,
    String? email,
    double rating,
    int reviews,
    bool excluded, {
    String? reason,
  }) {
    return Prospect(
      id: id,
      campaignId: campaignId,
      name: name,
      city: 'Albi',
      address: '81000 Albi',
      managerName: excluded ? null : 'Gérant',
      email: email,
      phone: phone,
      website: website,
      googleRating: rating,
      googleReviews: reviews,
      category: category,
      status: excluded ? ProspectStatus.excluded : ProspectStatus.newProspect,
      isExcluded: excluded,
      exclusionReason: reason,
      createdAt: DateTime.now(),
    );
  }
}
