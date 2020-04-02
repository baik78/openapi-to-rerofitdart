import 'package:args/args.dart';
import 'package:oretgen/models_generator.dart';
import 'package:oretgen/retrofit_generator.dart';
import 'package:oretgen/utils.dart';

const pathApiDoc = 'path-api';
const modelName = 'out';
const multiple = 'multiple';

ArgResults argResultPath;
ArgResults argResultModels;

String _help() {
  StringBuffer result = StringBuffer();
  result.writeln("use ./command -p path to yaml directory -o output directory for models");
  result.writeln("parameters:");
  result.writeln("--$multiple - if you use common file with refs to other yaml files");
  return '$result';
}

void main(List<String> arguments) async {
  final parserPath = ArgParser()
    ..addFlag(pathApiDoc, negatable: false, abbr: 'p')
    ..addFlag(multiple, negatable: false)
    ..addFlag(modelName, negatable: false, abbr: 'o')
    ..addFlag('help', negatable: false, abbr: 'h');
  try {
    argResultPath = parserPath.parse(arguments);
  }catch(ex) {
    print(ex.toString());
    return;
  }

  if(argResultPath.arguments.contains('--help') || argResultPath.arguments.contains('-h') || argResultPath.arguments.isEmpty) {
    print(_help());
    return;
  }

  if(argResultPath.rest != null && argResultPath.rest.length != 2) {
    print("you need put the path '-p' and model '-o' parameters");
    return ;
  }

  var args = List.from(argResultPath.arguments);
  var rests = List.from(argResultPath.rest);
  for(var r in rests) {
    if(args.contains(r)) args.remove(r);
  }

  var yamlPathIndex = args.contains("--$pathApiDoc") ? args.indexOf("--$pathApiDoc") : args.indexOf("-p");
  var modelPathIndex = args.contains("--$modelName") ? args.indexOf("--$modelName") : args.indexOf("-o");

  String pathYaml = rests[yamlPathIndex];
  final pathModel = rests[modelPathIndex];

  try {
    final doc = await parseYaml(pathYaml);
    var items = pathYaml.split('/');
    items.removeLast();
    var dirPath = items.join("/");
    if (argResultPath.wasParsed(multiple)) {
      if(doc['paths'] != null) {
        for(var k in doc['paths'].keys) {
          if(doc['paths'][k]['\$ref'] != null) {
            final fPath = makePath(dirPath, doc['paths'][k]['\$ref']);
            final fDoc = await parseYaml(fPath);
            if(fDoc['components'] != null && fDoc['components']['schemas'] != null) {
              final generator = ModelsGenerator(fDoc['components']['schemas'],  path: pathModel, sourcePath: dirPath);
              await generator.generate();
            }
          }
        }
        final apiGenerator = RetrofitGenerator(doc['paths'],  path: pathModel, sourcePath: dirPath, multiple: true);
        await apiGenerator.generate();
      }
    }else{
      if(doc['components'] != null && doc['components']['schemas'] != null) {

        final generator = ModelsGenerator(doc['components']['schemas'],  path: pathModel, sourcePath: dirPath);
        final apiGenerator = RetrofitGenerator(doc['paths'],  path: pathModel, sourcePath: dirPath);
        try {
          await generator.generate();
          await apiGenerator.generate();
        }catch(ex) {
          print('Generation error ${ex.toString()}');
        }
      }
    }
  }catch(ex) {
    print('Parse file error ${ex.toString()}');
  }
}
