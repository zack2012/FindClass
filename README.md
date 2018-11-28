# findclass

通过Mach-O文件查找一个Objective-C类的所有子类，支持静态库和可执行文件，不支持动态库

## Uasge

对于完全组件化的工程，主工程本身不包含代码，整个工程由许多pod组成，可以通过扫描Pods文件夹来查找一个类的所有子类:  

```bash
./findclass UIView /path/to/Pods
```

扫描app的二进制文件查找一个类的所有子类:  
```bash
./findclass -d=false UIView /path/to/Binary
```