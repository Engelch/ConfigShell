# 1. ConfigShell

- v0.0.1 --u2022-05-19
- author: engel-ch@outlook.com

- [1. ConfigShell](#1-configshell)
	- [1.1. About](#11-about)
	- [1.2. Tools covered](#12-tools-covered)
		- [1.2.1. Support by git-submodules](#121-support-by-git-submodules)
	- [1.3. Shell support](#13-shell-support)
		- [1.3.1. Bash structure](#131-bash-structure)
			- [1.3.1.1. .bashrc](#1311-bashrc)
			- [1.3.1.2. .bash_profile](#1312-bash_profile)
		- [Class-like file structure convention](#class-like-file-structure-convention)
		- [Reloading ConfigShell](#reloading-configshell)
		- [Provided files](#provided-files)

## 1.1. About

ConfigShell is a project by many working on a common, extended standard to install dot-files
to local workstations and servers. Dot-files are configuration files for tools that are usually
loaded automaticatically when a tool is started,
Workstations are systems running on the following operating systems at the moment:

- Linux (debian-based such as Ubuntu and Debian)
- Linux (redhat-based such as Fedora and RHEL)
- Darwin (alias OSX alias Mac OS)
- WSL with Windows 10
- WSL with Windows 11

The supported OS are also listed in the file `supportedOS.txt`.

## 1.2. Tools covered

The configuration files cover the following tools

- bash (Version ≥ 3)
- zsh (although we are moving back to bash)
- tmux
- git
- vim
- LaTeX
- golang (compilation files)
- bumpversion (to support semantic versioning)
- British dictionary as to be used for hunspell

Some elements are supported by git-submodules.

### 1.2.1. Support by git-submodules

3 submodules exist

1. `PowerlineFonts/` - a font collection particularly for zsh to support the agnoster theme.
2. `ConfigLinux/` - a git repository with binaries for amd64 to support sha256 checksums and signing files.
3. `ConfigOSX/` - same of `ConfigLinux/` but for OSX supporting arm64 and amd64.

The documentation of them is subjects of their individual projects. These elements are to be loaded as git-submodules. A git-submodule can be loaded and updated by issuing the command:

```bash
git submodule update --init
```

The existing git-submodules and their local directories can be found in the file `<<projectRoot>>/.gitmodules` which currenctly contains:

```bash
[submodule "PowerlineFonts"]
    path = PowerlineFonts
    url = https://github.com/powerline/fonts.git
[submodule "ConfigDarwin"]
    path = ConfigDarwin
    url = git@github.com:Engelch/ConfigDarwin.git
[submodule "ConfigLinux"]
    path = ConfigLinux
    url = git@github.com:Engelch/ConfigLinux.git
```

## 1.3. Shell support

Support is mainly for `bash` after returning from `zsh` but most of the elements should still work with `zsh`.  Furthermore, the scripts try to be separated into `sh-normal` scripts and *bash-specific* ones.

### 1.3.1. Bash structure

The general structure of execution is shown here. The design makes sure that every interactive shell has executed the main scripts `.bashrc` and `.bash_profile`. Non-interactive executions split nearly all of this.

#### 1.3.1.1. .bashrc

This script is executed by every non-login shell. Strangely, by default
it is not executed by login shells.

1. sourceIfExist ~/.bashrc.pre - allow users to change processing

2. set history file
3. source ~/.bash_profile if it was not loaded before and stop bashrc
4. sourceIfExistExecInit  Shell/common.*.sh - Load files source-able by zsh and bash.

5. sourceIfExistExecInit  Shell/bash.*.sh - Load bash-specific files.

6. sourceifExistExecInit  Shell/os.$(uname).sh - Load operating-system specific files.

7. sourceIfExist ~/.bashrc.post - Cleanup and correction routine for users.

8. sourceIfExist ~/.bashrc.d/*.sh

    ConfigShell does neither create nor distributes files by .bashrd.d. This is just supposed to change
    the behaviour of execution.

#### 1.3.1.2. .bash_profile

This script is executed by login shells.

1. setupPath
2. envVars
3. sourceIfExistExecInit Shell/env.path.*.sh
4. sourceIfExistExecInit Shell/env.os.$(uname).sh
5. sourcePaths $HOME/.env.*.path
6. source .bashrc

### Class-like file structure convention

Most of the shell scripts sourced by one of the above main-scripts are executed in a class-like design. As bash is quite limited as a programming language this is be done like:

1. A file `common.blabla.sh` is sourced
2. The file provides a destructor `common.blabla.del`
3. The file provides a constructor-like shell function `common.blabla.init`

### Reloading ConfigShell

1. During normal loading or a `rl` (reload, built-in), all the constructor shell functions are called
1. During a `rlFull` (reload full) execution (built-in), first all destructors and then all constructors are executed.

    An `rlFull` also deletes all cache files, takes longer, but is the usual way to actualise everything after a new version of ConfigShell was pulled.

### Provided files

| Filename | Purpose |
| --- | --- |
| bash.prompt_version.sh | Bash shell-prompt specific settings and version definition |
| common.aliases.sh | Aliases for all environments and  all OS |
| common.crypto.sh  | Aliases and functions for crypto-, certificate-related topics |
| common.diverse.sh |  functions available in all environments and  all OS |
| common.git.sh | git-related helpers |
| common.go.sh  | golang-related helpers |
| common.k8s.sh | Kubernetes (k8s) helpers |
| common.path.aws.sh | AWS-related path settings |
| common.path.ruby.sh | ruby-related path settings |
| env.os.Darwin.sh | OSX alias MacOSX alias Darwin related helpers |
| env.os.Linux.sh | Linux related helpers |
| env.path.go.sh | golang-related PATH and environment settings |
| env.path.latex.sh | latex-related PATH settings |
| env.path.terraform.sh | terraform-related PATH settings |
| os.Darwin.sh | OSX-related aliases and functions |
| os.FreeBSD.sh |  aliases and functions |
| os.Linux.sh | Linux-related aliases and functions |
| zsh.diverse.sh | zsh-only related settings |
| zsh.version.sh | zsh file defining version of zsh scripts |
