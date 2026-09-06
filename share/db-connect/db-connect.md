# db-connect.sh — one command to reach any of your databases

Stop remembering hosts, ports, users and passwords. Put them **once** into a
small profile file, give the profile a name, and from then on:

```sh
db-connect.sh ddsadm                          # interactive psql / mysql shell
db-connect.sh ddsro "select count(*) from t"  # run a single statement
cat schema.sql | db-connect.sh ddsadm         # feed a whole script
```

Same command, same syntax, whether the backend is **PostgreSQL** or
**MySQL/MariaDB**, whether the database runs on localhost, in the homelab or as
a managed service in the cloud. That is the whole idea.

## Why you want it

- **Named use-cases instead of connection strings.** `ddsadm`, `ddsro`,
  `shopprod` — the name says what you are connecting to and as whom.
- **DBMS-agnostic front door.** The script picks `psql` or `mysql` from the
  profile; you never type client-specific flags again.
- **Fits into scripts and pipelines.** Statements can be passed as an argument
  or piped on stdin; exit codes are deterministic and documented.
- **Per-project credentials.** The profile file lives in the working directory
  (or wherever `-f` points), so every project carries its own connections.
- **Aliases for free.** Symlink the script as `db-connect-<usecase>.sh` and the
  use-case is taken from the file name: `db-connect-ddsadm.sh "select 1"`.
- **Sane defaults for daily work.** Pager off, optional expanded output (`-x`)
  for wide PostgreSQL rows, a debug switch when something misbehaves.

## Setup

1. The script uses the ConfigShell bash library
   (`/opt/ConfigShell/lib/bashlib.sh`). Install ConfigShell first.
2. Put `db-connect.sh` on your `PATH`.
3. Make sure the client you need is installed: `psql` and/or `mysql`.

## The profile file

A plain shell file, sourced by the script. Each use-case is a prefix in front of
six variables:

```sh
# db-connect.pw
ddsadm_DB_TYPE='psql'          # psql | postgresql | postgres | mysql | mariadb
ddsadm_HOST='db.example.com'   # IP or FQDN
ddsadm_PORT='5432'
ddsadm_USER='dds_adm'
ddsadm_PW='secret'
ddsadm_DB='dds'

ddsro_DB_TYPE='psql'
ddsro_HOST='db.example.com'
ddsro_PORT='5432'
ddsro_USER='dds_ro'
ddsro_PW='secret'
ddsro_DB='dds'
```

All six values are required; the script refuses to run with an incomplete
profile (the port must be given explicitly). Comment lines start with `#`.

Where the script looks, in this order:

| Location                 | Notes                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| `-f <file>`              | Explicit file, wins over everything else                              |
| `./db-connect.pw`        | Profile file in the current directory                                 |
| `./db-connect.pws`       | Must be a **symlink** — points to a shared profile kept elsewhere     |

The `.pws` variant is the trick for repositories: commit a symlink that points
outside the repo (e.g. `~/.config/db-connect/company.pw`), keep the secrets out
of git, and every checkout still connects. Keep the profile file `chmod 600`.

## Usage

```
db-connect.sh            [-D] [-x] [-f <file>] <use-case> [ sql command ]
db-connect-<use-case>.sh [-D] [-x] [-f <file>]            [ sql command ]
cat file.sql | db-connect.sh <use-case>
```

| Option | Meaning                                                        |
|--------|----------------------------------------------------------------|
| `-f`   | Use this profile file instead of `db-connect.pw[s]`            |
| `-x`   | Expanded (vertical) output — PostgreSQL only                   |
| `-D`   | Debug output: which file, which values, which client is called |
| `-n`   | Dry run — print the client command instead of executing it     |
| `-V`   | Print version (currently 1.2.0) and exit 11                     |
| `-h`   | Usage                                                          |

Without a SQL command you land in the interactive client; with one, it is
executed and the script returns. Anything on stdin is handed to the client, so
`.sql` files and here-documents work as expected.

## Exit codes

| Code | Meaning                                              |
|-----:|------------------------------------------------------|
| 1    | Usage shown                                          |
| 2    | Unknown option                                       |
| 10   | Use-case could not be determined / `-f` file unreadable |
| 11   | Version shown                                        |
| 20   | No profile file found                                |
| 21   | `db-connect.pws` exists but is not a symlink         |
| 25   | Fewer than six settings found for the use-case       |
| 26   | Unsupported `DB_TYPE`                                |
| 28–32| `HOST`, `PORT`, `USER`, `PW` or `DB` unset           |
| 40   | Internal: unsupported client                         |
| 127  | ConfigShell bash library not found                   |

## Good to know

- Credentials are passed to the client on its command line (URI for `psql`,
  `--password=` for `mysql`), so they are briefly visible in the process list
  on shared machines. On single-user workstations and CI runners this is
  usually acceptable; for stricter setups, prefer `~/.pgpass` / `~/.my.cnf`.
- TLS is whatever the client's defaults are. For managed services that require
  it (e.g. Azure Database for PostgreSQL), export `PGSSLMODE=require` before
  calling the script.

---
*Author: Christian Engel · version 1.2.0 · part of the ConfigShell tool set*
