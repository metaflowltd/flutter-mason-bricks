import 'package:get_it/get_it.dart';
import 'package:lumen_client_core/lumen_client_core.dart';{{#has_routes}}
import 'package:prism_flutter_go_router/prism_flutter_go_router.dart';
import 'package:prism_flutter_go_router/interfaces/module_route.dart';{{/has_routes}}{{^has_routes}}
import 'package:prism_flutter_getit/prism_flutter_getit.dart';{{/has_routes}}{{#has_services}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/domain/services/{{name.snakeCase()}}_service.dart';{{/has_services}}{{#needs_configuration_service}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/domain/services/{{name.snakeCase()}}_configuration_service.dart';{{/needs_configuration_service}}{{#has_repository}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/data/repositories/{{name.snakeCase()}}_repository.dart';{{/has_repository}}

class {{name.pascalCase()}}Module extends {{#has_routes}}GoRouterModule{{/has_routes}}{{^has_routes}}GetItModule{{/has_routes}} implements ModuleMetadata { {{#has_routes}}
  @override
  List<ModuleRoute> configureRoutes() => [
        //TODO fill this list with module routes
      ];
{{/has_routes}}
  @override
  Future<void> init(GetIt container) async {
    //TODO initialize module's services here{{#has_repository}}
    container.registerLazySingleton(() => {{name.pascalCase()}}Repository());{{/has_repository}}{{#has_services}}
    container.registerLazySingleton(() => {{name.pascalCase()}}Service());{{/has_services}}{{#needs_configuration_service}}
    container.registerLazySingleton(() => {{name.pascalCase()}}ConfigurationService(
          configurationService: container<ConfigurationService>(),
        ));{{/needs_configuration_service}}
  }

  @override
  int get level => {{level}};

  @override
  bool get continueOnException => {{continue_on_exception}};

  @override
  bool get allowReinit => {{allow_reinit}};
}
