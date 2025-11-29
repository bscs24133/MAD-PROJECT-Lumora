import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Save color to Firebase
  Future<void> saveColorToHistory({
    required Color color,
    required String colorName,
    required String hex,
    required String rgb,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('colorHistory')
          .add({
        'color': color.value,
        'colorName': colorName,
        'hex': hex,
        'rgb': rgb,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toString(),
      });
      print('Color saved successfully for user: $userId');
    } catch (e) {
      print('Error saving color: $e');
      rethrow;
    }
  }

  // Get color history from Firebase
  Stream<List<Map<String, dynamic>>> getColorHistory() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]); // Return empty stream if user not logged in
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('colorHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID for deletion
        return data;
      }).toList();
    });
  }

  // Delete a single color from history
  Future<void> deleteColor(String colorId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('colorHistory')
          .doc(colorId)
          .delete();
      print('Color deleted successfully');
    } catch (e) {
      print('Error deleting color: $e');
      rethrow;
    }
  }

  // Clear all color history for the user
  Future<void> clearAllHistory() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('colorHistory')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('All history cleared for user: $userId');
    } catch (e) {
      print('Error clearing history: $e');
      rethrow;
    }
  }
}
