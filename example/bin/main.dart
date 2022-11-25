// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_cli/ffmpeg_cli.dart';

/// Uses an [FfmpegBuilder] to create an [FfmpegCommand], then
/// runs the [FfmpegCommand] to render a video.
void main() async {
  final commandBuilder = FfmpegBuilder();

  // final outputStream =
  //     commandBuilder.createStream(hasImage: true, hasAudio: true);

  // Run Ffprobe to get audio duration
  final probeProcess = await Ffprobe.run(
      'C:\\Users\\remco\\Documents\\GitHub\\ffmpeg_cli\\example\\assets\\appelsientje.mp3',
      ffprobeDir: 'assets/ffprobe');
  int? audioDurationInSeconds = probeProcess.format?.duration?.inSeconds;
  int? audioDurationInMilliSeconds =
      probeProcess.format?.duration?.inMilliseconds;

  final cliCommand = commandBuilder.build(
    args: [
      // Set the FFMPEG log level.
      // CliArg.logLevel(LogLevel.info),
      // Map the final stream IDs from the filter graph to
      // the output file.
      const CliArg(name: 'loop', value: '1'),
      const CliArg(name: 'framerate', value: '1'),
      const CliArg(
          name: 'i',
          value:
              'C:\\Users\\remco\\Documents\\GitHub\\ffmpeg_cli\\example\\assets\\lambo.jpg'), // image input
      const CliArg(
          name: 'i',
          value:
              'C:\\Users\\remco\\Documents\\GitHub\\ffmpeg_cli\\example\\assets\\appelsientje.mp3'), // audio input
      CliArg(name: 't', value: audioDurationInSeconds.toString()),
      const CliArg(name: 'c:v', value: 'libx264'),
      const CliArg(name: 'preset', value: 'ultrafast'),
      const CliArg(name: 'crf', value: '20'),
      const CliArg(name: 'tune', value: 'stillimage'),
      const CliArg(name: 'pix_fmt', value: 'yuv420p'),
      const CliArg(
          name: 'vf',
          value:
              'scale=w=1920:h=1080:force_original_aspect_ratio=1,pad=1920:1080:-1:(1080-1080)/2,setsar=1'),
    ],
    outputFilepath: "C:\\Users\\remco\\Desktop\\test_render.mp4",
  );

  print('');
  print('Expected command input: ');
  print(cliCommand.expectedCliInput());
  print('');

  // Run the FFMPEG command.
  final process = await Ffmpeg().run('assets/ffmpeg', cliCommand);

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
      progress =
          (100 / audioDurationInMilliSeconds! * parsedTime).roundToDouble();
      print('${progress.toString()}%');
    }
  });

  // Allow the user to respond to FFMPEG queries, such as file overwrite
  // confirmations.
  stdin.pipe(process.stdin);

  await process.exitCode;
  print('DONE');
}
