# Run Script Framework

This is an extensible run script framework that is shared between my Python
repositories that use the Poetry build tool.

## Background/History

The original `run` script implementation was prototyped in the
[apologies](https://github.com/pronovic/apologies) demonstration project.  In
the first few years after apologies was written, I used it as a basis for a lot
of other production code, copying around and customizing the `run` script each
time.

Eventually, that became awkward.  It required too much effort to keep the `run`
script up-to-date as I improved it or fixed bugs.  To improve that situation, I
simplified the `run` script to be implemented in terms of discrete **Tasks**
and **Commands** implemented in the `.run` directory.  It's much easier to
share these smaller, discrete files than maintain a larger `run` script that's
slightly different everywhere it's used.

## Concepts

**Tasks** are high-level actions that can be executed via the `run` script.

**Commands** are the building blocks of tasks.  Any command can be invoked from
a task or another command using `run_command <command>`.

Normally, commands implement functionality that is general enough to be shared,
like build steps or actions that are part of a standard code maintenance
pattern.  If you need a custom task for your repository, it is usually better
to implement that behavior within the task itself rather than breaking it up
between a task and a command.  This helps make it more obvious that your new
task is repository-specific, and makes it easier to keep the set of shared
commands up-to-date with the latest improvements.

See [`tasks/README.md`](tasks/README.md) and [`commands/README.md`](commands/README.md) for
more information about how tasks and commands are defined, and how to create and modify them.

## Required Tasks

The following tasks must always be defined if you want to use the standard
`run` script:

- install
- format
- checks
- build
- test
- suite

These tasks are needed to set up the local development environment, and they're
also needed by the standard GitHub Actions build in [gha-shared-workflows](https://github.com/pronovic/gha-shared-workflows/blob/master/.github/workflows/poetry-build-and-test.yml).  They 
are called out separately as "basic tasks" in the help output for the `run`
script.  All other tasks are listed in alphabetical order in a separate help
section.  You can change the definition of these tasks to meet the needs of
your repository, but they must exist.

Additionally, there are two "hidden" tasks that are not shown in the help
output for the `run` script:

- mypy
- pylint

These tasks exist for easy integration with Pycharm, so it's possible to use
`run mypy` or `run pylint` from external tools configuration.  If you don't
want to use one of these tools, just change the task to a no-op (i.e. `echo
"MyPy is not used in this repo"`).

## Synchronizing Shared Code

This repository is meant to be the source of record for all shared code.  When
code is changed in a repository that uses the framework, it should be pulled in
here.  When changes are made here, they should be pushed to other repositories
that use the framework.  The `pull` and `push` scripts are used for this
purpose.  Both scripts are intended to be run from within this repository. 

The general rule is that individual repos may customize only tasks, not any of
the other code.  We pull in only non-customized tasks.  If the source
repository contains a new task that doesn't already exist here, we will pull it
in as long as it's not a customized task.  We push only standard,
non-customized tasks.  We never add a new task that does not already exist in
the repo.

A repo can flag a customized task using a marker comment:

```bash
# runscript: customized=true
```

If this marker is found in first 5 lines of code, then the script is considered
customized and will be ignored.
