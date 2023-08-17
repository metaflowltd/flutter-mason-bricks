import 'package:get_it/get_it.dart';
import 'package:lumen_client_core/lumen_client_core.dart';{{#contains_routes}}
import 'package:prism_flutter_go_router/prism_flutter_go_router.dart';
import 'package:prism_flutter_go_router/interfaces/module_route.dart';{{/contains_routes}}{{^contains_routes}}
import 'package:prism_flutter_getit/prism_flutter_getit.dart';{{/contains_routes}}{{#needs_configuration_service}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/services/{{name.snakeCase()}}_configuration_service.dart';{{/needs_configuration_service}}{{#has_repository}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/services/{{name.snakeCase()}}_repository.dart';{{/has_repository}}

class {{name.pascalCase()}}Module extends {{#contains_routes}}GoRouterModule{{/contains_routes}}{{^contains_routes}}GetItModule{{/contains_routes}} implements ModuleMetadata { {{#contains_routes}}
  @override
  List<ModuleRoute> configureRoutes() => [
        //TODO fill this list with module routes
      ];
{{/contains_routes}}
  @override
  Future<void> init(GetIt container) async {
    //TODO initialize module's services here{{#has_repository}}
    container.registerLazySingleton(() => {{name.pascalCase()}}Repository());{{/has_repository}}{{#needs_configuration_service}}
    container.registerLazySingleton(() => {{name.pascalCase()}}ConfigurationService(
          configurationService: container<ConfigurationService>(),
          cache: ConfigurationCache<{{configurationModelName.pascalCase()}}>(),
        ));{{/needs_configuration_service}}
  }

  @override
  int get level => {{level}};

  @override
  bool get continueOnException => {{continue_on_exception}};

  @override
  bool get allowReinit => {{allow_reinit}};
}
