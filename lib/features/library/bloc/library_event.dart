sealed class LibraryEvent {
  const LibraryEvent();
}

final class LibraryStarted extends LibraryEvent {
  final String modsPath;
  final String downloadPath;
  const LibraryStarted({required this.modsPath, required this.downloadPath});
}

final class LibraryRefreshed extends LibraryEvent {
  const LibraryRefreshed();
}

final class LibraryTabChanged extends LibraryEvent {
  final int index;
  const LibraryTabChanged(this.index);
}

final class LibraryCharacterOpened extends LibraryEvent {
  final String character;
  const LibraryCharacterOpened(this.character);
}

final class LibraryCharacterClosed extends LibraryEvent {
  const LibraryCharacterClosed();
}
