# ConfigShell

- v0.0.1 --u2022-05-19
- author: engel-ch@outlook.com

## About

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

## Tools covered

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

### Support by git-submodules

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
