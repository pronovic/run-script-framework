# vim: set ft=bash ts=3 sw=3 expandtab:
# Update the release title and body for a GitHub release

# This command requires the following environment variables:
#
#   $GITHUB_API_URL - the base URL for the GitHub API
#   $API_TOKEN - a GitHub API token with repository scope

command_updaterelease() {

   local REPOSITORY RELEASE RELEASE_NOTES OPTIONS BODY UPDATE_URL

   if [ $# != 3 ]; then
      echo "updaterelease <repository> <release> <release-notes>"
      echo "Update the release title and body for a GitHub release"
      echo ""
      echo "repository - the GitHub repository in format 'owner/repo'"
      echo "release - the release to modify, like 'v1.2.0'"
      echo "release-notes - absolute path to release notes on disk, in Markdown format"
      echo ""
      exit 1
   fi

   REPOSITORY="$1"
   RELEASE="$2"
   RELEASE_NOTES="$3"

   RELEASE_URL="$GITHUB_API_URL/repos/$REPOSITORY/releases/tags/$RELEASE"

   # Put common options and secrets into $OPTIONS, so they're not visible in ps listing
   OPTIONS="$WORKING_DIR/options.txt"
   rm -f "$OPTIONS"
   cat << EOF >> "$OPTIONS"
silent
Header "Authorization: token $API_TOKEN"
EOF

   # Create the JSON body
   BODY="$WORKING_DIR/body.json"
   rm -f "$BODY"
   jq -n '$ARGS.named' \
     --arg 'name' "Release $RELEASE" \
     --arg 'body' "$(cat '$RELEASE_NOTES')" > "$BODY"

   # Retrieve the update URL
   UPDATE_URL=$(curl -X GET --config "$OPTIONS" "$RELEASE_URL" | jq -r '.url')
   if [ "$UPDATE_URL" == "null" ]; then
      echo "Failed to retrieve update URL"
      exit 1
   fi

   # Update the release by patching it
   echo "Updating release: $UPDATE_URL"
   curl -X PATCH \
      --config "$OPTIONS" \
      -H "Accept: application/vnd.github.v3+json" \
      --data-binary "@$BODY" \
      "$UPDATE_URL" | jq

}
