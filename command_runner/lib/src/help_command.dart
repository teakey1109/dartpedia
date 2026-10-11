import 'dart:async';

import 'package:command_runner/command_runner.dart';

import 'console.dart';
import 'exceptions.dart';

class HelpCommand extends Command {
  HelpCommand() {
    addFlag(
      'verbose',
      abbr: 'v',
      help: 'When true, this command will print each command and its options.',
    );
    addOption(
      'command',
      abbr: 'c',
      help:
          "When a command is passed as an argument, prints only that command's verbose usage.",
    );
  }

  @override
  String get name => 'help';

  @override
  String get description => 'Prints usage information to the command line.';

  @override
  String? get help => 'Prints this usage information';

  @override
  FutureOr<Object?> run(ArgResults args) async {
    final buffer = StringBuffer();
    buffer.writeln(runner.usage.titleText);
    if (args.flag('verbose')) {
      for (var cmd in runner.commands) {
        buffer.write(_renderCommandVerbose(cmd));
      }

      return buffer.toString();
    }

    if (args.hasOption('command')) {
      var (:option, :input) = args.getOption('command');

      var cmd = runner.commands.firstWhere(
        (command) => command.name == input,
        orElse: () {
          throw ArgumentException(
            'Input $input is not a known command.',
            name,
          );
        },
      );

      return _renderCommandVerbose(cmd);
    }

    for (var command in runner.commands) {
      buffer.writeln(command.usage);
    }

    return buffer.toString();
  }
}

String _renderCommandVerbose(Command cmd) {
  final indent = ' ' * 10;
  final buffer = StringBuffer();
  buffer.writeln(cmd.usage.instructionText); //abbr, name: description
  buffer.writeln('$indent ${cmd.help}');
  if (cmd.valueHelp != null) {
    buffer.writeln(
      '$indent [Argument] Required? ${cmd.requiresArguments}, Type: ${cmd.valueHelp}, Default: ${cmd.defaultValue ?? 'none'}',
    );
  }
  buffer.writeln('$indent Options:');
  for (var option in cmd.options) {
    buffer.writeln('$indent ${option.usage}');
  }
  return buffer.toString();
}
