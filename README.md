# Run Script Framework

This is an extensible run script framework that is shared between my Python
repositories that use the [UV](https://docs.astral.sh/uv/) build tool.  The
framework is used to implement a standard build process that my 
[shared GitHub workflows](https://github.com/pronovic/gha-shared-workflows) depend on.

## Purpose

In my Python repositories, the `run` script is the entry point for developers
and for the GitHub Actions CI/CD process.  It wraps `poetry` and other build
tools to standardize various common tasks.  Here's what it looks like in 
the [apologies](https://github.com/pronovic/apologies) demonstration project:

```
------------------------------------
Shortcuts for common developer tasks
------------------------------------

Basic tasks:

- run install: Install the Python virtualenv and pre-commit hooks
- run update: Update all dependencies, or a subset passed as arguments
- run outdated: Find top-level dependencies with outdated constraints
- run format: Run the code formatters
- run checks: Run the code checkers
- run build: Build artifacts in the dist/ directory
- run test: Run the unit tests
- run test -c: Run the unit tests with coverage
- run test -ch: Run the unit tests with coverage and open the HTML report
- run suite: Run the complete test suite, as for the GitHub Actions CI build
- run suite -f: Run a faster version of the test suite, omitting some steps
- run clean: Clean the source tree

Additional tasks:

- run demo: Run a game with simulated players, displaying output on the terminal
- run docs: Build the Sphinx documentation for readthedocs.io
- run docs -o: Build the Sphinx documentation and open in a browser
- run release: Tag and release the code, triggering GHA to publish artifacts
- run sim: Run a simulation to see how well different character input sources behave
```

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
- update
- outdated
- format
- checks
- build
- test
- suite
- clean

These tasks are needed to set up the local development environment, and they're
also needed by the standard GitHub Actions build in [gha-shared-workflows](https://github.com/pronovic/gha-shared-workflows/blob/main/.github/workflows/poetry-build-and-test.yml).  They 
are called out separately as "basic tasks" in the help output for the `run`
script.  All other tasks are listed in alphabetical order in a separate help
section.  You can change the definition of these tasks to meet the needs of
your repository, but they must exist.

Additionally, there are several "hidden" tasks that are not shown in the help
output for the `run` script.

The `dch` and `sync` tasks are hidden utility features that simplify day-to-day
development but aren't worth documenting publicly.

The `mypy` and `lint` tasks exist for easy integration with Pycharm.  This way,
it's possible to use `run mypy` or `run lint` from external tools
configuration.  If you don't want to use one of these tools, just change the
task to a no-op (i.e.  `echo "MyPy is not used in this repo"`).

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

## Dependencies That Rely on Libraries

Python packages that depend on other libraries, especially geospatial packages,
tend to bundle those libraries along with the published artifacts on PyPI.
This works ok as long as 1) they're bundling the version of the library that
you need and 2) you aren't using more than one Python package that depends on
the same library.  Otherwise, you tend to run into problems.

The usual solution for this scenario is to rely on system libraries (installed
from Debian or Homebrew, etc.).  You install each system library outside of the
Python build process, and then you force UV to build and link the Python
package against the system library rather than the bundled library.  This is
done using the [no-binary-package](https://docs.astral.sh/uv/reference/settings/#no-binary-package) setting 
in `pyproject.toml`.

However, even if you do this, there are some times when you will need to force
UV to rebuild and relink &mdash; for instance, if the system library has been
updated, and you want UV to pick up that change.  This requires some extra
work.  The best solution I've found is to clear those packages out of the UV
cache:

```shell
uv cache clean $(grep '^no-binary-package' pyproject.toml | sed 's/^no-binary-package = //' | sed 's/[][,"]//g')
```

For now, I've decided not to implement this in the run script framework.  It's
relatively rare, and I don't need it for any of the packages I'm maintaining
today.  If/when I have a project of my own that needs this, I'll figure out the
right way to integrate it, probably as a custom task.
