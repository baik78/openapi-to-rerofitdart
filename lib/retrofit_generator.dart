import 'dart:io';

import 'utils.dart';
import 'package:yaml/yaml.dart';


class RetrofitGenerator {
  YamlMap paths;
  String path;
  String sourcePath;
  Set<String> imports = Set();
  bool multiple;

  RetrofitGenerator(this.paths, {this.path, this.sourcePath, this.multiple = false}): assert(paths == null);


  Future<void> generate() async {
    final modelPath = '$path/models/';
    var importBody = StringBuffer();

    importBody.writeln("// Json Model RestClient generated!\n\n");
    importBody.writeln("import 'package:retrofit/retrofit.dart';");
    importBody.writeln("import 'package:dio/dio.dart';\n");

    var result = StringBuffer();
    try {
      result.writeln("part 'api.g.dart';\n");
      result.writeln("@RestApi(baseUrl: \"\")");
      result.writeln("abstract class RestClient {\n");

      if(multiple) {
        for(var k in paths.keys) {
          if(paths[k]['\$ref'] != null) {
            final fPath = makePath(sourcePath, paths[k]['\$ref']);
            final fDoc = await parseYaml(fPath);
            if(fDoc['paths'] != null) {
              for (var s in fDoc['paths'].keys) {
                final method =  await _makePath(modelPath, s, fDoc['paths'][s]);
                result.writeln(method);
              }
            }
          }
        }
      }else {
        for (var s in paths.keys) {
          final method =  await _makePath(modelPath, s, paths[s]);
          result.writeln(method);
        }
      }

      result.writeln("}\n");
      importBody.writeln(_import());
      importBody.write('$result');
      File("$path/api.dart")
        ..writeAsString('$importBody')
        ..createSync();
    }catch(ex) {
      rethrow;
    }
  }

  Future<String> _makePath(String modelPath, String methodPath, YamlMap pathInfo ) async {

    var result = StringBuffer();

    for(var k in pathInfo.keys) {
      result.write("\t${_makeMethod(k, methodPath, pathInfo[k])}");
      var respt  = await _makeResponse(pathInfo[k]);
      result.write(respt);
      result.write(pathInfo[k]['operationId']);
      var params = await _makeParams(pathInfo[k]);
      result.write(params);
    }
    return '$result';
  }

  String _import() {
    var result = StringBuffer();
    for(var obj in imports) {
      result.writeln("import 'models/${obj}_model.dart';");
    }
    return '$result';
  }

  Future<String> _makeParams(YamlMap info) async{
    var result = StringBuffer();
    result.write('(');

    if(info['parameters'] != null && info['parameters'].length != 0) {
      for(var param in info['parameters']) {
        YamlMap paramMap;
        if(param['in'] != null) {
          paramMap = param;
        }else if(param['\$ref'] != null) {
          paramMap = await _forign(param['\$ref']);
        }
//        print(param);
        switch (paramMap['in']) {
          case 'path':
            result.write('@Path() ');
            break;
          case 'query':
            result.write('@Query(\"${paramMap['name']}\") ');
            break;
        }
        if(paramMap['schema'] != null && paramMap['schema']['type'] != null) {
          switch(paramMap['schema']['type']) {
            case 'boolean':
              result.write('bool ${paramMap['name']}, ');
              break;
            case 'string':
              result.write('String ${paramMap['name']}, ');
              break;
            case 'integer':
              result.write('int ${paramMap['name']}, ');
              break;
            case 'number':
              result.write('double ${paramMap['name']}, ');
              break;
            case 'object':
              result.write('object ${paramMap['name']}, ');
              break;
          }
        }
      }
    }
    if(info['requestBody'] != null && info['requestBody']['content'] != null) {
      final firstKey = info['requestBody']['content'].keys.first;

      if (info['requestBody']['content'][firstKey]['schema'] != null
          && info['requestBody']['content'][firstKey]['schema']['\$ref'] != null) {
        final obj = (info['requestBody']['content'][firstKey]['schema']['\$ref'] as String)
            .split('/')
            .last;
        imports.add(obj.toLowerCase());
        result.write('@Body() $obj ${obj.toLowerCase()}, ');
      }
    }
    if(result.length > 2) {
      return '${result.toString().substring(0, result.length - 2)});\n';
    }
    return '$result);\n';
  }

  Future<YamlMap> _forign(String path) async {
    final filePath = makePath(sourcePath, path);

    try {
      final doc = await parseYaml(filePath);

      var items = path.split('#').last.split('/');
      if(items.isNotEmpty) items.remove(items[0]);
      imports.add(items.last.toLowerCase());
      switch(items.length) {
        case 1:
          if(doc[items[0]] != null) {
            return doc[items[0]];
          }
          break;
        case 2:
          if(doc[items[0]][items[1]] != null) {
            return doc[items[0]][items[1]];
          }
          break;
        case 3:
          if(doc[items[0]][items[1]][items[2]] != null) {
            return doc[items[0]][items[1]][items[2]];
          }
          break;
        case 4:
          if(doc[items[0]][items[1]][items[2]][items[3]] != null) {
            return doc[items[0]][items[1]][items[2]][items[3]];
          }
          break;
      }
      return null;
    }catch(ex) {
      print("Ошибка ${ex.toString()}");
    }
    return null;

  }

  Future<String> _makeResponse(YamlMap info) async{
    var result = StringBuffer();
    if(info['responses'] != null) {
      for(var k in info['responses'].keys) {
        if(k == '200' || k == '201') {
          if(info['responses'][k]['content'] != null) {
            final firstContentKey = info['responses'][k]['content'].keys.first;

            if(firstContentKey != null && info['responses'][k]['content'][firstContentKey]['schema'] != null) {
              final firstContent = info['responses'][k]['content'][firstContentKey];
              if(firstContent['schema'].keys.contains('\$ref')) {
                final items = (firstContent['schema']['\$ref'] as String).split('/');
                imports.add(items.last.toLowerCase());
                result.write('\tFuture<${items.last}> ');
              }else if(firstContent['schema'].keys.contains('object')){

              }
            }
          }else {
            result.write('\tFuture<void> ');
          }
          break;
        }
      }
    }
    if(result.length == 0) result.write('\tFuture<void> ');
    return '$result';
  }

  String _makeMethod(String methodType, String methodPath, YamlMap info) {
    var result = StringBuffer();
    switch(methodType) {
      case 'get':
        result.writeln("@GET(\"$methodPath\")");
        break;
      case 'put':
        result.writeln("@PUT(\"$methodPath\")");
        break;
      case 'post':
        result.writeln("@POST(\"$methodPath\")");
        break;
      case 'delete':
        result.writeln("@DELETE(\"$methodPath\")");
        break;
      case 'patch':
        result.writeln("@PATCH(\"$methodPath\")");
        break;
    }
    return "$result";
  }
}
