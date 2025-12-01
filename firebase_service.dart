import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save color to Firebase
  Future<void> saveColorToHistory({
    required String userEmail,
    required Color color,
    required String colorName,
    required String hex,
    required String rgb,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('colorHistory')
          .add({
        'color': color.value,
        'colorName': colorName,
        'hex': hex,
        'rgb': rgb,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toString(),
      });
      print('Color saved successfully');
    } catch (e) {
      print('Error saving color: $e');
      rethrow;
    }
  }

  // Get color history from Firebase
  Stream<List<Map<String, dynamic>>> getColorHistory(String userEmail) {
    return _firestore
        .collection('users')
        .doc(userEmail)
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

  // Delete color from history
  Future<void> deleteColor(String userEmail, String colorId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('colorHistory')
          .doc(colorId)
          .delete();
      print('Color deleted successfully');
    } catch (e) {
      print('Error deleting color: $e');
      rethrow;
    }
  }

  // Clear all color history
  Future<void> clearAllHistory(String userEmail) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('colorHistory')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('All history cleared');
    } catch (e) {
      print('Error clearing history: $e');
      rethrow;
    }
  }
}