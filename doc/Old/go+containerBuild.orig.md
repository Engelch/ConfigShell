---
mainfont: DejaVuSerif.ttf
sansfont: DejaVuSans.ttf
monofont: DejaVuSansMono.ttf
mathfont: texgyredejavu-math.otf
---

# Go Compilation and Container Builds

## Info

- version 1.0.0
- --c230516

## Contents

- [Go Compilation and Container Builds](#go-compilation-and-container-builds)
  - [Info](#info)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Cloud Provider Support](#cloud-provider-support)
    - [Container Repositories Upload](#container-repositories-upload)
    - [Container Repositories Download](#container-repositories-download)
  - [Project Directory Layout](#project-directory-layout)
  - [Compilation of Go Applications](#compilation-of-go-applications)
    - [Overview](#overview)
    - [Simple Example](#simple-example)
      - [Directory/Project Setup](#directoryproject-setup)
      - [Go Initialisation](#go-initialisation)
      - [First Compilation Test](#first-compilation-test)
      - [Requirements of Version Information](#requirements-of-version-information)
      - [First Successful Compilation](#first-successful-compilation)
      - [Creating a New Version](#creating-a-new-version)
      - [Increasing Version Numbers](#increasing-version-numbers)
      - [Summary](#summary)
  - [Versioning of Applications and Services](#versioning-of-applications-and-services)
    - [synchroniseVersions of a Collection of Microservices](#synchroniseversions-of-a-collection-of-microservices)

## Introduction

Containers become a more and more essential element for software distribution and run-time environments. These days, most of our containers run as pods in Kubernetes (k8s) environments. This solution supports multiple cloud providers.

This solution describes a toolchain to simplify and normalise the creation of containers.

## Cloud Provider Support

### Container Repositories Upload

The toolchain supports to the upload of created containers into container registries by external providers. If the configuration-files specifies a remote repository, the tools try to log in automatically into the remote repository.

### Container Repositories Download

Additionally, references to external repositories are checked in file `Containerfile` (preferred) or `Dockerfile`. If external references are identified, the toolchain helps to login into these repositories.

## Project Directory Layout

It is expected to have a directory with go source files at the moment. This is supposed to be in a directory structure like:

```shell
<<projectHomeDir>>/src/go//<<binaryName>>
```

This directory contains the go source code of the project. Local packages are supposed to be bound in via a `packages` directory. It is common practice to build go binaries using a `vendor` sub-directory.

Let's image, we develop a *reverse proxy* for an *example* solution. Then the directory-structure could look like:

\small
```shell
example/                            # project directory
├── README.md                       # doc, often created from doc/ dir
├── README.pdf
├── doc/
│   └── img/
└── src/
    ├── packages/                   # local, private pkgs
    │   └── example-shared/
    │       ├── README.md           # each pkg, app with a README
    │       ├── connSharing.go      # at least a go file
    │       └── connSharing_test.go # here the corresponding unit-test
    ├── reverse-proxy/
    │   ├── Container/              # dir to create the container
    │   │   └── Containerfile       # alias Dockerfile
    │   ├── README.md
    │   ├── build/                  # used by gobuild.* scripts (ConfigShell)
    │   ├── main.go
    │   ├── main_test.go
    │   ├── packages -> ../packages/ # import of local packages
    │   ├── go.mod
    │   ├── go.sum
    │   └── vendor/
    ├── reverse-proxy-system-tests/
    │   ├── README.md
    │   └── runTest.sh              # system or load tests,...
    └── test-server/                # s-link to packages possible
        ├── Container/
        │   └── Containerfile
        ├── README.md
        ├── build/
        ├── main.go
        ├── main_test.go
        ├── go.mod
        ├── go.sum
        └── vendor/
```
\normalsize

## Compilation of Go Applications

### Overview

The compilation is done using the scripts of ConfigShell.  The scripts can be sub-classified:

1. Showing the current version number of the source code
2. Increasing either major, minor, or patch number of the version
3. creation of debug builds
4. creation of release builds (without debug information)
5. creation of release builds with additional [UPX](https://upx.github.io/) compression (does not seem to work for Apple M1/arm64)
6. execution of latest debug build
7. execution of latest release build

Builds are created under the build/ sub-directory.

### Simple Example

#### Directory/Project Setup

Let's start with a simple example to get a basic understanding of the work flow. A dollar ($) at the beginning of a line (BOL) expresses an entered command.

Let's create a directory hw/ and let's put a file main.go inside:

```shell
$ mkdir hw
$ cd hw
$ cat > main.go <<HERE
package main

import "fmt"

func main() {
    fmt.Println("Hi folks. Version is")
}
HERE
```

#### Go Initialisation

Specify a package name with it, here example.com:

```shell
$ go mod init example.com
```

`go mod vendor` is not required as only default golang packages
are referenced. If you would still try, you would get an error message like:

```shell
$ go mod vendor
go: no dependencies to vendor
```

The command is strongly recommended as soon as packages from https://github.com or else are included.

Now, clean up (making no harm):

```shell
$ go mod tidy
```

#### First Compilation Test

Now, let's try to compile a debug build for the current archicture and operating system. You can just use:

```shell
$ godebug
Calling /opt/ConfigShell/bin/gobuild.debug.darwin_arm64
```

The script determines the current OS,... and calls the listed script. If you want to compile for a specific platform, just use the long form. That's handy.

If you change from `godebug` to `gorelease`, a release build is
created (not suited for debugging), but usually used for container builds.

But, the above compilation returns an error!

#### Requirements of Version Information

The above command returned an ERROR:

```shell
godebug
Calling /opt/ConfigShell/bin/gobuild.debug.darwin_arm64
ERROR:Version information could not be determined.
ERROR:Could not determine the version of the go application.
```

The version of the go programme cannot be determined. Let's try it
manually with. `version.sh` is a script from ConfigShell:

```shell
$ version.sh
ERROR:Version information could not be determined.
```

So, we have to add it by either:

   1. specifying a pattern how to retrieve it
   2. specifying the version in a `version.txt` file
   3. specifying it with a default variable/const in one of the go files.

Let's use option 3. The source code file has to look like:

```shell
package main

import "fmt"

const _AppVersion = "0.0.1"

func main() {
    fmt.Println("Hi folks. Version is " + _AppVersion)
}
```

If we call now `version.sh` again, we get:

```shell
$ version.sh
0.0.1
```

#### First Successful Compilation

Let's restart the compilation:

```shell
$ godebug
Calling /opt/ConfigShell/bin/gobuild.debug.darwin_arm64
env GOARCH=arm64 GOOS=darwin go build -o ./build/debug/darwin_arm64/hw-0.0.1
```

We see, a binary `hw-0.0.1` was created in the directory `build/debug/darwin_arm64`.
Now, let's see all our files and directories:

```shell
$ tree -F hw
hw/
├── README.md
├── build/
│   └── debug/
│       └── darwin_arm64/
│           ├── hw -> hw-0.0.1*
│           └── hw-0.0.1*
├── go.mod
└── main.go
```

We see a bit more:

1. The binary is named after the directory enclosing it.
2. The version number is appending to the binary.
3. The actual binary is also reachable just by the directory name `hw`, or more precise `

    ```shell
    $ ./build/debug/darwin_arm64/hw
    Hi folks. Version is 0.0.1
    ```

As we just wanted to call the latest debug build, there is a script for it:

```shell
$ goexec-debug
Hi folks. Version is 0.0.1
```

Or even short:

```shell
$ goed
Hi folks. Version is 0.0.1
```

`goer` and `goeu` exist if you want to run the latest release or release-upx version.

#### Creating a New Version

Now, let's improve our file and hereby create a new version (main.go):

```shell
package main

import "fmt"

const _AppVersion = "0.0.1"

func main() {
   fmt.Println("HELLO!  Version is " + _AppVersion)
}
```

Now, let's try to compile it:

```shell
$ godebug
Calling /opt/ConfigShell/bin/gobuild.debug.darwin_arm64
ERROR:Current version hw-0.0.1 already exists.
```

A new compilation does not overwrite an existing build by default. If you want to keep at this version number (usually, not a good idea, but situations exist...), you could issue:

```shell
godebug -f
Calling /opt/ConfigShell/bin/gobuild.debug.darwin_arm64
env GOARCH=arm64 GOOS=darwin go build -o ./build/debug/darwin_arm64/hw-0.0.1
```

The `-f` options allows for overwriting existing versions.

#### Increasing Version Numbers

One approach is to change the number in the source file. But, you always have to go to this line, it becomes tedious, there is a more elegant way. 3 scripts exist to help you:

1. bpa (running `bumppatch ; version.sh`)
2. bmi (running `bumpminor ; version.sh`)
3. bma (running `bumpmajor ; version.sh`)

They will update the file with the version number automatically for you. Let's decide,
this is a minor change. So, let's execute:

```shell
$ bmi
0.1.0
$ cat main.go
package main

import "fmt"

const _AppVersion = "0.1.0"

func main() {
	fmt.Println("HELLO!  Version is " + _AppVersion)
}
$ godebug
Calling /opt/ConfigShell/bin/gobuild.debug.darwin_arm64
env GOARCH=arm64 GOOS=darwin go build -o ./build/debug/darwin_arm64/hw-0.1.0
```

#### Summary

Congratulations, you should have a grip now to our compilation model:

1. Scripts support the compilation
2. Script allow to differentiate between debug, release, and release+upx builds. All these builds go to different directories.
3. The scripts allow for cross compilation.
4. Builds by default do not overwrite each other.
5. Semantic versioning is supported by `bpa/bmi/bma`

## Versioning of Applications and Services

Changed software implementation must get a new, in their series unique version number, when they are deployed. This condition can be extended as a recommendation to do the same for already medium changes when recompiling software. This is supported by the above mentioned `godebug` and `gorelease` commands.

### synchroniseVersions of a Collection of Microservices

If you have a couple of microservices that bring up a service together, it is highly recommended to deploy only microservices with the same version number. This expresses that the microservices are supposed to run together and saves a lot of time for tedious research if the software versions are compatible with each other.

Configshell offers support to synchronise the versions of multiple solutions by the script `synchroniseVersions`. The algorithm of this script can be described by:

1. The command requires a file `synchroniseVersions.cfg` in the current directory. The file specifies directories
with contain applications. For each application, this app shows the current version.
2. Then it asks for a new version to be input by the user. This new version number is set to all the applications specified.
3. Alternatively to enter a new version number in step 2, the execution of the script can be stopped (`^c`).

In the case that you have multiple sets of microservices (e.g. A and B) and all A services have one version and all B services have one but possibly different version from A services, the script supports the specification of configuration files like `A.cfg` and `B.cfg`. You can call the script like:

```shell
synchroniseVersions -c <<cfgFile>>
```




