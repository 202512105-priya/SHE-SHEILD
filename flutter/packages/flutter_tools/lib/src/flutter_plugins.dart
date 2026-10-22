
list(APPEND FLUTTER_FFI_PLUGIN_LIST
{{#ffiPlugins}}
  {{name}}
{{/ffiPlugins}}
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory({{pluginsDir}}/${plugin}/{{os}} plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory({{pluginsDir}}/${ffi_plugin}/{{os}} plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
''';

const _dartPluginRegisterWith = r'''
      try {
        {{pluginName}}.{{dartClass}}.registerWith();
      } catch (err) {
        print(
          '`{{pluginName}}` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }
''';

// TODO(egarciad): Evaluate merging the web and non-web plugin registry templates.
// https://github.com/flutter/flutter/issues/80406
const _dartPluginRegistryForNonWebTemplate =
    '''
//
// Generated file. Do not edit.
// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.
//

// @dart = {{dar
<truncated 29838 bytes>
uginsByPlatform;
}

/// Resolves the plugins for the given [platformKey] (Dart-only or native
/// implementations).
(List<Plugin> pluginImplementations, bool hasPluginPubspecError, bool hasResolutionError)
_resolvePluginImplementationsByPlatform(
  Iterable<Plugin> plugins,
  String platformKey, {
  _PluginResolutionType pluginResolutionType = _PluginResolutionType.nativeOrDart,
}) {
  var hasPluginPubspecError = false;
  var hasResolutionError = false;

  // Key: the plugin name, value: the list of plugin candidates for the implementation of [platformKey].
  final pluginImplCandidates = <String, List<Plugin>>{};

  // Key: the plugin name, value: the plugin of the default implementation of [platformKey].
  final defaultImplementations = <String, Plugin>{};

  for (final plugin in plugins) {
    final String? error = _validatePlugin(
      plugin,
      platformKey,
      pluginResolutionType: pluginResolutionType,
    );
    if (error != null) {
      globals.printError(error);
      hasPluginPubspecError = true;
      continue;
    }
    final String? implementsPluginName = _getImplementedPlugin(
      plugin,
      platformKey,
      pluginResolutionType: pluginResolutionType,
    );
    final String? defaultImplPluginName = _getDefaultImplPlugin(
      plugin,
      platformKey,
      pluginResolutionType: pluginResolutionType,
    );

    if (defaultImplPluginName != null) {
      final Plugin? defaultPackage = plugins
          .where((Plugin plugin) => plugin.name == defaultImplPluginName)
          .firstOrNull;
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
