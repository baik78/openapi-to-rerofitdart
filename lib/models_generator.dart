import 'dart:convert';
import 'dart:io';

import 'utils.dart';
import 'package:yaml/yaml.dart';

class ModelsGenerator {
  YamlMap schemes;
  String path;
  String sourcePath;

  ModelsGenerator(this.schemes, {this.path, this.sourcePath}): assert(schemes == null);

  void generate() async {
    await Directory('$path/models').create(recursive: true);
    try {
      for (var s in schemes.keys) {
//        print('----------------');
//        print(schemes[s]);
//        print('----------------');
        await _makeScheme(s, schemes[s], schemes);
      }
    }catch(ex) {
      rethrow;
    }
  }

  Future<void> _makeScheme(String name, YamlMap data, YamlMap parent) async {
    if(data['type'] == null && data['allOf'] != null ) {
      await _makeClass(name, data, parent);
    }
    switch(data['type']) {
      case 'object':
        await _makeClass(name, data, parent);
        break;
      case 'array':
        break;
    }
  }

  Future<void> _makeClass(String name, YamlMap data, YamlMap parent) async {
    var result = StringBuffer();

    if(data['properties'] != null) {
      result.writeln(_imports(data['properties']));
      result.writeln("// Json Model $name generated!\n\n");
      result.writeln("class $name {\n");
      result.writeln(_properties(data['properties']));
      result.writeln(_fromJson(name, data['properties']));
      result.writeln(_toJson(name, data['properties']));
    }else if(data['allOf'] != null) {
      YamlList allOf = data['allOf'];
      YamlMap first = allOf.first;
      YamlMap second = allOf.last;
      YamlMap parentProps;
      YamlMap current;
      if(first.containsKey('\$ref')) {
        parentProps = await _getParentsProperties(first['\$ref'], parent);
        current = second['properties'];
      }else if(second.containsKey('\$ref')) {
        parentProps = await _getParentsProperties(second['\$ref'], parent);
        current = first['properties'];
      }
      result.writeln(_imports(current));
      Map<dynamic,dynamic> temp = Map();
      temp.addAll(current);
      temp.addAll(parentProps);
      current = YamlMap.wrap(temp);

      result.writeln("// Json Model $name generated!\n\n");
      result.writeln("class $name {\n");

      result.writeln(_properties(current));
      result.writeln(_fromJson(name, current));
      result.writeln(_toJson(name, current));
    }
    result.writeln('}');
    File("$path/models/${name.toLowerCase()}_model.dart")
      ..writeAsString('$result')
      ..createSync();
  }

  Future<YamlMap> _getParentsProperties(String model, YamlMap parent) async {
    final items = model.split('/');
    if(items.first == '#') {
      return parent[items.last]['properties'];
    }
    final filePath = makePath(sourcePath, model);
    try {
      final doc = await parseYaml(filePath);
//      print('======================');
//      print('${doc['components']['schemas']}');
//      print('======================');
      if(doc['components'] != null && doc['components']['schemas'] != null
        && doc['components']['schemas'][items.last]['properties'] != null) {
        return doc['components']['schemas'][items.last]['properties'];
      }
      return null;
    }catch(ex) {
      print("Ошибка ${ex.toString()}");
    }
    return null;
  }

  String _imports(YamlMap data) {
    if(data == null) return '';
    Set<String> imports = Set();
    for(var k in data.keys){
//      print("=========k = $k");
//      print(data[k]);
      switch(data[k]['type']) {
        case 'array':
          if(data[k]['items']['type'] != null) {
            switch(data[k]['items']['type']) {
              case 'object':
                break;
              case '\$ref':
                final items = (data[k]['items']['type']['\$ref'] as String)?.split('/');
                if(items != null) {
                  imports.add("import '${items.last.toLowerCase()}_model.dart';\n");
                }
                break;
            }
          }else if(data[k]['items']['\$ref'] != null) {
            final items = (data[k]['items']['\$ref'] as String)?.split('/');
            if(items != null) {
              imports.add("import '${items.last.toLowerCase()}_model.dart';\n");
            }
          }
          break;
        case '\$ref':
          final items = (data[k]['items']['type']['\$ref'] as String)?.split('/');
          imports.add("import '${items.last.toLowerCase()}_model.dart';\n");
          break;
      }
    }
    var result = StringBuffer();
    for(var i in imports) {
      result.write(i);
    }
    return "$result";
  }

