# Tasks

Tasks are high-level actions that can be executed via the `run` script.

If you need a custom task for your repository, it's usually simpler to
implement that behavior within the task itself rather than breaking it up
between a task and a command.  This helps make it more obvious that your new
task is repository-specific.

## Creating a new task

A task is defined by a naming convention.  There is a bash script that
identifies the name of the task.  Within the bash script, there must be two
bash functions, `help_<task>` and `task_<task>`.

So, for command called "example", you would create a file
file `.run/tasks/example.sh`.  That file must contain the 
following bash functions:

```bash
help_example() {
   echo "- run example: Description of the example task"
}

task_example() {
   # Put your implementation here
}
```

If you don't want your task to appear in the help output, then use `echo -n ""`
as the implementation for `help_<task>` (bash functions must not be empty).

Tasks are implemented mostly in terms of commands (using `run_command
<command>`), but you can also run installed tools (using `poetry_run <tool>`),
run the Python interpreter (using `poetry_run python`), or even just invoke
`poetry` directly.

Commands are supposed to `exit 1` when they encounter a permanent error, so you
don't have to check their result via `$?` when using `run_command`.  Similar
error handling exists when you use `poetry_run`.  If you invoke `poetry`
directly, you must do your own error handling.

You may use `$REPO_DIR` to refer to the main repository directory,
and `$DOTRUN_DIR` to refer to the `.run` directory within the repository.
There is a temporary working directory at `$WORKING_DIR`.

If you change directories as part of your task, you _must_ change back
to the original directory if the task completes successfuly.  This makes
it possible to safely chain together multiple tasks and commands.
