# Go Programming Support

March 2024

## Contents

- [Go Programming Support](#go-programming-support)
  - [Contents](#contents)
  - [TODO](#todo)
  - [About](#about)
  - [Project Structure](#project-structure)

[//]: # (delete before 4 LaTeX)

## TODO

You can search for keyword TODO in this document.

- reference to git gee

## About

Since 2017, we use go for various development projects. The major focus is on applications for IoT devices and communication-based services such as reverse proxies. Overall, this is considered to be a full success story. Important elements for this success lay in certain elements:

1. Well documented programming language.
2. Fast run-time environment with limited memory required, in particular if compiled with CLR or JRE.
3. Good, CSP-based support for multi-threading.
4. The libraries were created by some engineers who seem to have programmed for some years. The application of them can be considered pragmatically. This is considered to be the opposite of many consortium-originated languages.
5. Good tool-chain support: the good language design and the quality of the tool-chain well fit together.
6. Excellent support for cross-compilation. Every normal installation contains all the elements to compile for different CPU-types and operating systems.
7. Fitting really well into the world of docker/podman containers and Kubernetes (K8s) clusters.
8. BSD-based license.

## Project Structure

A go project usually consists out of one or multiple binaries, a documentation directory, and other elements such as configuration files. A typical project setup can look like the following directory tree:

```bash
ProjectRoot/
  + README.md --> doc/README.md
  + README.pdf --> doc/README.pdf
  + doc/
     + README.md
     + README.pdf
     + TODO.md # open topics
     + Structure and Design Document Structure/
     + Operations and Maintenance Document Structure/
     + Implementation & Configuration Documents/
     + Other Documents/
        + Training Documentation/
        + Tutorials/
  + config/  # configurations
  + src/
     + app1/
     + app2/
     ...
     + packages/ # shared packages between the applications but not public to the Internet, can include git-submodules,...
  + tests/ # regression, load-tests, ...
  + old/ # older stuff, which shall not be removed
  + tmp/ # temporary directory, to be cleaned up for releases
  + .git/ # git meta directory
ProjectRoot.gee.pw
```

The file `ProjectRoot.gee.pw` is optional. If existing it must have the same name as the project root directory, appended by the suffix `.gee.pw`. TODO Git gee is also part of the [ConfigShell](https://github.com/engelch/ConfigShell) collection. It is used for encryption purposes to keep things private. It is similar to solutions such as *git secret* or *git secrets* but we think it is easier and in particular more bulletproof to use.

The tools described here help with the building of the applications which are located under the `src/` directory.
