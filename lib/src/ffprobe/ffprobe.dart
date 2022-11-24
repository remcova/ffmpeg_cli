import 'dart:convert';
import 'dart:io';

import 'ffprobe_json.dart';

/// The `ffprobe` command in Dart.
///
/// `ffprobe` is a CLI tool that's used for inspecting video and audio files.
/// The `ffprobe` tool can be used, for example, to determine the types of
/// streams in a video file, a video's codec, or a video's duration.
class Ffprobe {
  /// Runs the FFMPEG `ffprobe` CLI command against the given [filepath].
  static Future<FfprobeResult> run(
    String filepath, {
    String? ffprobeDir,
  }) async {
    final result = await Process.run(
        'ffprobe.exe',
        [
          '-v',
          'error', // or: error
          '-hide_banner',
          '-print_format',
          'json',
          '-show_format',
          '-show_streams',
          '-show_chapters',
          filepath,
        ],
        workingDirectory: ffprobeDir);

    if (result.exitCode != 0) {
      print('Failed to run ffprobe for "$filepath"');
      throw Exception(
          'ffprobe returned error: ${result.exitCode}\n${result.stderr}');
    }

    if (result.stdout == null ||
        result.stdout is! String ||
        (result.stdout as String).isEmpty) {
      throw Exception('ffprobe did not output expected data: ${result.stdout}');
    }

    final json = jsonDecode(result.stdout);
    return FfprobeResult.fromJson(json);
  }
}
