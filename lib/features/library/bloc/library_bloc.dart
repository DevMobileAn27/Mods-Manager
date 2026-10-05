import 'package:bloc/bloc.dart';
import '../data/library_repository.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryRepository repository;

  LibraryBloc({required this.repository}) : super(const LibraryState()) {
    on<LibraryStarted>(_onStarted);
    on<LibraryRefreshed>(_onRefreshed);
    on<LibraryTabChanged>(
      (event, emit) => emit(
        state.copyWith(selectedTab: event.index, clearSelectedCharacter: true),
      ),
    );
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

  Future<void> _sync(Emitter<LibraryState> emit) async {
    try {
      await repository
          .ensureCharacterFolders(state.modsPath, state.downloadPath)
          .timeout(const Duration(seconds: 8));
      final characters = await repository.scanSkinFolders(
        state.modsPath,
        state.downloadPath,
      );
      emit(state.copyWith(status: LibraryStatus.ready, characters: characters));
    } catch (error) {
      final characters = await repository.scanSkinFolders(
        state.modsPath,
        state.downloadPath,
      );
      emit(
        state.copyWith(
          status: LibraryStatus.ready,
          characters: characters,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
