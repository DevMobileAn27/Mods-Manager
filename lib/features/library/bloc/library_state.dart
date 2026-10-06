enum LibraryStatus { initial, loading, ready, failure }

class LibraryState {
  final LibraryStatus status;
  final String modsPath;
  final String downloadPath;
  final List<String> characters;
  final Map<String, int> zipCounts;
  final Map<String, int> modFolderCounts;
  final int selectedTab;
  final String? selectedCharacter;
  final String? errorMessage;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.modsPath = '',
    this.downloadPath = '',
    this.characters = const [],
    this.zipCounts = const {},
    this.modFolderCounts = const {},
    this.selectedTab = 0,
    this.selectedCharacter,
    this.errorMessage,
  });

  LibraryState copyWith({
    LibraryStatus? status,
    String? modsPath,
    String? downloadPath,
    List<String>? characters,
    Map<String, int>? zipCounts,
    Map<String, int>? modFolderCounts,
    int? selectedTab,
    String? selectedCharacter,
    bool clearSelectedCharacter = false,
    String? errorMessage,
  }) => LibraryState(
    status: status ?? this.status,
    modsPath: modsPath ?? this.modsPath,
    downloadPath: downloadPath ?? this.downloadPath,
    characters: characters ?? this.characters,
    zipCounts: zipCounts ?? this.zipCounts,
    modFolderCounts: modFolderCounts ?? this.modFolderCounts,
    selectedTab: selectedTab ?? this.selectedTab,
    selectedCharacter: clearSelectedCharacter
        ? null
        : (selectedCharacter ?? this.selectedCharacter),
    errorMessage: errorMessage,
  );
}
