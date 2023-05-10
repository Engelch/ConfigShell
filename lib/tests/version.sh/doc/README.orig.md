# Test cases for version.sh

- author: engelch
- c230509

## Contents

- [Test cases for version.sh](#test-cases-for-versionsh)
  - [Contents](#contents)
  - [About](#about)
  - [Output](#output)
    - [ok:....](#ok)
    - [ERROR:.... or FAIL:...](#error-or-fail)
    - [Other output](#other-output)
  - [Example Output](#example-output)


## About

This directory tree contains tests to check for the desired behaviour of the `version.sh` script which is usually located in `/opt/ConfigShell/bin`.

The tests can be started by calling the script:

```shell
./test_all.sh
```

To do that, you are supposed to be in the directory:

```shell
/opt/ConfigShell/lib/tests/version.sh
```

The script will execute all scripts ending in `test.sh` which are located either in this or some of the sub-directories.
Each directory is supposed to contain a certain setup that is supposed to be tested for `version.sh`.
The actual tests are described in the individual directories.
As stated, a directory can contain multiple `*test.sh` script, but it is common to contain only one with multiple tests.

## Output

The output can be classified in 3 different elements:

### ok:....

A successful test has to output a line like

```shell
ok:<<testNameOrDirectoryName>>:<<what was tested>>
```

### ERROR:.... or FAIL:...

An unsuccessful test output **one** line like

```shell
ERROR:<<testNameOrDirectoryName>>:<<what was tested>>
```

or

```shell
FAIL:<<testNameOrDirectoryName>>:<<what was tested>>
```

### Other output

Other output must not begin with `ok:`, `ERRROR:`, or `FAIL:`. This output shall be minimised and best not existing.

## Example Output

The output should look like:

\footnotesize
```shell
ok:version.txt-file:test1 version.sh
ok:version.txt-file:test2 version.sh -v
ok:defaultGoModeWithFilenameWithSpaces:test1 version.sh
ok:defaultGoModeWithFilenameWithSpaces:test2 version.sh -v
ok:versionPatternFilenameWithSpaces:test1 version.sh
ok:versionPatternFilenameWithSpaces:test2 version.sh -v
ok:defaultMultipleAppVersions:test1 version.sh
ok:defaultMultipleAppVersions:test1 version.sh -v
ok:versionPatternMultipleMatchingFiles:test1 version.sh
ok:versionPatternMultipleMatchingFiles:test1 version.sh -v
ok:defaultNoVersionInfo:test1 version.sh
ok:defaultNoVersionInfo:test1 version.sh -v
ok:versionPattern:test1 version.sh
ok:versionPattern:test2 version.sh -v
ok:defaultMultipleAppVersionsWithFilenamesWithSpaces:test1 version.sh
ok:defaultMultipleAppVersionsWithFilenamesWithSpaces:test1 version.sh -v
ok:defaultGoMode:test1 version.sh
ok:defaultGoMode:test2 version.sh -v
ok:versionPatternNoMatchingFile:test1 version.sh
ok:versionPatternNoMatchingFile:test1 version.sh -v
```
\normalsize