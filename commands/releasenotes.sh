# vim: set ft=bash ts=3 sw=3 expandtab:
# Generate release notes based on the top entry in the Changelog file

command_releasenotes() {
   local OUTPUT CHANGES

   if [ $# != 1 ]; then
      echo "releasenotes <output>"
      exit 1
   fi

   OUTPUT="$1"
   rm -f "$OUTPUT"

   # See: https://stackoverflow.com/a/55222646/2907667
   CHANGES=$(sed -n '/^Version /{:a;n;/^Version /q;p;$!ba}' Changelog | sed '/^$/d' | sed 's/^\s*\*/-/' | sed 's/\.$//')

   if [ -z "$CHANGES" ]; then
      echo "" > "$OUTPUT"
   else
      echo "## Changes" > "$OUTPUT"
      echo "" >> "$OUTPUT"
      echo "$CHANGES" >> "$OUTPUT"
   fi
}
