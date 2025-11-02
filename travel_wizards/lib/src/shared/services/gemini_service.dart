/// Lightweight heuristic for an on-device Gemini-style classification.
/// You can swap this with a real on-device model integration when available.
class GeminiService {
  /// Returns true if the text likely refers to a trip/travel event.
  static Future<bool> isTripText(String text) async {
    // Simple heuristic; replace with model inference when integrating a local model.
    final t = text.toLowerCase();
    const keywords = [
      'trip',
      'travel',
      'flight',
      'vacation',
      'holiday',
      'hotel',
      'itinerary',
      'check-in',
      'boarding',
    ];
    return keywords.any(t.contains);
  }
}
