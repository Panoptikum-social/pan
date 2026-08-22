#!/bin/sh
set -eu

case "${1:-start}" in
  start)
    /app/bin/pan eval "Pan.Release.migrate()"
    exec /app/bin/pan start
    ;;
  *)
    exec /app/bin/pan "$@"
    ;;
esac
