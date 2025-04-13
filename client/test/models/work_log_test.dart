import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([DocumentSnapshot])
import 'work_log_test.mocks.dart';

void main() {
  group('WorkLog Model Tests', () {
    // テスト用のデータ
    const testId = 'test-id';
    const testHouseWorkId = 'house-work-1';
    final testCompletedAt = DateTime(2023, 1, 2);
    const testCompletedBy = 'user-2';
    const testNote = 'これはテスト用のメモです';

    test('WorkLogモデルが正しく作成されること', () {
      final workLog = WorkLog(
        id: testId,
        houseWorkId: testHouseWorkId,
        completedAt: testCompletedAt,
        completedBy: testCompletedBy,
        note: testNote,
      );

      expect(workLog.id, equals(testId));
      expect(workLog.houseWorkId, equals(testHouseWorkId));
      expect(workLog.completedAt, equals(testCompletedAt));
      expect(workLog.completedBy, equals(testCompletedBy));
      expect(workLog.note, equals(testNote));
    });

    test('デフォルト値が正しく設定されること', () {
      final workLog = WorkLog(
        id: testId,
        houseWorkId: testHouseWorkId,
        completedAt: testCompletedAt,
        completedBy: testCompletedBy,
      );

      expect(workLog.note, isNull); // デフォルト値のテスト
    });

    test('toFirestore()が正しいMapを返すこと', () {
      final workLog = WorkLog(
        id: testId,
        houseWorkId: testHouseWorkId,
        completedAt: testCompletedAt,
        completedBy: testCompletedBy,
        note: testNote,
      );

      final firestoreMap = workLog.toFirestore();

      expect(firestoreMap['houseWorkId'], equals(testHouseWorkId));
      expect(firestoreMap['completedBy'], equals(testCompletedBy));
      expect(firestoreMap['note'], equals(testNote));
      expect(firestoreMap['completedAt'], isA<Timestamp>());
    });

    test('fromFirestore()が正しくWorkLogオブジェクトを作成すること', () {
      // Firestoreのドキュメントスナップショットをモック
      final mockData = {
        'houseWorkId': testHouseWorkId,
        'completedAt': Timestamp.fromDate(testCompletedAt),
        'completedBy': testCompletedBy,
        'note': testNote,
      };

      final mockDocSnapshot = MockDocumentSnapshot();
      when(mockDocSnapshot.id).thenReturn(testId);
      when(mockDocSnapshot.data()).thenReturn(mockData);

      final workLog = WorkLog.fromFirestore(mockDocSnapshot);

      expect(workLog.id, equals(testId));
      expect(workLog.houseWorkId, equals(testHouseWorkId));
      expect(workLog.completedAt, equals(testCompletedAt));
      expect(workLog.completedBy, equals(testCompletedBy));
      expect(workLog.note, equals(testNote));
    });

    test('fromFirestore()が欠損データに対してデフォルト値を設定すること', () {
      // 一部のフィールドが欠けているデータ
      final mockIncompleteData = {
        'houseWorkId': testHouseWorkId,
        'completedAt': Timestamp.fromDate(testCompletedAt),
        'completedBy': testCompletedBy,
      };

      final mockDocSnapshot = MockDocumentSnapshot();
      when(mockDocSnapshot.id).thenReturn(testId);
      when(mockDocSnapshot.data()).thenReturn(mockIncompleteData);

      final workLog = WorkLog.fromFirestore(mockDocSnapshot);

      expect(workLog.id, equals(testId));
      expect(workLog.houseWorkId, equals(testHouseWorkId));
      expect(workLog.completedAt, equals(testCompletedAt));
      expect(workLog.completedBy, equals(testCompletedBy));
      expect(workLog.note, isNull);
    });
  });
}
