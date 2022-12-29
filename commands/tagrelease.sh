# vim: set ft=bash ts=3 sw=3 expandtab:
# Update the changelog and tag a specific version of the code

command_tagrelease() {
   local VERSION DATE TAG FILES MESSAGE

   if [ $# != 1 ]; then
      echo "tagrelease <version>"
      exit 1
   fi

   VERSION=$(echo "$1" | sed 's/^v//') # so you can use "0.1.5 or "v0.1.5"
   DATE=$(date +'%d %b %Y')
   TAG="v$VERSION" # follow PEP 440 naming convention
   FILES="NOTICE pyproject.toml Changelog"
   MESSAGE="Release v$VERSION to PyPI"

   if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
      echo "*** You are not on $DEFAULT_BRANCH; you cannot release from this branch"
      exit 1
   fi

   git tag -l "$TAG" | grep -q "$TAG"
   if [ $? = 0 ]; then
      echo "*** Version v$VERSION already tagged"
      exit 1
   fi

   head -1 Changelog | grep -E -q "^Version $VERSION[[:blank:]][[:blank:]]*unreleased"
   if [ $? != 0 ]; then
      echo "*** Unreleased version v$VERSION is not at the head of the Changelog"
      exit 1
   fi

   poetry version $VERSION
   if [ $? != 0 ]; then
      echo "*** Failed to update version"
      exit 1
   fi

   run_command dos2unix pyproject.toml
   run_command sedreplace "s|^Version $VERSION[[:blank:]][[:blank:]]*unreleased|Version $VERSION     $DATE|g" Changelog
   run_command sedreplace "s|(^ *Copyright \(c\) *)([0-9,-]+)( *.*$)|\1$COPYRIGHT\3|" NOTICE

   git diff $FILES

   git commit --no-verify -m "$MESSAGE" $FILES
   if [ $? != 0 ]; then
      echo "*** Commit step failed"
      exit 1
   fi

   git tag -a "$TAG" -m "$MESSAGE"
   if [ $? != 0 ]; then
      echo "*** Tag step failed"
      exit 1
   fi

   echo ""
   echo "*** Version v$VERSION has been released and committed; you may publish now"
   echo ""
}

