// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_cli/ffmpeg_cli.dart';

/// Uses an [FfmpegBuilder] to create an [FfmpegCommand], then
/// runs the [FfmpegCommand] to render a video.
void main() async {
  final commandBuilder = FfmpegBuilder();

  final butterflyStream = commandBuilder.addAsset(
      "C:\\Users\\remco\\Documents\\GitHub\\ffmpeg_cli\\example\\assets\\Butterfly-209.mp4");
  final beeStream = commandBuilder.addAsset(
      "C:\\Users\\remco\\Documents\\GitHub\\ffmpeg_cli\\example\\assets\\bee.mp4");
  final outputStream =
      commandBuilder.createStream(hasVideo: true, hasAudio: true);

  commandBuilder.addFilterChain(
    // We combine the two example videos into one, by using a
    // "concat" filter.
    FilterChain(
      inputs: [
        // The inputs into the "concat" filter are the input IDs
        // for the source videos that FFMPEG generated.
        butterflyStream,
        beeStream,
      ],
      filters: [
        // Combine the two source videos, one after the other, by
        // using the "concat" filter.
        ConcatFilter(
          segmentCount: 2,
          outputVideoStreamCount: 1,
          outputAudioStreamCount: 1,
        ),
      ],
      outputs: [
        // This "concat" filter will produce a video stream and an
        // audio stream. Here, we give those streams IDs so that we
        // can pass them into other FilterChains, or map them to the
        // output file.
        outputStream,
      ],
    ),
  );

  final cliCommand = commandBuilder.build(
    args: [
      // Set the FFMPEG log level.
      CliArg.logLevel(LogLevel.info),
      // Map the final stream IDs from the filter graph to
      // the output file.
      CliArg(name: 'map', value: outputStream.videoId!),
      CliArg(name: 'map', value: outputStream.audioId!),
      const CliArg(name: 'vsync', value: '2'),
    ],
    outputFilepath: "C:\\Users\\remco\\Desktop\\test_render.mp4",
  );

  print('');
  print('Expected command input: ');
  print(cliCommand.expectedCliInput());
  print('');

  // Run the FFMPEG command.
  final process = await Ffmpeg().run('assets/ffmpeg', cliCommand);
  final probeProcess = await Ffprobe.run(
      'C:\\Users\\remco\\Documents\\GitHub\\ffmpeg_cli\\example\\assets\\test.mp3',
      ffprobeDir: 'assets/ffprobe');

  var audioDurationInMilliSeconds =
      probeProcess.format?.duration?.inMilliseconds;

  int staticTimeInMilliSeconds = 11580;
  double progress = 0;

  // Pipe the process output to the Dart console.
  process.stderr.transform(utf8.decoder).listen((data) {
    if (data.contains('time=')) {
      List<String> items = data.split(' ');
      String word = items.firstWhere((word) => word.contains('time='));
      List<String> trimmedTime = word.split('=');
      String time = trimmedTime[1];
      int parsedTime = parseStandardDuration(time).inMilliseconds;
      progress = (100 / staticTimeInMilliSeconds * parsedTime).roundToDouble();
      print('${progress.toString()}%');
    }
  });

  // Allow the user to respond to FFMPEG queries, such as file overwrite
  // confirmations.
  stdin.pipe(process.stdin);

  await process.exitCode;
  print('DONE');
}
