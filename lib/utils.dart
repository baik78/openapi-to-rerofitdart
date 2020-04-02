import 'package:yaml/yaml.dart';
import 'dart:io';

Future<Map<String, dynamic>> parseYaml(String path) async {
  // ignore: omit_local_variable_types
  String data = await File(path).readAsString();
  return await (loadYaml(data) as YamlMap).cast();
}

String makePath(String source, String ref) {
  final items = ref.split('/');
  var buf = StringBuffer();
  if(source != null) buf.write(source);
  buf.write('/');
  for(var i in items) {
    if(i.contains('#')) {
      buf.write(i.substring(0, i.length - 1));
      break;
    }else{
      buf.write(i);
      buf.write('/');
    }
  }
  return '$buf';
}
