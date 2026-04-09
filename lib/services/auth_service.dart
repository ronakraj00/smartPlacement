import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import '../models/user_model.dart' as model;

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  model.UserModel? _currentUser;
  bool _isLoading = true;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _init();
  }

  model.UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    try {
      _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          await _fetchUserData(user.uid);
        } else {
          _currentUser = null;
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      if (kDebugMode) {
        print("Auth Service Init Error (Maybe Firebase not configured?): $e");
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = model.UserModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
        
        // Initialize Notification logic and cache FCM Token to firestore asynchronously
        NotificationService().init(uid);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching user data: $e");
      }
    }
  }

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required model.UserRole role,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role.toString().split('.').last,
        // Recruiters require admin approval before they can post jobs
        if (role == model.UserRole.recruiter) 'accountStatus': 'pending',
      });

      // Fix race condition: the auth listener triggers before the firestore document is created
      await _fetchUserData(credential.user!.uid);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Registration error: $e");
      }
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print("Sign out failed, clearing mock user");
      }
    }
    _currentUser = null;
    notifyListeners();
  }
}
