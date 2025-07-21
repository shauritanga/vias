import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firebase-based admin authentication and management service
class FirebaseAdminService {
  static final FirebaseAdminService _instance = FirebaseAdminService._internal();
  factory FirebaseAdminService() => _instance;
  FirebaseAdminService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin user roles
  static const String adminRole = 'admin';
  static const String superAdminRole = 'super_admin';
  static const String staffRole = 'staff';

  /// Get current admin user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Initialize admin service and create default admin if needed
  Future<void> initialize() async {
    try {
      // Check if any admin users exist
      final adminUsers = await _firestore
          .collection('admin_users')
          .where('role', whereIn: [adminRole, superAdminRole])
          .get();

      if (adminUsers.docs.isEmpty) {
        if (kDebugMode) print('No admin users found, creating default admin...');
        await _createDefaultAdmin();
      }

      if (kDebugMode) print('Firebase Admin Service initialized');
    } catch (e) {
      if (kDebugMode) print('Error initializing Firebase Admin Service: $e');
    }
  }

  /// Create default admin user
  Future<void> _createDefaultAdmin() async {
    try {
      // Create default admin account
      const defaultEmail = 'admin@dit.ac.tz';
      const defaultPassword = 'DIT@2024!Admin';

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: defaultEmail,
        password: defaultPassword,
      );

      if (userCredential.user != null) {
        // Add admin user data to Firestore
        await _firestore.collection('admin_users').doc(userCredential.user!.uid).set({
          'email': defaultEmail,
          'name': 'Default Administrator',
          'role': superAdminRole,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': null,
          'isActive': true,
          'permissions': [
            'manage_content',
            'manage_users',
            'view_analytics',
            'system_admin',
          ],
        });

        // Update user profile
        await userCredential.user!.updateDisplayName('Default Administrator');

        if (kDebugMode) {
          print('Default admin created successfully:');
          print('Email: $defaultEmail');
          print('Password: $defaultPassword');
          print('Role: $superAdminRole');
        }

        // Sign out after creating the account
        await _auth.signOut();
      }
    } catch (e) {
      if (kDebugMode) print('Error creating default admin: $e');
    }
  }

  /// Sign in admin user
  Future<AdminLoginResult> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Check if user is an admin
        final adminDoc = await _firestore
            .collection('admin_users')
            .doc(userCredential.user!.uid)
            .get();

        if (!adminDoc.exists) {
          await _auth.signOut();
          return AdminLoginResult(
            success: false,
            message: 'Access denied: Not an admin user',
          );
        }

        final adminData = adminDoc.data()!;
        if (adminData['isActive'] != true) {
          await _auth.signOut();
          return AdminLoginResult(
            success: false,
            message: 'Account is deactivated',
          );
        }

        // Update last login
        await _firestore
            .collection('admin_users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        return AdminLoginResult(
          success: true,
          message: 'Login successful',
          user: userCredential.user,
          adminData: AdminUserData.fromMap(adminData),
        );
      }

      return AdminLoginResult(
        success: false,
        message: 'Login failed',
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No admin account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }

      return AdminLoginResult(
        success: false,
        message: message,
      );
    } catch (e) {
      return AdminLoginResult(
        success: false,
        message: 'Login error: $e',
      );
    }
  }

  /// Sign out admin user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (kDebugMode) print('Admin signed out successfully');
    } catch (e) {
      if (kDebugMode) print('Error signing out: $e');
    }
  }

  /// Create new admin user
  Future<AdminCreateResult> createAdminUser({
    required String email,
    required String password,
    required String name,
    required String role,
    List<String> permissions = const [],
  }) async {
    try {
      // Check if current user has permission to create admins
      if (!await _hasPermission('system_admin')) {
        return AdminCreateResult(
          success: false,
          message: 'Insufficient permissions to create admin users',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Add admin user data
        await _firestore.collection('admin_users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid,
          'lastLogin': null,
          'isActive': true,
          'permissions': permissions,
        });

        await userCredential.user!.updateDisplayName(name);

        return AdminCreateResult(
          success: true,
          message: 'Admin user created successfully',
          userId: userCredential.user!.uid,
        );
      }

      return AdminCreateResult(
        success: false,
        message: 'Failed to create user account',
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account with this email already exists';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = 'Account creation failed: ${e.message}';
      }

      return AdminCreateResult(
        success: false,
        message: message,
      );
    } catch (e) {
      return AdminCreateResult(
        success: false,
        message: 'Error creating admin user: $e',
      );
    }
  }

  /// Get admin user data
  Future<AdminUserData?> getAdminUserData(String userId) async {
    try {
      final doc = await _firestore.collection('admin_users').doc(userId).get();
      if (doc.exists) {
        return AdminUserData.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting admin user data: $e');
      return null;
    }
  }

  /// Check if current user has specific permission
  Future<bool> _hasPermission(String permission) async {
    if (_auth.currentUser == null) return false;

    try {
      final adminDoc = await _firestore
          .collection('admin_users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (adminDoc.exists) {
        final permissions = List<String>.from(adminDoc.data()!['permissions'] ?? []);
        return permissions.contains(permission) || permissions.contains('system_admin');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error checking permissions: $e');
      return false;
    }
  }

  /// Get all admin users (for super admins only)
  Future<List<AdminUserData>> getAllAdminUsers() async {
    try {
      if (!await _hasPermission('system_admin')) {
        return [];
      }

      final snapshot = await _firestore.collection('admin_users').get();
      return snapshot.docs
          .map((doc) => AdminUserData.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting admin users: $e');
      return [];
    }
  }
}

/// Admin login result
class AdminLoginResult {
  final bool success;
  final String message;
  final User? user;
  final AdminUserData? adminData;

  AdminLoginResult({
    required this.success,
    required this.message,
    this.user,
    this.adminData,
  });
}

/// Admin creation result
class AdminCreateResult {
  final bool success;
  final String message;
  final String? userId;

  AdminCreateResult({
    required this.success,
    required this.message,
    this.userId,
  });
}

/// Admin user data model
class AdminUserData {
  final String email;
  final String name;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final List<String> permissions;

  AdminUserData({
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
    this.lastLogin,
    required this.isActive,
    required this.permissions,
  });

  factory AdminUserData.fromMap(Map<String, dynamic> map) {
    return AdminUserData(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      lastLogin: map['lastLogin']?.toDate(),
      isActive: map['isActive'] ?? false,
      permissions: List<String>.from(map['permissions'] ?? []),
    );
  }
}
