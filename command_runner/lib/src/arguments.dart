import 'dart:async';
import 'dart:collection';
import '../command_runner.dart';

enum OptionType {
  flag,
  option
}

abstract class Argument {
  String get name;
  String? get help;

  Object? get defaultValue;
  String? get valueHelp;

  String get usage;
}

class Option extends Argument {

  Option (
    this.name, {
    required this.type,
    this.help,
    this.abbr,
    this.defaultValue,
    this.valueHelp,
  });

  @override
  final String name;

  final OptionType type;

  @override
  final String? help;

  final String? abbr;

  @override
  final Object? defaultValue;

  @override
  final String? valueHelp;

  @override
  String get usage {
    if (abbr != null) {
      return '-$abbr,--$name: $help';
    }

    return '--$name: $help';
  }
}

abstract class Command extends Argument {
  @override
  String get name;

  String get description;

  bool get requiresArguments => false;

  late CommandRunner runner;

  @override
  String? help;

  @override
  String? defaultValue;

  @override
  String? valueHelp;

  final List<Option> _options = [];

  UnmodifiableSetView<Option> get options => UnmodifiableSetView(_options.toSet());

  void addFlag(
    String name,
    {
      String? help,
      String? abbr,
      String? valueHelp,
    }
  ) {
    _options.add(
      Option(
        name,
        type: OptionType.flag,
        help: help,
        abbr: abbr,
        valueHelp: valueHelp,
        defaultValue: false,
      ),
    );
  }

  void addOption(
    String name, {
    String? help,
    String? abbr,
    Object? defaultValue,
    String? valueHelp,
  }) {
    _options.add(
      Option(
        name,
        type: OptionType.option,
        help: help,
        abbr: abbr,
        defaultValue: defaultValue,
        valueHelp: valueHelp,
      ),
    );
  }

  FutureOr<Object?> run(ArgResults args);

  @override
  String get usage {
    return '$name: $description';
  }
}

class ArgResults {
  Command? command;
  String? commandArg;
  Map<Option, Object?> options = {};


  bool flag(String name) {
    for (var option in options.keys.where(
      (option) => option.type == OptionType.flag,
    )) {
      if (option.name == name) {
        return options[option] as bool;
      }
    }
    return false;
  }

  bool hasOption(String name) {
    return options.keys.any((option) => option.name == name);
  } 
  
  ({Option option, Object? input}) getOption(String name) {
    var mapEntry = options.entries.firstWhere(
      (entry) => entry.key.name == name || entry.key.abbr == name,
    );

    return (option: mapEntry.key, input: mapEntry.value);
  }
}
