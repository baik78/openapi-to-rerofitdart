## Oretgen 

A small dart library to generate [retrofit](https://pub.dev/packages/retrofit) skeleton from
open api yaml file with generated models.

A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`. To build use command
```
dart2native bin/main.dart -o bin/oretgen
```

If You have open api file, You can generate retrofit 
```
bin/oretgen -p full path to yaml file  -o full path tooutput directory for models
```
You can use common yaml open api file with slitted files. But it is necessary 
all file are in the same directory. Use flag 'multiple'
```
bin/oretgen -p full path to yaml file  -o full path tooutput directory for models --multiple
```

### Example
In example folder You can find test files.
Use command 
```
./bin/oretgen -p  $(pwd)/example/test.yaml -o $(pwd)/example
```

### Warning
This is alpha version. And may be have errors.
Generator makes objects only from components/scheme 


## License
Copyright © 2020 
Licensed under [license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

