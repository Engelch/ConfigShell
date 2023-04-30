---
marp: true
paginate: true
---

# ConfigShell

Version 2.0.0

Christian Engel

Fabio Scaccabarozzi
![opacity:.7](shell.png)
![bg left contain](configuration.png)

---

# About - Navigation

If you are new to ConfigShell, it is recommended to

1. read the basic documentation first
2. read the updated about version 1.2 and version 2.0

---

# License

1. The elements of ConfigShell are under MIT license

1. One element is under GPL und not changed

---

# Release 2 Changelog

todo 
---

# Release 1.* Changelog

---

- Commands moved from shell aliases to ConfigShell/bin scripts
    - maintenance of one version for all shells
    - easier to integrate new shells
    - shorter shell rc-files, shorter loading times
    
---

# Release 1.2 Changes

todo

---

# ConfigShell Introduction

- Open-source (MIT-based) project to support Linux/UNIX® interactive working environments
- Experience based on 40 years of UNIX and Linux experience since 1992
- having the same CLI environment everywhere
- Shell interactive support for bash, fish, zsh (partly)
- Linux support for environments behind a proxy
- Golang development support, rust support coming
- Scripts for TLS & SSH key/certificate creation and analysis
- Bash scripting, markdown & LaTeX support
- git encryption and general git support
- Kubernetes (k8s) support

---

# ConfigShell Basic Features

- can be installed without password (git clone) 
- script included to automatically upgrade when logging in
- also working from PR China

---

# Installation of ConfigShell 1of2
![bg opacity:.5](1stStep.png)
1. Use the default path if possible
    
    ```bash
    sudo mkdir /opt/ConfigShell
    sudo chown <<you>> /opt/ConfigShell # or !$ for /opt/ConfigShell
    ```
1. Install ConfigShell
    ```bash
    git clone https://github.com/engelch/ConfigShell /opt/ConfigShell
    ```
2. Activate it for you (home directory of the current user)
    ```bash
    /opt/ConfigShell/installDotFiles2home
    ```
3. Restart your shell

---

# Installation of ConfigShell Submodules 2/2

## About

Special support for OSX/Darwin, Linux,...

- Linux gnome-terminal colours; signfile, gosha256
- OSX iTerm and Terminal colour profiles; divvy profile; signfile, gosha256

## Installation
```bash
cd /opt/ConfigShell
git submodule update --init
```

---

# ConfigShell, is it enabled?

## Bash's ConfigShell Prompt

## Fish's ConfigShell Prompt



