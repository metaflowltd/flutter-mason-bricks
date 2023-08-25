import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumen_client_core/lumen_client_core.dart';
import 'package:{{{fullPath}}}/routes/{{metadata_file_name}}';
import 'package:{{{fullPath}}}/ui/screens/{{name.snakeCase()}}/{{name.snakeCase()}}_bloc.dart';
import 'package:{{{fullPath}}}/ui/screens/{{name.snakeCase()}}/{{name.snakeCase()}}_screen.dart';

class {{name.pascalCase()}}Route extends LumenScreenRoute {
  const {{name.pascalCase()}}Route();

  @override
  Widget buildScreen(BuildContext context, arguments) => BlocProvider(
        create: (ctx) => {{name.pascalCase()}}Bloc(),
        child: const {{name.pascalCase()}}Screen(),
      );

  @override
  String get screenPath => "/{{name.camelCase()}}";

  @override
  RouteAnalyticsData get analyticsData => RouteAnalyticsData(
        domain: {{analytics_domain_const}},{{#has_subdomain}}
        subDomain: {{analytics_subdomain_const}},{{/has_subdomain}}
      );
}
