import 'dart:async';

class BrainstormService {
  BrainstormService._();
  static final BrainstormService instance = BrainstormService._();

  Future<String> send(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Return a simple simulated response
    return 'AI: Based on "$prompt", consider a 3-day weekend to Goa with beaches, seafood, and a sunset cruise.';
  }
}
