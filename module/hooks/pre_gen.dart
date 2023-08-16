import 'dart:io';

import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

Future run(HookContext context) async {
  final logger = context.logger;
  final helper = _Helper(context);

  final directory = Directory.current.path;
  try {
    final (packageName, modulePath) = await helper.retrievePaths();

    final needsConfigurationService = context.vars['needs_configuration_service'];
    final hasServices = context.vars['has_repository'] || needsConfigurationService;

    final String? configurationModelName;
    if (needsConfigurationService) {
      configurationModelName = context.logger.prompt(
        'Pick name for configuration model class',
        defaultValue: "${context.vars['name'].toString().pascalCase}Configuration",
      );
    } else {
      configurationModelName = null;
    }

    context.vars = {
      ...context.vars,
      'fullPath': ('$packageName/$modulePath').replaceAll('//', '/'),
      'hasServices': hasServices,
      'configurationModelName': configurationModelName,
    };
  } on RangeError catch (_) {
    logger.alert(red.wrap('Could not find lib folder in $directory'));
    logger.alert(red.wrap('Re-run this brick inside your lib folder'));
    throw Exception();
  } on FileSystemException catch (e, s) {
    logger.alert(red.wrap('$e $s Could not find pubspec.yaml folder in ${directory.replaceAll('\\lib', '')}'));
    throw Exception();
  } on PubspecNameException catch (_) {
    logger.alert(red.wrap('Could not read package name in pubspec.yaml}'));
    logger.alert(red.wrap('Does your pubspec have a name: ?'));
    throw Exception();
  } on Exception catch (e) {
    throw e;
  }
}

class _Helper {
  final HookContext context;

  _Helper(this.context);

  Future<(String, String)> retrievePaths() async {
    final directory = Directory.current.path;
    List<String> folders;

    if (Platform.isWindows) {
      folders = directory.split(r'\').toList();
    } else {
      folders = directory.split('/').toList();
    }
    final libIndex = folders.indexWhere((folder) => folder == 'lib');
    final modulePath = folders.sublist(libIndex + 1, folders.length).join('/');
    final pubSpecFile = File('${folders.sublist(0, libIndex).join('/')}/pubspec.yaml');
    final content = await pubSpecFile.readAsString();
    final yamlMap = loadYaml(content);
    final packageName = yamlMap['name'];

    if (packageName is! String) {
      throw PubspecNameException();
    }

    return (packageName, modulePath);
  }
}

class PubspecNameException implements Exception {}

extension on FileSystemEntity {
  String get name => this.path.split(Platform.pathSeparator).last;
}
