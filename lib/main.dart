import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const DomainStatusApp());
}

class DomainStatusApp extends StatelessWidget {
  const DomainStatusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domain Status Monitor',
      // Tema claro
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      // Tema oscuro
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      // Adaptación automática al sistema
      themeMode: ThemeMode.system,
      home: const DomainMonitorPage(),
    );
  }
}

class Domain {
  final String name;
  final String url;
  bool isOnline;
  DateTime lastChecked;
  int responseTime;
  String statusMessage;

  Domain({
    required this.name,
    required this.url,
    this.isOnline = false,
    DateTime? lastChecked,
    this.responseTime = 0,
    this.statusMessage = 'No verificado',
  }) : lastChecked = lastChecked ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'isOnline': isOnline,
      'lastChecked': lastChecked.toIso8601String(),
      'responseTime': responseTime,
      'statusMessage': statusMessage,
    };
  }

  factory Domain.fromJson(Map<String, dynamic> json) {
    return Domain(
      name: json['name'],
      url: json['url'],
      isOnline: json['isOnline'] ?? false,
      lastChecked: DateTime.parse(json['lastChecked']),
      responseTime: json['responseTime'] ?? 0,
      statusMessage: json['statusMessage'] ?? 'No verificado',
    );
  }
}

class DomainMonitorPage extends StatefulWidget {
  const DomainMonitorPage({super.key});

  @override
  State<DomainMonitorPage> createState() => _DomainMonitorPageState();
}

