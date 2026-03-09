import 'dart:io';
import 'dart:convert';

/// Generator for converting JSON schemas to Hive model classes
class DbGenerator {
  static const String jsonModelsDir = 'json_models';
  static const String generatedDir = 'generated';

  /// Main entry point for the generator
  static Future<void> main() async {
    print('🚀 Starting JSON to Hive Model Generator...\n');
    print('📍 Current working directory: ${Directory.current.path}\n');

    try {
      // Ensure generated directory exists
      await _ensureGeneratedDirExists();

      // Get all JSON schema files
      final jsonFiles = await _getJsonFiles();

      if (jsonFiles.isEmpty) {
        print('⚠️  No JSON schema files found in $jsonModelsDir/');
        return;
      }

      print('📁 Found ${jsonFiles.length} schema file(s):\n');

      // Collect all schemas
      final schemas = await _collectAllSchemas(jsonFiles);

      print('📋 Collected ${schemas.length} schema(s):\n');
      for (final table in schemas.keys) {
        print('  → $table');
      }

      // Process each main schema
      for (final schema in schemas.values) {
        final table = schema['table'] as String;
        if (table.isNotEmpty && table[0].toUpperCase() == table[0])
          continue; // Skip nested schemas
        await _processSchema(schema, schemas);
      }

      print('\n✅ Model generation completed!\n');
    } catch (e) {
      print('❌ Error: $e');
      exit(1);
    }
  }

  /// Ensures the generated directory exists
  static Future<void> _ensureGeneratedDirExists() async {
    final dir = Directory(generatedDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('📂 Created $generatedDir/ directory\n');
    }
  }

