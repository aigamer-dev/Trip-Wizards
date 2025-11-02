import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Invite {
  final String id;
  final String email;
  final String status; // pending, accepted, declined
  final DateTime createdAt;

  Invite({
    required this.id,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Invite.fromMap(Map<String, dynamic> map) => Invite(
    id: map['id'] as String,
    email: map['email'] as String,
    status: map['status'] as String? ?? 'pending',
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}

class InvitesRepository {
  InvitesRepository._();
  static final InvitesRepository instance = InvitesRepository._();

  CollectionReference<Map<String, dynamic>> _collection(String tripId) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .collection('invites');
  }

  Future<void> sendInvite({
    required String tripId,
    required String email,
  }) async {
    final id = FirebaseFirestore.instance.collection('_ids').doc().id;
    final invite = Invite(
      id: id,
      email: email.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await _collection(tripId).doc(id).set(invite.toMap());
  }

  Future<List<Invite>> listInvites(String tripId) async {
    final snap = await _collection(
      tripId,
    ).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Invite.fromMap(d.data())).toList();
  }

  Stream<List<Invite>> watchInvites(String tripId) {
    return _collection(tripId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Invite.fromMap(d.data())).toList());
  }

  Future<void> updateInviteStatus({
    required String tripId,
    required String inviteId,
    required String status, // pending|accepted|declined
  }) async {
    await _collection(tripId).doc(inviteId).update({'status': status});
  }

  Future<void> cancelInvite({
    required String tripId,
    required String inviteId,
  }) async {
    await _collection(tripId).doc(inviteId).delete();
  }
}
