# vim: set ft=bash ts=3 sw=3 expandtab:
# Generate a requirements.txt file in the docs directory, for use by readthedocs.io

# Unfortunately, we can't just rely on Poetry here.  Poetry wants to generate a
# file that includes our project's lowest compatible version of Python, but
# readthedocs.io can only build with older versions (v3.7 as of this writing,
# even though it's years out of date).  So, we need to modify the generated
# result to make readthedocs.io happy.
#
# The "solution" is to replace whatever lowest python version Poetry generated
# with "3.7", and hope for the best. That seems to have been working so far,
# but we may eventually run into a dependency that simply doesn't exist for
# Python 3.7.

command_requirements() {
   echo -n "Generating docs/requirements.txt..."

   local replacement

   run_command poetryplugin poetry-plugin-export

   poetry export --format=requirements.txt --without-hashes --with dev --output=docs/requirements.txt
   if [ $? != 0 ]; then
      echo ""
      echo "*** Failed to export docs/requirements.txt"
      exit 1
   fi

   run_command sedreplace 's|python_version >= "3\.[0-9][0-9]*"|python_version >= "3.7"|g' docs/requirements.txt
   run_command dos2unix docs/requirements.txt

   echo "done"
}

