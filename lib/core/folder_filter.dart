import '../models/music_models.dart';

/// 本地音乐扫描的文件夹过滤工具。
///
/// 用户可将录音等目录加入排除列表，扫描结果中位于这些目录
/// （含子目录）下的歌曲将被过滤掉。所有比较均不区分大小写，
/// 并统一路径分隔符，避免大小写/分隔符差异导致匹配失败。
class FolderFilter {
  const FolderFilter._();

  /// 规范化文件夹路径：统一分隔符、去尾部 `/`、转小写。
  ///
  /// 空字符串或空白输入返回 `null`。
  static String? normalizeFolderPath(String? path) {
    if (path == null) return null;
    var normalized = path.trim().replaceAll('\\', '/');
    while (normalized.endsWith('/') && normalized.length > 1) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.isEmpty || normalized == '/') return null;
    return normalized.toLowerCase();
  }

  /// 取文件所在父文件夹（已规范化）。无法解析时返回 `null`。
  static String? parentFolderOf(String? filePath) {
    if (filePath == null) return null;
    final normalized = filePath.trim().replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return null;
    return normalizeFolderPath(normalized.substring(0, index));
  }

  /// 判断 [filePath] 是否位于 [folder] 目录（含其子目录）下。
  ///
  /// [folder] 会先做规范化；两者比较不区分大小写。
  static bool isPathUnderFolder(String filePath, String folder) {
    final normalizedFolder = normalizeFolderPath(folder);
    if (normalizedFolder == null) return false;
    final parent = parentFolderOf(filePath);
    if (parent == null) return false;
    return parent == normalizedFolder || parent.startsWith('$normalizedFolder/');
  }

  /// 过滤掉位于 [excludedFolders] 目录（含子目录）下的歌曲。
  static List<Song> filterSongs(
    List<Song> songs,
    Iterable<String> excludedFolders,
  ) {
    final normalized = excludedFolders
        .map(normalizeFolderPath)
        .whereType<String>()
        .toSet();
    if (normalized.isEmpty) return List<Song>.of(songs);

    return songs.where((song) {
      final parent = parentFolderOf(song.hash);
      return parent == null ||
          (!normalized.contains(parent) &&
              !normalized.any((folder) => parent.startsWith('$folder/')));
    }).toList();
  }

  /// 按父目录把歌曲分组。
  ///
  /// - 分组键为 [parentFolderOf] 的规范化结果，无父目录的歌曲归入空串分组；
  /// - 显示名取末级目录，末级为 `0`（顶层存储目录）时保留完整路径，
  ///   无父目录的歌曲显示为「其他」；
  /// - 排序：有父目录的按显示名升序，「其他」分组永远排在最后。
  static List<({String folder, String displayName, List<Song> songs})>
      groupByFolder(List<Song> songs) {
    final groups = <String, List<Song>>{};
    final names = <String, String>{};
    for (final song in songs) {
      final parent = parentFolderOf(song.hash) ?? '';
      (groups[parent] ??= <Song>[]).add(song);
      names.putIfAbsent(
        parent,
        () => parent.isEmpty ? '其他' : folderDisplayName(parent),
      );
    }
    final result = groups.entries
        .map(
          (entry) => (
            folder: entry.key,
            displayName: names[entry.key]!,
            songs: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) {
        if (a.folder.isEmpty) return 1;
        if (b.folder.isEmpty) return -1;
        final byName = a.displayName.compareTo(b.displayName);
        return byName != 0 ? byName : a.folder.compareTo(b.folder);
      });
    return result;
  }

  /// 取文件夹显示名：优先末级目录名，顶层存储目录（末级为 `0`）显示完整路径。
  static String folderDisplayName(String folder) {
    final separator = folder.contains(r'\') ? r'\' : '/';
    final segments =
        folder.split(separator).where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return folder;
    final last = segments.last;
    if (last == '0' || last == 'storage') return folder;
    return last;
  }

  /// 统计各父文件夹下的歌曲数量（按数量降序，供排除设置界面展示）。
  static List<({String folder, int count})> folderCounts(List<Song> songs) {
    final counts = <String, int>{};
    for (final song in songs) {
      final parent = parentFolderOf(song.hash);
      if (parent == null) continue;
      counts[parent] = (counts[parent] ?? 0) + 1;
    }
    final result = counts.entries
        .map((entry) => (folder: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.folder.compareTo(b.folder);
      });
    return result;
  }
}
