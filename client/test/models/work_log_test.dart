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
    const testTitle = 'テスト作業';
    const testDescription = 'これはテスト用の作業です';
    const testIcon = '🧹';
    final testCreatedAt = DateTime(2023);
    final testCompletedAt = DateTime(2023, 1, 2);
    const testCreatedBy = 'user-1';
    const testCompletedBy = 'user-2';
    const testIsShared = true;
    const testIsRecurring = true;
    const testRecurringIntervalMs = 86400000; // 1日
    const testIsCompleted = true;
    const testPriority = 2;

    test('WorkLogモデルが正しく作成されること', () {
      final workLog = WorkLog(
        id: testId,
        title: testTitle,
        description: testDescription,
        icon: testIcon,
        createdAt: testCreatedAt,
        completedAt: testCompletedAt,
        createdBy: testCreatedBy,
        completedBy: testCompletedBy,
        isShared: testIsShared,
        isRecurring: testIsRecurring,
        recurringIntervalMs: testRecurringIntervalMs,
        isCompleted: testIsCompleted,
        priority: testPriority,
      );

      expect(workLog.id, equals(testId));
      expect(workLog.title, equals(testTitle));
      expect(workLog.description, equals(testDescription));
      expect(workLog.icon, equals(testIcon));
      expect(workLog.createdAt, equals(testCreatedAt));
      expect(workLog.completedAt, equals(testCompletedAt));
      expect(workLog.createdBy, equals(testCreatedBy));
      expect(workLog.completedBy, equals(testCompletedBy));
      expect(workLog.isShared, equals(testIsShared));
      expect(workLog.isRecurring, equals(testIsRecurring));
      expect(workLog.recurringIntervalMs, equals(testRecurringIntervalMs));
      expect(workLog.isCompleted, equals(testIsCompleted));
      expect(workLog.priority, equals(testPriority));
    });

    test('デフォルト値が正しく設定されること', () {
      final workLog = WorkLog(
        id: testId,
        title: testTitle,
        icon: testIcon,
        createdAt: testCreatedAt,
        createdBy: testCreatedBy,
        isShared: testIsShared,
        isRecurring: testIsRecurring,
      );

      expect(workLog.isCompleted, equals(false)); // デフォルト値のテスト
      expect(workLog.priority, equals(0)); // デフォルト値のテスト
    });

    test('recurringInterval getterが正しく動作すること', () {
      final workLog = WorkLog(
        id: testId,
        title: testTitle,
        icon: testIcon,
        createdAt: testCreatedAt,
        createdBy: testCreatedBy,
        isShared: testIsShared,
        isRecurring: testIsRecurring,
        recurringIntervalMs: testRecurringIntervalMs,
      );

      expect(
        workLog.recurringInterval,
        equals(const Duration(milliseconds: testRecurringIntervalMs)),
      );

      final workLogWithoutInterval = WorkLog(
        id: testId,
        title: testTitle,
        icon: testIcon,
        createdAt: testCreatedAt,
        createdBy: testCreatedBy,
        isShared: testIsShared,
        isRecurring: false,
      );

      expect(workLogWithoutInterval.recurringInterval, isNull);
    });

    test('toFirestore()が正しいMapを返すこと', () {
      final workLog = WorkLog(
        id: testId,
        title: testTitle,
        description: testDescription,
        icon: testIcon,
        createdAt: testCreatedAt,
        completedAt: testCompletedAt,
        createdBy: testCreatedBy,
        completedBy: testCompletedBy,
        isShared: testIsShared,
        isRecurring: testIsRecurring,
        recurringIntervalMs: testRecurringIntervalMs,
        isCompleted: testIsCompleted,
        priority: testPriority,
      );

      final firestoreMap = workLog.toFirestore();

      expect(firestoreMap['title'], equals(testTitle));
      expect(firestoreMap['description'], equals(testDescription));
      expect(firestoreMap['icon'], equals(testIcon));
      expect(firestoreMap['createdBy'], equals(testCreatedBy));
      expect(firestoreMap['completedBy'], equals(testCompletedBy));
      expect(firestoreMap['isShared'], equals(testIsShared));
      expect(firestoreMap['isRecurring'], equals(testIsRecurring));
      expect(
        firestoreMap['recurringIntervalMs'],
        equals(testRecurringIntervalMs),
      );
      expect(firestoreMap['isCompleted'], equals(testIsCompleted));
      expect(firestoreMap['priority'], equals(testPriority));
      expect(firestoreMap['createdAt'], isA<Timestamp>());
      expect(firestoreMap['completedAt'], isA<Timestamp>());
    });

    test('fromFirestore()が正しくWorkLogオブジェクトを作成すること', () {
      // Firestoreのドキュメントスナップショットをモック
      final mockData = {
        'title': testTitle,
        'description': testDescription,
        'icon': testIcon,
        'createdAt': Timestamp.fromDate(testCreatedAt),
        'completedAt': Timestamp.fromDate(testCompletedAt),
        'createdBy': testCreatedBy,
        'completedBy': testCompletedBy,
        'isShared': testIsShared,
        'isRecurring': testIsRecurring,
        'recurringIntervalMs': testRecurringIntervalMs,
        'isCompleted': testIsCompleted,
        'priority': testPriority,
      };

      final mockDocSnapshot = MockDocumentSnapshot();
      when(mockDocSnapshot.id).thenReturn(testId);
      when(mockDocSnapshot.data()).thenReturn(mockData);

      final workLog = WorkLog.fromFirestore(mockDocSnapshot);

      expect(workLog.id, equals(testId));
      expect(workLog.title, equals(testTitle));
      expect(workLog.description, equals(testDescription));
      expect(workLog.icon, equals(testIcon));
      expect(workLog.createdAt, equals(testCreatedAt));
      expect(workLog.completedAt, equals(testCompletedAt));
      expect(workLog.createdBy, equals(testCreatedBy));
      expect(workLog.completedBy, equals(testCompletedBy));
      expect(workLog.isShared, equals(testIsShared));
      expect(workLog.isRecurring, equals(testIsRecurring));
      expect(workLog.recurringIntervalMs, equals(testRecurringIntervalMs));
      expect(workLog.isCompleted, equals(testIsCompleted));
      expect(workLog.priority, equals(testPriority));
    });

    test('fromFirestore()が欠損データに対してデフォルト値を設定すること', () {
      // 一部のフィールドが欠けているデータ
      final mockIncompleteData = {
        'title': testTitle,
        'createdAt': Timestamp.fromDate(testCreatedAt),
        'createdBy': testCreatedBy,
      };

      final mockDocSnapshot = MockDocumentSnapshot();
      when(mockDocSnapshot.id).thenReturn(testId);
      when(mockDocSnapshot.data()).thenReturn(mockIncompleteData);

      final workLog = WorkLog.fromFirestore(mockDocSnapshot);

      expect(workLog.id, equals(testId));
      expect(workLog.title, equals(testTitle));
      expect(workLog.description, isNull);
      expect(workLog.icon, equals('🏠')); // デフォルトアイコン
      expect(workLog.createdAt, equals(testCreatedAt));
      expect(workLog.completedAt, isNull);
      expect(workLog.createdBy, equals(testCreatedBy));
      expect(workLog.completedBy, isNull);
      expect(workLog.isShared, equals(false));
      expect(workLog.isRecurring, equals(false));
      expect(workLog.recurringIntervalMs, isNull);
      expect(workLog.isCompleted, equals(false));
      expect(workLog.priority, equals(0));
    });
  });
}
