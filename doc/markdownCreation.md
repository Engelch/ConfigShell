# Markdown Utilities provided by ConfigShell

## Contents

- [Markdown Utilities provided by ConfigShell](#markdown-utilities-provided-by-configshell)
  - [Contents](#contents)
  - [About](#about)
  - [A Classical Situation](#a-classical-situation)

[//]: # (delete before 4 LaTeX)

## About

LaTeX is still considered to be the best typesetting solution existing in the IT market. Nevertheless, it can be considered to be too complex for a lot of normal usages.

Markdown can be considered as a simplified version of a batch formatting system such as LaTeX. Its rules are much easier to learn than the ones of LaTeX and TeX. ConfigShell provides scripts to convert and format Markdown documents to the interim format LaTeX and then to PDF. This combines the easiness of Markdown with with excellent formatting of LaTeX. This wonderful process is supported by the OSS tool [pandoc](https://pandoc.org).

The scripts and templates provided by ConfigShell shall help to use this tool-chain more effectively.

## A Classical Situation

Image you format a Markdown document like this:

```text
  # Markdown Utilities provided by ConfigShell

  ## Contents

  You might use an automatic table of contents (TOC) as
  created by tools such as typora or vscode (extension: Markdown
  all in One)

  ## About
  ...
```

With this automatic TOC this might look like:

```text
  # Markdown Utilities provided by ConfigShell
  
  ## Contents
  
  - [Markdown Utilities provided by ConfigShell](#markdown-utilities-provided-by-configshell)
    - [Contents](#contents)
    - [About](#about)
    - [A Classical Situation](#a-classical-situation)
  
  ## About
  ...
```

If such a document is stored as a `README.md` file, then many git repository front-ends would automatically format this document and it all looks ok.
Often, we are interested to format this Markdown file also the PDF. Then, even local clones of this directory can be used to display this Markdown file in a well looking form.

But, if we want to format this document to PDF using [pandoc](https://pandoc.org), we run into some challenges:

- No LaTeX title, author is defined
- The table of contents is based on Markdown, not LaTeX: by far not so beautiful as it could, as it should be.
- Only one section exists. This is supposed to be the title. All *normal* elements are subsections and below.

Here is an example how it looks like:

![](img/markdownUsingPlanPandoc.png)

This is where `md2pdf` (same as `markdown2pdf`) comes into the game.
Let's use the ConfigShell tool to format it:

```shell
md2pdf README.pdf
```

And here the output:

![](img/markdownFormatttedWithConfigShell.png)

We can see:

- The markdown title is the LaTeX title
- The LaTeX table of contents macro is used
- All sections and below are on the right level