import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// Storage service that enforces user-scoped upload paths.
///
/// All upload paths include the authenticated user's ID as the first path
/// segment. Storage rules verify `pathStartsWithUserId`, preventing a user
/// from uploading to another user's workspace path. Metadata documents are
/// stored in Firestore and protected by Firestore Security Rules.
class StorageRepository {
  StorageRepository({
    required FirebaseStorage storage,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _storage = storage,
       _firestore = firestore,
       _auth = auth;

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final _uuid = const Uuid();

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Upload a profile image.
  /// Path: profile_images/{userId}/{fileName}
  Future<String> uploadProfileImage(File file) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('User not authenticated');
    final fileName = '${_uuid.v4()}_${file.path.split('/').last}';
    final ref = _storage.ref().child('profile_images/$userId/$fileName');
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    // Store metadata in Firestore.
    await _firestore.collection('users').doc(userId).update({
      'photoUrl': downloadUrl,
      'photoUrlUpdatedAt': FieldValue.serverTimestamp(),
    });

    return downloadUrl;
  }

  /// Upload a task attachment.
  /// Path: task_attachments/{userId}/{workspaceId}/{taskId}/{fileName}
  Future<Map<String, dynamic>> uploadTaskAttachment({
    required File file,
    required String workspaceId,
    required String taskId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('User not authenticated');
    final fileName = '${_uuid.v4()}_${file.path.split('/').last}';
    final ref = _storage
        .ref()
        .child('task_attachments/$userId/$workspaceId/$taskId/$fileName');
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();
    final metadata = await ref.getMetadata();

    // Store attachment metadata in Firestore.
    final attachmentId = _uuid.v4();
    await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('task_attachments')
        .doc(attachmentId)
        .set({
      'attachmentId': attachmentId,
      'taskId': taskId,
      'workspaceId': workspaceId,
      'uploadedBy': userId,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'contentType': metadata.contentType,
      'size': metadata.size,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'attachmentId': attachmentId,
      'downloadUrl': downloadUrl,
      'fileName': fileName,
    };
  }

  /// Upload a project file.
  /// Path: project_files/{userId}/{workspaceId}/{projectId}/{fileName}
  Future<Map<String, dynamic>> uploadProjectFile({
    required File file,
    required String workspaceId,
    required String projectId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('User not authenticated');
    final fileName = '${_uuid.v4()}_${file.path.split('/').last}';
    final ref = _storage
        .ref()
        .child('project_files/$userId/$workspaceId/$projectId/$fileName');
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();
    final metadata = await ref.getMetadata();

    final fileId = _uuid.v4();
    await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('project_files')
        .doc(fileId)
        .set({
      'fileId': fileId,
      'projectId': projectId,
      'workspaceId': workspaceId,
      'uploadedBy': userId,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'contentType': metadata.contentType,
      'size': metadata.size,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'fileId': fileId,
      'downloadUrl': downloadUrl,
      'fileName': fileName,
    };
  }

  /// Delete a task attachment file and its metadata.
  Future<void> deleteTaskAttachment({
    required String workspaceId,
    required String taskId,
    required String attachmentId,
    required String userId,
    required String fileName,
  }) async {
    // Delete from Storage.
    final ref = _storage
        .ref()
        .child('task_attachments/$userId/$workspaceId/$taskId/$fileName');
    try {
      await ref.delete();
    } catch (_) {
      // File may not exist — continue to delete metadata.
    }

    // Delete metadata from Firestore.
    await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('task_attachments')
        .doc(attachmentId)
        .delete();
  }

  /// Delete a project file and its metadata.
  Future<void> deleteProjectFile({
    required String workspaceId,
    required String projectId,
    required String fileId,
    required String userId,
    required String fileName,
  }) async {
    final ref = _storage
        .ref()
        .child('project_files/$userId/$workspaceId/$projectId/$fileName');
    try {
      await ref.delete();
    } catch (_) {}

    await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('project_files')
        .doc(fileId)
        .delete();
  }
}
