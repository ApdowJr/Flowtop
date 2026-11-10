import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';

void main() {
  group('ProjectEntity', () {
    final project = ProjectEntity(
      id: 'p1',
      name: 'My Project',
      ownerId: 'u1',
      workspaceId: 'ws1',
      taskIds: ['t1', 't2', 't3'],
      progress: 0.5,
    );

    test('recalculateProgress with all done tasks returns 1.0', () {
      final tasks = [
        {'status': 'done'},
        {'status': 'done'},
        {'status': 'done'},
      ];
      expect(project.recalculateProgress(tasks), equals(1.0));
    });

    test('recalculateProgress with mixed tasks returns correct ratio', () {
      final tasks = [
        {'status': 'todo'},
        {'status': 'inProgress'},
        {'status': 'done'},
      ];
      // 0 + 0.5 + 1 = 1.5 / 3 = 0.5
      expect(project.recalculateProgress(tasks), equals(0.5));
    });

    test('recalculateProgress with empty tasks returns 0.0', () {
      expect(project.recalculateProgress([]), equals(0.0));
    });

    test('recalculateProgress with all todo tasks returns 0.0', () {
      final tasks = [
        {'status': 'todo'},
        {'status': 'todo'},
        {'status': 'todo'},
      ];
      expect(project.recalculateProgress(tasks), equals(0.0));
    });

    test('recalculateProgress with all inProgress tasks returns 0.5', () {
      final tasks = [
        {'status': 'inProgress'},
        {'status': 'inProgress'},
      ];
      expect(project.recalculateProgress(tasks), equals(0.5));
    });

    test('recalculateProgress with unknown status treats as 0.0', () {
      final tasks = [
        {'status': 'done'},
        {'status': 'unknown_status'},
      ];
      expect(project.recalculateProgress(tasks), equals(0.5));
    });

    test('copyWith updates fields', () {
      final updated = project.copyWith(name: 'Renamed', progress: 0.75);
      expect(updated.name, equals('Renamed'));
      expect(updated.progress, equals(0.75));
      expect(updated.id, equals('p1'));
    });
  });
}
