import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/models/urun.dart';

class ShoppingListService {
  ShoppingListService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // A single default list per device/user for now
  CollectionReference<Map<String, dynamic>> get _listsCol => _db.collection('shoppingLists');

  DocumentReference<Map<String, dynamic>> listRef(String listId) => _listsCol.doc(listId);

  CollectionReference<Map<String, dynamic>> itemsCol(String listId) => listRef(listId).collection('items');

  Future<String> ensureDefaultList(String ownerId) async {
    // Deterministic default list id to avoid needing read permissions
  final id = 'default_$ownerId';
    await listRef(id).set({
      'ownerId': ownerId,
      'name': 'Varsayilan Liste',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return id;
  }

  Stream<List<Urun>> watchItems(String listId) {
    return itemsCol(listId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Urun.fromMap(d.data())).toList());
  }

  Future<void> addItem(String listId, Urun urun) async {
    await itemsCol(listId).add({
      ...urun.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeItem(String listId, String itemId) async {
    await itemsCol(listId).doc(itemId).delete();
  }

  Future<void> clearItems(String listId) async {
    final batch = _db.batch();
    final docs = await itemsCol(listId).get();
    for (final d in docs.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  // With document IDs for UI actions
  Stream<List<ItemRecord>> watchItemsWithIds(String listId) {
    return itemsCol(listId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ItemRecord(d.id, Urun.fromMap(d.data())))
            .toList());
  }
}

class ItemRecord {
  final String id;
  final Urun urun;
  ItemRecord(this.id, this.urun);
}
