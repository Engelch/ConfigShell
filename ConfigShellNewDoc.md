---
marp: true
paginate: true
theme: foobar
size: 16:9
class:
    - invert
---

# ConfigShell

Version 2.0.0

Christian Engel

Fabio Scaccabarozzi
![bg left contain](img/hand-with-support-gears-isolated.jpg)

---

# About - Navigation
![bg right contain](img/about-us-word-debossed-text-style.jpg)
If you are new to ConfigShell, it is recommended to

1. read the basic documentation first
2. read the changelogs for the versions 1.1, 1.2, 2.0

---

# License
![left bg contain](img/terms-use-conditions-rule-policy-regulation-concept.jpg)

1. All elements of ConfigShell are under MIT license except

   1. lorem3 script (GPL)

---

## Release 2 Changelog

### bashlib
Header of bash shellscripts factored out to `/opt/ConfigShell/lib/bashlib.sh`

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
![bg opacity:.5](img/2888933.jpg)

- can be installed without password (git clone)
- script included to automatically upgrade when logging in
- also working from PR China

---

# Installation of ConfigShell 1of2
![bg opacity:.5](img/crop-sportsman-crouch-start-pose.jpg)
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

- Optional submodules
- Special support for OSX/Darwin, Linux,...
  - Linux: gnome-terminal colours; signfile; gosha256
  - OSX:  iTerm, Terminal colour profiles; divvy profile; keyboard maestro LaTeX-like sequences (\\=>, \\<=>, \lambda, \euro,...); signfile; gosha256

## Installation & Upgrade
```bash
cd /opt/ConfigShell
git submodule update --init
```

---

# ConfigShell, is it enabled?

## Bash's ConfigShell Prompt

## Fish's ConfigShell Prompt



