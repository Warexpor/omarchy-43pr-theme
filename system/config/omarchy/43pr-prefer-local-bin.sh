#!/bin/bash
# Prefer ~/.local/bin wrappers (claude, cursor, claude-desktop, …) over
# `mise activate` tool paths that would otherwise shadow them.
_local_bin="${HOME}/.local/bin"
_new_path=""
_old_ifs=$IFS
IFS=:
for _p in $PATH; do
  [[ -n $_p && $_p != "$_local_bin" ]] || continue
  _new_path="${_new_path:+$_new_path:}$_p"
done
IFS=$_old_ifs
export PATH="${_local_bin}${_new_path:+:$_new_path}"
unset _local_bin _new_path _old_ifs _p
