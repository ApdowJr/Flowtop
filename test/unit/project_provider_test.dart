import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/core/di/injection_container.dart' show selectedWorkspaceProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
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
          selectedWorkspaceProvider.overrideWith((ref) => 'ws1'),
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

      when(() => mockRepository.watchProject('ws1', 'p1')).thenAnswer(
        (_) => Stream.value(project),
      );

      await container.read(projectProvider('p1').future);
      expect(container.read(projectProvider('p1')).value, equals(project));
    });

    test('projectProvider returns null when project does not exist', () async {
      when(() => mockRepository.watchProject('ws1', 'missing')).thenAnswer(
        (_) => Stream.value(null),
      );

      await container.read(projectProvider('missing').future);
      expect(container.read(projectProvider('missing')).value, isNull);
    });
  });
}