  String _properties(YamlMap data) {
    var result = StringBuffer();
    for(var k in data.keys){
      switch(data[k]['type']) {
        case 'object':
          break;
        case 'string':
          result.writeln("\tString $k;\n");
          break;
        case 'number':
          result.writeln("\tdouble $k;\n");
          break;
        case 'integer':
          result.writeln("\tint $k;\n");
          break;
        case 'boolean':
          result.writeln("\tbool $k;\n");
          break;
        case 'array':
          if(data[k]['items']['type'] != null) {
            switch(data[k]['items']['type']) {
              case 'object':
                result.writeln("\tList<T> $k;\n");
                break;
              case '\$ref':
                final items = (data[k]['items']['type']['\$ref'] as String)?.split('/');
                if(items != null) {
                  result.writeln("\tList<${items.last}> $k;\n");
                }
                break;
            }
          }else if(data[k]['items']['\$ref'] != null) {
            final items = (data[k]['items']['\$ref'] as String)?.split('/');
            if(items != null) {
              result.writeln("\tList<${items.last}> $k;\n");
            }
          }
          break;
        case '\$ref':
          final items = (data[k]['items']['type']['\$ref'] as String)?.split('/');
          result.writeln("\t${items.last} $k;\n");
          break;
      }
    }
    return "$result";
  }

  String _fromJson(String name,YamlMap data) {
    var result = StringBuffer();
    result.writeln("\t$name.fromJson(Map<String, dynamic> map):");
    for(var k in data.keys){
      switch(data[k]['type']) {
        case 'object':
          result.writeln("\t\t$k = Object.fromJson(map[\"$k\"]),");
          break;
        case 'string':
          result.writeln("\t\t$k = map[\"$k\"],");
          break;
        case 'number':
          result.writeln("\t\t$k = map[\"$k\"],");
          break;
        case 'integer':
          result.writeln("\t\t$k = map[\"$k\"],");
          break;
        case 'boolean':
          result.writeln("\t\t$k = map[\"$k\"],");
          break;
        case 'array':
          if(data[k]['items']['type'] != null) {
            switch(data[k]['items']['type']) {
              case 'object':
                result.writeln("\t\t$k=map[\"$k\"] != null ? List<Object>.from(map[\"$k\"].map((it) => Object.fromJson(it))) : null,");
                break;
              case '\$ref':
                final items = (data[k]['items']['type']['\$ref'] as String)?.split('/');
                if(items != null) {
                  result.writeln("\t\t$k=map[\"$k\"] != null ? List<${items.last}>.from(map[\"$k\"].map((it) => ${items.last}.fromJson(it))) : null,");
                }
                break;
            }
          }
          break;
        case '\$ref':
          result.writeln("\t\t$k = $k.fromJson(map[\"$k\"]),");
          break;
      }
    }
    return "${result.toString().substring(0, result.length - 2)};\n";
  }

  String _toJson(String name, YamlMap data) {
    var result = StringBuffer();
    result.writeln("\tMap<String, dynamic> toJson() {\n");
    result.writeln("\t\tfinal Map<String, dynamic> data = new Map<String, dynamic>();\n");

    for(var k in data.keys){
      switch(data[k]['type']) {
        case 'object':
          result.writeln("\t\tdata['$k'] = $k;");
          break;
        case 'string':
          result.writeln("\t\tdata['$k'] = $k;");
          break;
        case 'number':
          result.writeln("\t\tdata['$k'] = $k;");
          break;
        case 'integer':
          result.writeln("\t\tdata['$k'] = $k;");
          break;
        case 'boolean':
          result.writeln("\t\tdata['$k'] = $k;");
          break;
        case 'array':
          result.writeln("\t\tdata['$k'] = $k != null ? $k.map((v) => v.toJson()).toList() : null;");
          break;
        case '\$ref':
          result.writeln("\t\t$k = $k.toJson();");
          break;
      }
    }
    result.writeln("\t\treturn data;");
    result.writeln("\t}");
    return "$result";
  }

}
