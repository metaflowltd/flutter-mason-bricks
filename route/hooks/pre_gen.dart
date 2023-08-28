import 'dart:io';

import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

part 'route_brick_helper.dart';

Future run(HookContext context) async {
  final logger = context.logger;
  final helper = RouteBrickHelper(context);

  if (await helper.isModulesDir() == false) {
    logger.alert(red.wrap('route can be created only under modules directory'));
    throw Exception();
  }

  final directory = Directory.current.path;
  try {
    final (packageName, modulePath) = await helper.retrievePaths();
    final subdomainConst = helper.subdomainConst();

    context.vars = {
      ...context.vars,
      'fullPath': ('$packageName/$modulePath').replaceAll('//', '/'),
      'metadata_file_name': helper.metadataFile().name,
      'analytics_domain_const': helper.domainConst(),
      'has_subdomain': subdomainConst.isNotEmpty,
      'analytics_subdomain_const': subdomainConst,
    };

    helper.addRouteToModule();
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
  } on MetadataFileException catch (_) {
    logger.alert(red.wrap('Something is wrong with metadata file'));
    throw Exception();
  } on NoDomainNameException catch (_) {
    logger.alert(red.wrap('Domain name is empty and no consts in metadata file found'));
    throw Exception();
  } on Exception catch (e) {
    throw e;
  }
}

class PubspecNameException implements Exception {}

class MetadataFileException implements Exception {}

class NoDomainNameException implements Exception {}
