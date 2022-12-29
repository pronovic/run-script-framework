# vim: set ft=bash ts=3 sw=3 expandtab:
# Attach an asset to a GitHub release for a repository

# This command requires the following environment variables:
#
#   $GITHUB_API_URL - the base URL for the GitHub API
#   $API_TOKEN - a GitHub API token with repository scope
#
# Rough steps for this process were taken from:
#
#   https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447?permalink_comment_id=4193924#gistcomment-4193924
#
# Uploading an asset is a multi-step process.  First, you have to query the
# release to get its upload URL, and then you need to POST to that upload URL
# to actually attach the artifact.
#
# The returned upload URL is something like this:
#
#   https://api.github.com/uploads/repos/owner/repo/releases/37443/assets{?name,label}
#
# The JQ command strips off the trailing "{?name,label}", which is just
# informational and is not really part of the POST.

command_attachasset() {

   local REPOSITORY RELEASE ASSET_PATH RELEASE_URL OPTIONS UPLOAD_URL

   if [ $# != 3 ]; then
      echo "attachasset <repository> <release> <asset>"
      echo "Attach an asset to a release"
      echo ""
      echo "repository - the GitHub repository in format 'owner/repo'"
      echo "release - the release to modify, like 'v1.2.0'"
      echo "asset - absolute path to the asset on disk"
      echo ""
      exit 1
   fi

   REPOSITORY="$1"
   RELEASE="$2"
   ASSET_PATH="$3"

   RELEASE_URL="$GITHUB_API_URL/repos/$REPOSITORY/releases/tags/$RELEASE"

   # Put common options and secrets into $OPTIONS, so they're not visible in ps listing
   OPTIONS="$WORKING_DIR/options.txt"
   rm -f "$OPTIONS"
   cat << EOF >> "$OPTIONS"
silent
Header "Authorization: token $API_TOKEN"
EOF

   # Retrieve the upload URL
   UPLOAD_URL=$(curl -X GET --config "$OPTIONS" "$RELEASE_URL" | jq -r '.upload_url' | cut -d'{' -f1)
   if [ "$UPLOAD_URL" == "null" ]; then
      echo "Failed to retrieve upload URL"
      exit 1
   fi

   # Upload the asset and attach it to the release via the upload URL
   echo "Uploading asset: $UPLOAD_URL"
   curl -X POST \
      --config "$OPTIONS" \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Content-Type: $(file -b --mime-type $ASSET_PATH)" \
      -H "Content-Length: $(wc -c <$ASSET_PATH | xargs)" \
      -T "$ASSET_PATH" \
      "$UPLOAD_URL?name=$(basename $ASSET_PATH)" | jq

}
