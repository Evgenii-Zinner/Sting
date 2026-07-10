import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart tools/generate_components.dart <schema.json> [output.dart]');
    exit(1);
  }

  final schemaFile = File(args[0]);
  if (!schemaFile.existsSync()) {
    print('Error: Schema file not found.');
    exit(1);
  }

  final schemaJson = jsonDecode(schemaFile.readAsStringSync());

  final schemas = schemaJson is List ? schemaJson : [schemaJson];

  final buffer = StringBuffer();
  buffer.writeln("import 'dart:typed_data';");
  buffer.writeln();

  for (var i = 0; i < schemas.length; i++) {
    buffer.write(generateComponentCode(schemas[i] as Map<String, dynamic>));
    if (i < schemas.length - 1) {
      buffer.writeln();
    }
  }

  if (args.length > 1) {
    File(args[1]).writeAsStringSync(buffer.toString());
    print('Wrote to ${args[1]}');
  } else {
    print(buffer.toString());
  }
}

String generateComponentCode(Map<String, dynamic> schema) {
  final name = schema['name'] as String;
  final backingType = schema['type'] as String;
  final fields = schema['fields'] as List<dynamic>;

  final buffer = StringBuffer();

  if (schema.containsKey('description')) {
    buffer.writeln("/// ${schema['description']}");
  }

  buffer.writeln("extension type $name($backingType data) {");

  if (backingType == 'ByteData') {
    _generateByteDataMethods(name, fields, buffer);
  } else {
    _generateTypedDataMethods(name, backingType, fields, buffer);
  }

  buffer.writeln("}");

  return buffer.toString();
}

void _generateTypedDataMethods(String name, String backingType, List<dynamic> fields, StringBuffer buffer) {
  final fieldType = (backingType == 'Float32List' || backingType == 'Float64List') ? 'double' : 'int';

  final paramSet = <String>{};
  final paramsList = <String>[];

  for (var field in fields) {
    final initFrom = field['init_from'] as String?;
    if (initFrom != null) {
      if (!paramSet.contains(initFrom)) {
        paramSet.add(initFrom);
        paramsList.add(initFrom);
      }
    } else {
      if (!paramSet.contains(field['name'])) {
        paramSet.add(field['name']);
        paramsList.add(field['name'] as String);
      }
    }
  }

  final constructorParams = paramsList.map((p) => "$fieldType $p").join(', ');

  buffer.writeln("  $name.create($constructorParams)");
  buffer.write("      : this($backingType(${fields.length})");

  for (var i = 0; i < fields.length; i++) {
    final fieldName = fields[i]['name'] as String;
    final initFrom = fields[i]['init_from'] as String? ?? fieldName;
    buffer.writeln();
    buffer.write("          ..[$i] = $initFrom");
  }
  buffer.writeln(");");

  for (var i = 0; i < fields.length; i++) {
    final fieldName = fields[i]['name'] as String;
    buffer.writeln();
    buffer.writeln("  $fieldType get $fieldName => data[$i];");
    buffer.writeln("  set $fieldName($fieldType value) => data[$i] = value;");
  }
}

void _generateByteDataMethods(String name, List<dynamic> fields, StringBuffer buffer) {
  final paramsList = <String>[];
  final paramSet = <String>{};
  final initMap = <String, String>{};
  final offsetMap = <String, int>{};

  int currentOffset = 0;

  for (var field in fields) {
    final fieldName = field['name'] as String;
    final fieldTypeStr = field['field_type'] as String;
    final initFrom = field['init_from'] as String? ?? fieldName;
    initMap[fieldName] = initFrom;
    offsetMap[fieldName] = currentOffset;

    String dartType;
    if (fieldTypeStr.startsWith('Float')) {
      dartType = 'double';
    } else {
      dartType = 'int';
    }

    if (!paramSet.contains(initFrom)) {
      paramSet.add(initFrom);
      paramsList.add("$dartType $initFrom");
    }

    int size = 4;
    if (fieldTypeStr.contains('64')) size = 8;
    else if (fieldTypeStr.contains('32')) size = 4;
    else if (fieldTypeStr.contains('16')) size = 2;
    else if (fieldTypeStr.contains('8')) size = 1;

    currentOffset += size;
  }

  final int totalBytes = currentOffset;

  final constructorParams = paramsList.join(', ');

  buffer.writeln("  $name.create($constructorParams)");
  buffer.write("      : this(ByteData($totalBytes)");

  for (var field in fields) {
    final fieldName = field['name'] as String;
    final fieldTypeStr = field['field_type'] as String;
    final offset = offsetMap[fieldName];
    final initFrom = initMap[fieldName];
    buffer.writeln();
    buffer.write("          ..set$fieldTypeStr($offset, $initFrom)");
  }
  buffer.writeln(");");

  for (var field in fields) {
    final fieldName = field['name'] as String;
    final fieldTypeStr = field['field_type'] as String;
    final offset = offsetMap[fieldName];
    String dartType = fieldTypeStr.startsWith('Float') ? 'double' : 'int';

    buffer.writeln();
    buffer.writeln("  $dartType get $fieldName => data.get$fieldTypeStr($offset);");
    buffer.writeln("  set $fieldName($dartType value) => data.set$fieldTypeStr($offset, value);");
  }
}
