# redis-setne
Quick implementation of a SET command that doesn't generate spurious keyspace events.


## Abstract
Setting a string key to the same value multiple times will produce multiple keyspace events even though the key value in fact never really changed. This command prevents that from happening by first checking if the current key value matches the new one. For this reason, this command is slower than SET and should only be used if necessary.

This is the module version of what was proposed in 
	[this pull-request](https://github.com/antirez/redis/pull/4258).

## Quickstart
```
> SET mykey banana
OK
> SETNE mykey pear
OK
> SETNE mykey pear
OK
```

The first call to `SETNE` will generate a keyspace event, while the second one will **not**.
The command can also be used to create new keys or transform an existing key to a string type, exactly like `SET` does.

### SETNE supports all of SET's options
You can also use all the usual `SET` options like `EX`, `PX`, `NX`, `XX`. All arguments passed to `SETNE` get routed to `SET` if the key must have a real write happen to it (otherwise, nothing happens and none of the options has any effect).

### Asymptotic Complexity (Big O)
The command has the same overall asymptotic complexity as SET: O(1), but it does do extra work as it has to first compare input with the current value of the key, in order to know if it should perform any assignment or not.

If you want to factor string length into your complexity analysis, the worst case is O(N) when N is the string length of the argument that you are passing in. In practice, this case only triggers when both the old and new value have the same length N (otherwise we will know immediately that the two strings are not equal) and when both old and new values are exactly the same.

In general the command is very fast but still slower than plain old `SET`, so use it only if you have real need for this functionality.

## Obtaining the module
### Download precompiled binaries from GitHub
In the releases section I provide x86_64 binaries for macOS and Linux.

### Compile the code
To compile the code you need to download a copy of [the Zig compiler](https://ziglang.org).

This command will compile a dynamic library for your own architecture:
```bash
$ zig build-lib -dynamic --release-fast -isystem src src/redis-setne.zig
```

This command will cross-compile for a given target (let's say we are on macOS and want to xcompile for 64bit linux):
```bash
$ zig build-lib -dynamic --release-fast -isystem src --library c -target x86_64-linux src/redis-setne.zig
```

### Compilation notes
You must link to a libc (`--library c`) also when compiling for your own target if you're on linux.

Currently you need to use the unstable release of Zig as the latest stable release at the moment of writing (0.4.0) is missing some critical QOL changes in the way it handles C headerfiles.


## Loading the module
The recommended way is to either change `redis.conf` or pass the `--loadmodule` option when launching `redis-server`.

A quick way of testing the module without needing to restart Redis is to load it using the `MODULE LOAD` command:

```
> MODULE LOAD /absolute/path/to/libredis-setne.0.0.0.dylib
OK
> SETNE key1 banana
OK
```
Note that dynamic libraries in macOS have the `.dylib` extension while on linux it's `.so`.


## License
MIT License

Copyright (c) 2019 Loris Cro

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
