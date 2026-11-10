import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/projects/data/repositories/project_repository_impl.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';
import 'package:flowtop/features/projects/domain/repositories/project_repository.dart';
import 'package:flowtop/features/projects/presentation/providers/project_provider.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  group('ProjectProvider', () {
    late ProviderContainer container;
    late MockProjectRepository mockRepository;

    setUp(() {
      mockRepository = MockProjectRepository();
      container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('projectProvider returns data when project exists', () async {
      final project = ProjectEntity(
        id: 'p1',
        name: 'Test Project',
        ownerId: 'u1',
        workspaceId: 'ws1',
        progress: 0.5,
      );

      when(() => mockRepository.watchProject('p1')).thenAnswer(
        (_) => Stream.value(project),
      );

      await container.read(projectProvider('p1').future);
      expect(container.read(projectProvider('p1')).value, equals(project));
    });

    test('projectProvider returns null when project does not exist', () async {
      when(() => mockRepository.watchProject('missing')).thenAnswer(
        (_) => Stream.value(null),
      );

      await container.read(projectProvider('missing').future);
      expect(container.read(projectProvider('missing')).value, isNull);
    });
  });
}