class _DomainMonitorPageState extends State<DomainMonitorPage> {
  List<Domain> domains = [];
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDomains();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkAllDomains();
    });
  }

  Future<void> _loadDomains() async {
    final prefs = await SharedPreferences.getInstance();
    final domainsJson = prefs.getStringList('domains') ?? [];

    setState(() {
      domains = domainsJson
          .map((json) => Domain.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveDomains() async {
    final prefs = await SharedPreferences.getInstance();
    final domainsJson = domains
        .map((domain) => jsonEncode(domain.toJson()))
        .toList();
    await prefs.setStringList('domains', domainsJson);
  }

  Future<void> _checkDomainStatus(Domain domain) async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse(
        domain.url.startsWith('http') ? domain.url : 'https://${domain.url}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      stopwatch.stop();

      setState(() {
        domain.isOnline =
            response.statusCode >= 200 && response.statusCode < 400;
        domain.responseTime = stopwatch.elapsedMilliseconds;
        domain.lastChecked = DateTime.now();
        domain.statusMessage = domain.isOnline
            ? 'Código: ${response.statusCode}'
            : 'Error: ${response.statusCode}';
      });
    } on TimeoutException catch (e) {
      stopwatch.stop();
      setState(() {
        domain.isOnline = false;
        domain.responseTime = stopwatch.elapsedMilliseconds;
        domain.lastChecked = DateTime.now();
        domain.statusMessage = 'Timeout: ${e.message ?? 'Sin respuesta'}';
      });
    } on SocketException catch (e) {
      stopwatch.stop();
      setState(() {
        domain.isOnline = false;
        domain.responseTime = stopwatch.elapsedMilliseconds;
        domain.lastChecked = DateTime.now();
        domain.statusMessage = 'Sin conexión: ${e.message}';
      });
    } on http.ClientException catch (e) {
      stopwatch.stop();
      setState(() {
        domain.isOnline = false;
        domain.responseTime = stopwatch.elapsedMilliseconds;
        domain.lastChecked = DateTime.now();
        domain.statusMessage = 'Error cliente: ${e.message}';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        domain.isOnline = false;
        domain.responseTime = stopwatch.elapsedMilliseconds;
        domain.lastChecked = DateTime.now();
        domain.statusMessage = 'Error: ${e.toString().substring(0, 50)}...';
      });
    }

    await _saveDomains();
  }

  Future<void> _checkAllDomains() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final futures = domains.map((domain) => _checkDomainStatus(domain));
    await Future.wait(futures);

    setState(() {
      _isLoading = false;
    });
  }

  void _showAddDomainDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Dominio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Mi Sitio Web',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com o example.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                final domain = Domain(
                  name: nameController.text.trim(),
                  url: urlController.text.trim(),
                );

                setState(() {
                  domains.add(domain);
                });

                _saveDomains();
                _checkDomainStatus(domain);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _removeDomain(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${domains[index].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                domains.removeAt(index);
              });
              _saveDomains();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Exportar dominios a un archivo JSON
  Future<void> _exportDomains() async {
    try {
      // Crear el JSON con los dominios
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Domain Status Monitor',
        'domains': domains.map((domain) => domain.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = 'dominios_${DateTime.now().millisecondsSinceEpoch}.json';

      if (Platform.isAndroid) {
        // En Android: mostrar diálogo para elegir entre guardar o compartir
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exportar dominios'),
            content: const Text('¿Cómo deseas exportar los dominios?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'save'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 18),
                    SizedBox(width: 8),
                    Text('Descargar'),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'share'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Compartir'),
                  ],
                ),
              ),
            ],
          ),
        );

        if (choice == null) return;

        if (choice == 'save') {
          // Solicitar permisos antes de guardar
          final hasPermission = await _requestStoragePermission();
          if (!hasPermission) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '⚠️ Se necesitan permisos de almacenamiento para guardar archivos',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          // Guardar en Android en la carpeta de descargas
          try {
            Directory? downloadsDirectory;

            // Intentar obtener la carpeta de descargas
            try {
              downloadsDirectory = await getExternalStorageDirectory();
              if (downloadsDirectory != null) {
                // Navegar al directorio public de Downloads
                final List<String> paths = downloadsDirectory.path.split('/');
                final int index = paths.indexOf('Android');
                if (index > 0) {
                  // Construir ruta a Downloads públicos
                  final publicPath = paths.sublist(0, index).join('/');
                  downloadsDirectory = Directory('$publicPath/Download');

                  // Verificar si existe y es accesible
                  if (!await downloadsDirectory.exists()) {
                    await downloadsDirectory.create(recursive: true);
                  }
                } else {
                  // Fallback: crear carpeta Download en el almacenamiento de la app
                  downloadsDirectory = Directory(
                    '${downloadsDirectory.path}/Download',
                  );
                  if (!await downloadsDirectory.exists()) {
                    await downloadsDirectory.create(recursive: true);
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                developer.log('Error obteniendo almacenamiento externo: $e');
              }
            }

            // Si no se puede obtener la carpeta de descargas, usar documentos externos
            if (downloadsDirectory == null) {
              try {
                downloadsDirectory = await getExternalStorageDirectory();
                if (downloadsDirectory != null) {
                  // Crear subcarpeta Download en el almacenamiento externo
                  downloadsDirectory = Directory(
                    '${downloadsDirectory.path}/Download',
                  );
                  if (!await downloadsDirectory.exists()) {
                    await downloadsDirectory.create(recursive: true);
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  developer.log('Error obteniendo almacenamiento externo: $e');
                }
              }
            }

            // Si todavía no tenemos un directorio, usar documentos de la app
            downloadsDirectory ??= await getApplicationDocumentsDirectory();

            final file = File('${downloadsDirectory.path}/$fileName');
            await file.writeAsString(jsonString);

            // Verificar si el archivo se guardó correctamente
            if (await file.exists()) {
              final fileSize = await file.length();
              final isInDownloads =
                  file.path.contains('/Download') &&
                  !file.path.contains('Android/data');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✅ ${domains.length} dominios guardados exitosamente',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Archivo: $fileName (${(fileSize / 1024).toStringAsFixed(1)} KB)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isInDownloads
                              ? '📁 Ubicación: Carpeta de descargas pública'
                              : '📁 Ubicación: ${file.parent.path.split('/').last}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 8),
                    action: SnackBarAction(
                      label: 'Compartir',
                      textColor: Colors.white,
                      onPressed: () async {
                        try {
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(file.path)],
                              text:
                                  'Respaldo de dominios - Domain Status Monitor',
                              subject: 'Respaldo de dominios',
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al compartir: $e'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              }
            } else {
              throw Exception('El archivo no se pudo crear');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️ Error al guardar archivo'),
                      const SizedBox(height: 4),
                      Text(
                        'Error: $e',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 6),
                  action: SnackBarAction(
                    label: 'Compartir en su lugar',
                    textColor: Colors.white,
                    onPressed: () async {
                      try {
                        final tempDir = await getTemporaryDirectory();
                        final tempFile = File('${tempDir.path}/$fileName');
                        await tempFile.writeAsString(jsonString);

                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(tempFile.path)],
                            text:
                                'Respaldo de dominios - Domain Status Monitor',
                            subject: 'Respaldo de dominios',
                          ),
                        );
                      } catch (shareError) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al compartir: $shareError'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            }
          }
        } else if (choice == 'share') {
          // Compartir archivo
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(jsonString);

          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: 'Respaldo de dominios - Domain Status Monitor',
              subject: 'Respaldo de dominios',
            ),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${domains.length} dominios compartidos exitosamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else if (kIsWeb || Platform.isIOS) {
        // Para iOS y web: usar share_plus (iOS no soporta bien saveFile)
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Respaldo de dominios - Domain Status Monitor',
            subject: 'Respaldo de dominios',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${domains.length} dominios exportados exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Para Linux/Windows/macOS: usar file picker para guardar
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar respaldo de dominios',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsString(jsonString);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${domains.length} dominios exportados a: ${result.split('/').last}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Importar dominios desde un archivo JSON
  Future<void> _importDomains() async {
    try {
      // Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        dialogTitle: 'Seleccionar archivo de respaldo',
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      String jsonString;

      if (result.files.single.path != null) {
        // Leer desde ruta de archivo (Linux/Windows/macOS)
        final file = File(result.files.single.path!);
        jsonString = await file.readAsString();
      } else {
        // Leer desde bytes (Web)
        final bytes = result.files.single.bytes;
        if (bytes == null) {
          throw Exception('No se pudo leer el archivo');
        }
        jsonString = String.fromCharCodes(bytes);
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validar formato
      List<dynamic> domainsData;
      if (data.containsKey('domains') && data['domains'] is List) {
        // Formato nuevo con metadatos
        domainsData = data['domains'] as List;
      } else if (jsonDecode(jsonString) is List) {
        // Formato legacy (solo array de dominios)
        domainsData = jsonDecode(jsonString) as List;
      } else {
        throw Exception('Formato de archivo inválido');
      }

      final importedDomains = domainsData
          .map((json) => Domain.fromJson(json as Map<String, dynamic>))
          .toList();

      if (importedDomains.isEmpty) {
        throw Exception('No se encontraron dominios en el archivo');
      }

      // Mostrar diálogo de confirmación
      if (!mounted) return;
      final importMode = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar importación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se encontraron ${importedDomains.length} dominios para importar.',
              ),
              if (data.containsKey('exportDate')) ...[
                const SizedBox(height: 8),
                Text(
                  'Exportado el: ${DateTime.parse(data['exportDate']).toLocal().toString().substring(0, 16)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              const Text('¿Cómo deseas proceder?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'merge'),
              child: const Text('Combinar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'replace'),
              child: const Text('Reemplazar todo'),
            ),
          ],
        ),
      );

      if (importMode == null) return;

      int importedCount = 0;
      setState(() {
        if (importMode == 'replace') {
          // Reemplazar todos los dominios
          domains = importedDomains;
          importedCount = importedDomains.length;
        } else {
          // Combinar dominios (evitar duplicados por URL)
          final existingUrls = domains.map((d) => d.url.toLowerCase()).toSet();
          final newDomains = importedDomains
              .where((d) => !existingUrls.contains(d.url.toLowerCase()))
              .toList();
          domains.addAll(newDomains);
          importedCount = newDomains.length;
        }
      });

      await _saveDomains();

      // Verificar dominios importados
      if (importedCount > 0) {
        _checkAllDomains();
      }

      if (mounted) {
        final message = importedCount > 0
            ? '$importedCount dominios importados exitosamente'
            : 'No se importaron dominios nuevos (todos ya existían)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: importedCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Función para solicitar permisos de almacenamiento
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // Para Android 13+ (API 33+) no necesitamos permisos especiales para MediaStore
      if (await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Solicitar permiso de almacenamiento
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // Si el permiso normal falla, intentar con manage external storage
      final manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error solicitando permisos: $e');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de Dominios'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _checkAllDomains,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Verificar todos',
          ),
          IconButton(
            onPressed: _exportDomains,
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar dominios',
          ),
          IconButton(
            onPressed: _importDomains,
            icon: const Icon(Icons.file_upload),
            tooltip: 'Importar dominios',
          ),
        ],
      ),
      body: domains.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.language, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay dominios agregados',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón + para agregar tu primer dominio',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: domains.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final domain = domains[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: domain.isOnline
                          ? Colors.green
                          : Colors.red,
                      child: Icon(
                        domain.isOnline ? Icons.check : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(domain.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(domain.url),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Última verificación: ${_formatTime(domain.lastChecked)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (domain.isOnline) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${domain.responseTime}ms',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _getResponseTimeColor(
                                        domain.responseTime,
                                      ),
                                    ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          domain.statusMessage,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: domain.isOnline
                                    ? Colors.green
                                    : Colors.red,
                              ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () => _checkDomainStatus(domain),
                          child: const Row(
                            children: [
                              Icon(Icons.refresh),
                              SizedBox(width: 8),
                              Text('Verificar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => _removeDomain(index),
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDomainDialog,
        tooltip: 'Agregar dominio',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace ${difference.inSeconds}s';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

  Color _getResponseTimeColor(int responseTime) {
    if (responseTime < 300) return Colors.green;
    if (responseTime < 1000) return Colors.orange;
    return Colors.red;
  }
}
