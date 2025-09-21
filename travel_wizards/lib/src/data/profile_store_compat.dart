import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/data/profile_store.dart';

/// Back-compat helpers for ProfileStore.
/// Ensures we can write extended fields even if the base ProfileStore
/// does not (yet) expose them as named params.
extension ProfileStoreCompat on ProfileStore {
  Future<void> updateAll({
    String? name,
    String? email,
    String? photoUrl,
    String? dob,
    String? state,
    String? city,
    String? foodPref,
    String? allergies,
  }) async {
    // Always update known base fields through the store API.
    await update(name: name, email: email, photoUrl: photoUrl);

    // Write extended fields directly to SharedPreferences so this works
    // even on older versions of ProfileStore.
    final prefs = await SharedPreferences.getInstance();
    if (dob != null) await prefs.setString('profile_dob', dob);
    if (state != null) await prefs.setString('profile_state', state);
    if (city != null) await prefs.setString('profile_city', city);
    if (foodPref != null) await prefs.setString('profile_food_pref', foodPref);
    if (allergies != null) {
      await prefs.setString('profile_allergies', allergies);
    }
  }
}
