import 'package:bloc/bloc.dart';
import '../data/library_repository.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryRepository repository;

  LibraryBloc({required this.repository}) : super(const LibraryState()) {
    on<LibraryStarted>(_onStarted);
    on<LibraryRefreshed>(_onRefreshed);
    on<LibraryTabChanged>(_onTabChanged);
    on<LibraryCharacterOpened>(
      (event, emit) => emit(state.copyWith(selectedCharacter: event.character)),
    );
    on<LibraryCharacterClosed>(
      (event, emit) => emit(state.copyWith(clearSelectedCharacter: true)),
    );
  }

  Future<void> _onStarted(
    LibraryStarted event,
    Emitter<LibraryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LibraryStatus.loading,
        modsPath: event.modsPath,
        downloadPath: event.downloadPath,
      ),
    );
    await _sync(emit);
  }

  Future<void> _onRefreshed(
    LibraryRefreshed event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(status: LibraryStatus.loading));
    await _sync(emit);
  }

  Future<void> _onTabChanged(
    LibraryTabChanged event,
    Emitter<LibraryState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedTab: event.index,
        clearSelectedCharacter: true,
        archiveCounts: const {},
        modFolderStatuses: const {},
      ),
    );
    final rootPath = event.index == 0 ? state.modsPath : state.downloadPath;
    final counts = await repository.scanArchiveCounts(rootPath);
    final modFolderStatuses = event.index == 0
        ? await repository.scanModFolderStatuses(rootPath)
        : const <String, ModFolderStatus>{};
    if (state.selectedTab == event.index) {
      emit(
        state.copyWith(
          archiveCounts: counts,
          modFolderStatuses: modFolderStatuses,
        ),
      );
    }
  }

  Future<void> _sync(Emitter<LibraryState> emit) async {
    try {
      await repository
          .ensureCharacterFolders(state.modsPath, state.downloadPath)
          .timeout(const Duration(seconds: 8));
      final rootPath = state.selectedTab == 0
          ? state.modsPath
          : state.downloadPath;
      final characters = await repository.scanSkinFoldersAt(rootPath);
      final archiveCounts = await repository.scanArchiveCounts(rootPath);
      final modFolderStatuses = state.selectedTab == 0
          ? await repository.scanModFolderStatuses(rootPath)
          : const <String, ModFolderStatus>{};
      emit(
        state.copyWith(
          status: LibraryStatus.ready,
          characters: characters,
          archiveCounts: archiveCounts,
          modFolderStatuses: modFolderStatuses,
        ),
      );
    } catch (error) {
      final rootPath = state.selectedTab == 0
          ? state.modsPath
          : state.downloadPath;
      final characters = await repository.scanSkinFoldersAt(rootPath);
      final archiveCounts = await repository.scanArchiveCounts(rootPath);
      final modFolderStatuses = state.selectedTab == 0
          ? await repository.scanModFolderStatuses(rootPath)
          : const <String, ModFolderStatus>{};
      emit(
        state.copyWith(
          status: LibraryStatus.ready,
          characters: characters,
          archiveCounts: archiveCounts,
          modFolderStatuses: modFolderStatuses,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