  /// Gets all JSON files from the json_models directory
  static Future<List<File>> _getJsonFiles() async {
    final dir = Directory(jsonModelsDir);
    if (!await dir.exists()) {
      throw 'Directory "$jsonModelsDir" does not exist';
    }

    final jsonFiles = <File>[];
    final entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        jsonFiles.add(entity);
      }
    }

    return jsonFiles;
  }

  /// Collects all schemas from JSON files
  static Future<Map<String, Map<String, dynamic>>> _collectAllSchemas(
      List<File> jsonFiles) async {
    final schemas = <String, Map<String, dynamic>>{};
    final nextTypeId = [1];

    for (final file in jsonFiles) {
      final content = await file.readAsString();
      final json = jsonDecode(content);

      if (json is Map<String, dynamic>) {
        _processSchemaJson(json, schemas, nextTypeId);
      } else if (json is List) {
        for (final item in json) {
          if (item is Map<String, dynamic>) {
            _processSchemaJson(item, schemas, nextTypeId);
          }
        }
      } else {
        throw 'Invalid JSON format in ${file.path}. Expected Map or List.';
      }
    }

    return schemas;
  }

  static void _processSchemaJson(Map<String, dynamic> json,
      Map<String, Map<String, dynamic>> schemas, List<int> nextTypeId) {
    final table = json['table'] as String;
    if (!json.containsKey('typeId')) {
      json['typeId'] = nextTypeId[0]++;
    } else {
      // if schema supplied its own typeId, make sure future ids don't clash
      final provided = json['typeId'] as int;
      if (provided >= nextTypeId[0]) {
        nextTypeId[0] = provided + 1;
      }
    }
    schemas[table] = json;
    _extractNestedSchemas(json, schemas, nextTypeId);
  }

  static void _extractNestedSchemas(Map<String, dynamic> schema,
      Map<String, Map<String, dynamic>> schemas, List<int> nextTypeId) {
    final fields = schema['fields'] as Map<String, dynamic>;
    _scanFieldsForNested(fields, schemas, nextTypeId);
  }

  static void _scanFieldsForNested(Map<String, dynamic> fields,
      Map<String, Map<String, dynamic>> schemas, List<int> nextTypeId) {
    for (final field in fields.values) {
      if (field is Map<String, dynamic>) {
        // handle inline object definitions
        if (field['type'] == 'object' && field.containsKey('fields')) {
          final model = field['model'] as String;
          final nestedFields = field['fields'] as Map<String, dynamic>;
          final nestedSchema = {
            'table': model,
            'typeId': nextTypeId[0]++,
            'fields': nestedFields,
          };
          schemas[model.toLowerCase()] = nestedSchema;
          _scanFieldsForNested(nestedFields, schemas, nextTypeId);
        }

        // handle lists with inline object definitions
        else if (field['type'] == 'list' && field.containsKey('fields')) {
          final model = field['model'] as String;
          final nestedFields = field['fields'] as Map<String, dynamic>;
          final nestedSchema = {
            'table': model,
            'typeId': nextTypeId[0]++,
            'fields': nestedFields,
          };
          schemas[model.toLowerCase()] = nestedSchema;
          _scanFieldsForNested(nestedFields, schemas, nextTypeId);
        }
      }
    }
  }

  /// Processes a single schema
  static Future<void> _processSchema(Map<String, dynamic> schema,
      Map<String, Map<String, dynamic>> allSchemas) async {
    final tableName = schema['table'] as String;
    final relatedSchemas = _getRelatedSchemas(schema, allSchemas);

    // Generate all models
    final modelCodes = <String>[];
    final adapterCodes = <String>[];
    for (final relSchema in relatedSchemas.values) {
      final relTable = relSchema['table'] as String;
      final relTypeId = relSchema['typeId'] as int;
      final relFields =
          (relSchema['fields'] as Map).cast<String, Map<String, dynamic>>();
      final relClassName = _getClassName(relSchema);
      modelCodes.add(_generateHiveModel(relClassName, relTypeId, relFields));
      adapterCodes.add(_generateAdapter(relClassName, relTypeId, relFields));
    }

    final modelCode =
        'import \'package:hive/hive.dart\';\n\npart \'$tableName.g.dart\';\n\n' +
            modelCodes.join('\n\n');
    final adapterCode =
        'part of \'$tableName.dart\';\n\n' + adapterCodes.join('\n\n');

    final modelFile = File('$generatedDir/$tableName.dart');
    final adapterFile = File('$generatedDir/$tableName.g.dart');
    await modelFile.writeAsString(modelCode);
    await adapterFile.writeAsString(adapterCode);

    print('  ✓ Generated: ${modelFile.path} and ${adapterFile.path}');
  }

  static Map<String, Map<String, dynamic>> _getRelatedSchemas(
      Map<String, dynamic> mainSchema,
      Map<String, Map<String, dynamic>> allSchemas) {
    final related = <String, Map<String, dynamic>>{};
    final toProcess = [mainSchema['table'] as String];
    final processed = <String>{};

    while (toProcess.isNotEmpty) {
      final table = toProcess.removeAt(0);
      if (processed.contains(table)) continue;
      processed.add(table);

      final sch = allSchemas[table];
      if (sch != null) {
        related[table] = sch;
        final fields = sch['fields'] as Map<String, dynamic>;
        _findNestedTables(fields, toProcess, allSchemas);
      }
    }

    return related;
  }

  static void _findNestedTables(Map<String, dynamic> fields,
      List<String> toProcess, Map<String, Map<String, dynamic>> allSchemas) {
    for (final field in fields.values) {
      if (field is Map<String, dynamic>) {
        // object fields
        if (field['type'] == 'object' && field.containsKey('fields')) {
          final model = field['model'] as String;
          final table = model.toLowerCase();
          if (allSchemas.containsKey(table) && !toProcess.contains(table)) {
            toProcess.add(table);
          }
        }
        // list fields with nested object definition
        else if (field['type'] == 'list' && field.containsKey('fields')) {
          final model = field['model'] as String;
          final table = model.toLowerCase();
          if (allSchemas.containsKey(table) && !toProcess.contains(table)) {
            toProcess.add(table);
          }
        }
      }
    }
  }

  static String _getClassName(Map<String, dynamic> schema) {
    final table = schema['table'] as String;
    return table[0].toUpperCase() == table[0]
        ? table
        : _toPascalCase(
            table.endsWith('s') ? table.substring(0, table.length - 1) : table);
  }

  /// Generates Hive model class code
  static String _generateHiveModel(
      String className, int typeId, Map<String, Map<String, dynamic>> fields) {
    final fieldEntries = fields.entries.toList();

    // Generate field declarations
    final fieldDeclarations = StringBuffer();
    final constructorParams = StringBuffer();
    final fromJsonAssignments = StringBuffer();
    final toJsonEntries = StringBuffer();
    int fieldIndex = 0;

    for (final entry in fieldEntries) {
      final fieldName = entry.key;
      final fieldConfig = entry.value;
      final fieldType = fieldConfig['type'] as String;
      final isNullable = fieldConfig['nullable'] as bool? ?? false;
      final isRequired = fieldConfig['required'] as bool? ?? !isNullable;
      final defaultValue = fieldConfig['default'];
      final modelName = fieldConfig['model'] as String?;

      final dartType = _getDartType(fieldType, modelName, isNullable);

      // Field declaration
      fieldDeclarations.writeln('  @HiveField($fieldIndex)');
      fieldDeclarations.writeln('  final $dartType $fieldName;');
      fieldDeclarations.writeln();

      // Constructor parameter
      if (constructorParams.isNotEmpty) {
        constructorParams.write(',\n');
      }
      constructorParams.write('    ');
      if (isRequired) {
        constructorParams.write('required this.$fieldName');
      } else if (defaultValue != null) {
        constructorParams.write(
            'this.$fieldName = ${_formatDefaultValue(defaultValue, fieldType)}');
      } else {
        constructorParams.write('this.$fieldName');
      }

      // fromJson assignment
      fromJsonAssignments.writeln(
          "      $fieldName: ${_generateFromJsonValue(fieldName, fieldType, modelName, isNullable, defaultValue)},");

      // toJson entry
      if (isNullable) {
        toJsonEntries.writeln(
            "      if ($fieldName != null) '$fieldName': ${_generateToJsonValue(fieldName, fieldType, modelName, true)},");
      } else {
        toJsonEntries.writeln(
            "      '$fieldName': ${_generateToJsonValue(fieldName, fieldType, modelName, false)},");
      }

      fieldIndex++;
    }

    // Generate the complete Dart class
    final code = '''@HiveType(typeId: $typeId)
class $className extends HiveObject {

${fieldDeclarations.toString()}
  $className({
${constructorParams.toString()}
  });

  factory $className.fromJson(Map<String, dynamic> json) {
    return $className(
${fromJsonAssignments.toString().trimRight()}
    );
  }

  Map<String, dynamic> toJson() {
    return {
${toJsonEntries.toString().trimRight()}
    };
  }
}
''';

    return code;
  }

  /// Generates Hive adapter code
  static String _generateAdapter(
      String className, int typeId, Map<String, Map<String, dynamic>> fields) {
    final fieldEntries = fields.entries.toList();

    final readFields = StringBuffer();
    final writeFields = StringBuffer();
    int fieldIndex = 0;

    for (final entry in fieldEntries) {
      final fieldName = entry.key;
      final fieldConfig = entry.value;
      final fieldType = fieldConfig['type'] as String;
      final isNullable = fieldConfig['nullable'] as bool? ?? false;

      // For read
      String readStatement = '';
      final model = fieldConfig['model'] as String?;
      final fieldTypeLC = fieldType.toLowerCase();

      if (fieldTypeLC == 'list') {
        final listItemType = model ?? 'dynamic';
        readStatement =
            '$fieldName: (fields[$fieldIndex] as List?)?.cast<$listItemType>()?? <$listItemType>[]';
      } else {
        String cast = 'dynamic';
        switch (fieldTypeLC) {
          case 'int':
          case 'integer':
            cast = isNullable ? 'int?' : 'int';
            break;
          case 'double':
          case 'float':
            cast = isNullable ? 'double?' : 'double';
            break;
          case 'bool':
          case 'boolean':
            cast = isNullable ? 'bool?' : 'bool';
            break;
          case 'string':
          case 'text':
            cast = isNullable ? 'String?' : 'String';
            break;
          case 'datetime':
          case 'date':
          case 'timestamp':
            cast = isNullable ? 'DateTime?' : 'DateTime';
            break;
          case 'object':
            cast = model ?? 'dynamic';
            if (isNullable) cast += '?';
            break;
          default:
            cast = 'dynamic';
            break;
        }
        readStatement = '$fieldName: fields[$fieldIndex] as $cast';
      }

      if (readFields.isNotEmpty) readFields.write(',\n      ');
      readFields.write(readStatement);

      // For write
      writeFields.write(
          "      ..writeByte($fieldIndex)\n      ..write(obj.$fieldName)\n");

      fieldIndex++;
    }

    final adapterCode = '''// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ${className}Adapter extends TypeAdapter<$className> {
  @override
  final int typeId = $typeId;

  @override
  $className read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };

    return $className(
      ${readFields.toString()}
    );
  }

  @override
  void write(BinaryWriter writer, $className obj) {
    writer
      ..writeByte($fieldIndex)
${writeFields.toString()}    ;
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ${className}Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
''';

    return adapterCode;
  }

  /// Gets the Dart type for a field
  static String _getDartType(
      String fieldType, String? modelName, bool isNullable) {
    String baseType;
    switch (fieldType.toLowerCase()) {
      case 'int':
      case 'integer':
        baseType = 'int';
        break;
      case 'double':
      case 'float':
        baseType = 'double';
        break;
      case 'bool':
      case 'boolean':
        baseType = 'bool';
        break;
      case 'string':
      case 'text':
        baseType = 'String';
        break;
      case 'datetime':
      case 'date':
      case 'timestamp':
        baseType = 'DateTime';
        break;
      case 'object':
        baseType = modelName ?? 'dynamic';
        break;
      case 'list':
        baseType = 'List<${modelName ?? 'dynamic'}>';
        break;
      default:
        baseType = 'dynamic';
    }
    return isNullable ? '$baseType?' : baseType;
  }

  /// Formats default value for constructor
  static String _formatDefaultValue(dynamic value, String fieldType) {
    if (value is String) {
      return "'$value'";
    } else if (value is bool) {
      return value ? 'true' : 'false';
    } else {
      return value.toString();
    }
  }

  /// Generates fromJson value assignment
  static String _generateFromJsonValue(String fieldName, String fieldType,
      String? modelName, bool isNullable, dynamic defaultValue) {
    final jsonAccess = "json['$fieldName']";
    String conversion;

    switch (fieldType.toLowerCase()) {
      case 'int':
        conversion = isNullable
            ? "$jsonAccess != null ? int.tryParse($jsonAccess.toString()) : null"
            : "int.tryParse($jsonAccess.toString()) ?? 0";
        break;
      case 'double':
        conversion = isNullable
            ? "$jsonAccess != null ? double.tryParse($jsonAccess.toString()) : null"
            : "double.tryParse($jsonAccess.toString()) ?? 0.0";
        break;
      case 'bool':
        if (isNullable) {
          conversion =
              "$jsonAccess != null ? ($jsonAccess is bool ? $jsonAccess as bool : null) : null";
        } else {
          conversion =
              "$jsonAccess is bool ? $jsonAccess as bool : ${defaultValue ?? false}";
        }
        break;
      case 'string':
        conversion =
            isNullable ? "$jsonAccess?.toString()" : "$jsonAccess.toString()";
        break;
      case 'datetime':
        conversion = isNullable
            ? "$jsonAccess != null ? DateTime.parse($jsonAccess.toString()) : null"
            : "DateTime.parse($jsonAccess.toString())";
        break;
      case 'object':
        conversion = isNullable
            ? "$jsonAccess != null ? ${modelName ?? 'dynamic'}.fromJson($jsonAccess as Map<String, dynamic>) : null"
            : "${modelName ?? 'dynamic'}.fromJson($jsonAccess as Map<String, dynamic>)";
        break;
      case 'list':
        final itemConversion = modelName != null
            ? ".map((e) => $modelName.fromJson(e as Map<String, dynamic>)).toList()"
            : "";
        if (isNullable) {
          conversion =
              "$jsonAccess != null ? ($jsonAccess as List)$itemConversion : null";
        } else {
          // use null-aware operator when mapping to avoid calling map on null
          final nullAwareItemConv =
              itemConversion.isNotEmpty ? '?$itemConversion' : '';
          conversion =
              "($jsonAccess as List?)$nullAwareItemConv ?? <${modelName ?? 'dynamic'}>[]";
        }
        break;
      default:
        conversion = isNullable
            ? jsonAccess
            : "$jsonAccess ?? ${defaultValue ?? 'null'}";
    }

    return conversion;
  }

  /// Generates toJson value
  static String _generateToJsonValue(
      String fieldName, String fieldType, String? modelName, bool isNullable) {
    switch (fieldType.toLowerCase()) {
      case 'datetime':
        return isNullable
            ? "$fieldName!.toIso8601String()"
            : "$fieldName.toIso8601String()";
      case 'object':
        return isNullable ? "$fieldName!.toJson()" : "$fieldName.toJson()";
      case 'list':
        return isNullable
            ? "$fieldName!.map((e) => e.toJson()).toList()"
            : "$fieldName.map((e) => e.toJson()).toList()";
      default:
        return fieldName;
    }
  }

  /// Converts string to PascalCase (e.g., "customer_name" -> "CustomerName")
  static String _toPascalCase(String input) {
    return input
        .split(RegExp('_|-| '))
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() +
                (word.length > 1 ? word.substring(1).toLowerCase() : ''))
        .join();
  }

  /// Converts string to snake_case (e.g., "CustomerName" -> "customer_name")
  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)}_${match.group(2)}')
        .toLowerCase();
  }
}

Future<void> main() async {
  await DbGenerator.main();
}
