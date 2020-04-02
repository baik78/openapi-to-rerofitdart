##Oretgen 

A small dart library to generate [retrofit](https://pub.dev/packages/retrofit) skeleton from
open api yaml file. 

A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`. To build use command
```
dart2native bin/main.dart -o bin/oretgen
```

If You have open api file, You can generate retrofit 
```
bin/oretgen -p path to yaml file  -o output directory for models
```
You can use common yaml open api file with slitted files. But it is necessary 
all file are in the same directory. Use flag 'multiple'
```
bin/oretgen -p path to yaml file  -o output directory for models --multiple
```

## License
Copyright © 2020 
Licensed under [license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

