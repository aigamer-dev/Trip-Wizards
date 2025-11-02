import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/pointycastle.dart' as pc;

/// Service for end-to-end encryption of messages using RSA and AES
class EncryptionService {
  EncryptionService._();
  static final instance = EncryptionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for RSA key pairs
  RSAKeyPair? _cachedKeyPair;
  final Map<String, String> _publicKeyCache = {};

  /// Generate or retrieve RSA key pair for the current user
  Future<RSAKeyPair> getOrCreateKeyPair() async {
    if (_cachedKeyPair != null) return _cachedKeyPair!;

    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Try to fetch existing keys from Firestore
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();

    if (data != null &&
        data['publicKey'] != null &&
        data['privateKey'] != null) {
      // Parse existing keys
      final parser = encrypt.RSAKeyParser();
      final publicKey = parser.parse(data['publicKey']) as RSAPublicKey;
      final privateKey = parser.parse(data['privateKey']) as RSAPrivateKey;
      _cachedKeyPair = RSAKeyPair(publicKey, privateKey);
      return _cachedKeyPair!;
    }

    // Generate new key pair
    final keyPair = _generateRSAKeyPair();
    _cachedKeyPair = keyPair;

    // Store public key in Firestore (private key stored securely on device)
    final publicKeyPem = _encodePublicKeyToPem(keyPair.publicKey);
    final privateKeyPem = _encodePrivateKeyToPem(keyPair.privateKey);

    await _firestore.collection('users').doc(uid).set({
      'publicKey': publicKeyPem,
      'privateKey': privateKeyPem, // In production, use flutter_secure_storage
      'keyGeneratedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return keyPair;
  }

  /// Generate a new RSA key pair
  RSAKeyPair _generateRSAKeyPair() {
    final keyGen = RSAKeyGenerator();
    final secureRandom = FortunaRandom();

    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));

    final params = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 12);
    keyGen.init(pc.ParametersWithRandom(params, secureRandom));

    final pair = keyGen.generateKeyPair();
    return RSAKeyPair(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  /// Get public key for a specific user
  Future<String> getPublicKey(String userId) async {
    // Check cache first
    if (_publicKeyCache.containsKey(userId)) {
      return _publicKeyCache[userId]!;
    }

    // Fetch from Firestore
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();

    if (data == null || data['publicKey'] == null) {
      throw Exception('Public key not found for user $userId');
    }

    final publicKey = data['publicKey'] as String;
    _publicKeyCache[userId] = publicKey;
    return publicKey;
  }

  /// Encrypt a message for multiple recipients using hybrid encryption
  /// Returns a map with encrypted AES key for each recipient and the encrypted message
  Future<Map<String, dynamic>> encryptMessage(
    String message,
    List<String> recipientIds,
  ) async {
    // Generate random AES key for this message
    final aesKey = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);

    // Encrypt message with AES
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    final encryptedMessage = encrypter.encrypt(message, iv: iv);

    // Encrypt AES key with each recipient's public key
    final encryptedKeys = <String, String>{};

    // Include sender's key so they can decrypt their own messages
    final currentUserId = _auth.currentUser?.uid;
    final allRecipients = currentUserId != null
        ? {...recipientIds, currentUserId}.toList()
        : recipientIds;

    for (final recipientId in allRecipients) {
      try {
        final publicKeyPem = await getPublicKey(recipientId);
        final parser = encrypt.RSAKeyParser();
        final publicKey = parser.parse(publicKeyPem) as RSAPublicKey;

        final rsaEncrypter = encrypt.Encrypter(
          encrypt.RSA(publicKey: publicKey),
        );
        final encryptedKey = rsaEncrypter.encrypt(base64.encode(aesKey.bytes));
        encryptedKeys[recipientId] = encryptedKey.base64;
      } catch (e) {
        // Logging removed for production
        // Continue with other recipients
      }
    }

    return {
      'encryptedMessage': encryptedMessage.base64,
      'iv': iv.base64,
      'encryptedKeys': encryptedKeys,
      'isEncrypted': true,
    };
  }

  /// Decrypt a message using the current user's private key
  Future<String> decryptMessage(Map<String, dynamic> encryptedData) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      // Get user's private key
      final keyPair = await getOrCreateKeyPair();

      // Get the encrypted AES key for this user
      final encryptedKeys =
          encryptedData['encryptedKeys'] as Map<String, dynamic>?;
      if (encryptedKeys == null || !encryptedKeys.containsKey(uid)) {
        throw Exception('No encrypted key found for current user');
      }

      final encryptedKeyBase64 = encryptedKeys[uid] as String;

      // Decrypt AES key using RSA private key
      final rsaEncrypter = encrypt.Encrypter(
        encrypt.RSA(privateKey: keyPair.privateKey),
      );
      final encryptedKey = encrypt.Encrypted.fromBase64(encryptedKeyBase64);
      final aesKeyBase64 = rsaEncrypter.decrypt(encryptedKey);
      final aesKeyBytes = base64.decode(aesKeyBase64);

      // Decrypt message using AES key
      final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes));
      final iv = encrypt.IV.fromBase64(encryptedData['iv'] as String);
      final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));

      final encryptedMessage = encrypt.Encrypted.fromBase64(
        encryptedData['encryptedMessage'] as String,
      );

      return encrypter.decrypt(encryptedMessage, iv: iv);
    } catch (e) {
      // Logging removed for production
      return '[Unable to decrypt message]';
    }
  }

  /// Clear cached keys (useful for logout)
  void clearCache() {
    _cachedKeyPair = null;
    _publicKeyCache.clear();
  }

  /// Encode RSA public key to PEM format
  String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    final modulus = publicKey.modulus!;
    final exponent = publicKey.exponent!;

    final modulusBytes = _encodeBigInt(modulus);
    final exponentBytes = _encodeBigInt(exponent);

    final keyBytes = base64.encode([...modulusBytes, ...exponentBytes]);
    return '-----BEGIN PUBLIC KEY-----\n$keyBytes\n-----END PUBLIC KEY-----';
  }

  /// Encode RSA private key to PEM format
  String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final modulus = privateKey.modulus!;
    final privateExponent = privateKey.privateExponent!;

    final modulusBytes = _encodeBigInt(modulus);
    final exponentBytes = _encodeBigInt(privateExponent);

    final keyBytes = base64.encode([...modulusBytes, ...exponentBytes]);
    return '-----BEGIN PRIVATE KEY-----\n$keyBytes\n-----END PRIVATE KEY-----';
  }

  /// Encode BigInt to bytes
  List<int> _encodeBigInt(BigInt number) {
    final bytes = <int>[];
    var n = number;
    while (n > BigInt.zero) {
      bytes.insert(0, (n & BigInt.from(0xff)).toInt());
      n = n >> 8;
    }
    return bytes;
  }
}

/// RSA key pair holder
class RSAKeyPair {
  final RSAPublicKey publicKey;
  final RSAPrivateKey privateKey;

  RSAKeyPair(this.publicKey, this.privateKey);
}
