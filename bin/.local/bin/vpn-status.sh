
#!/usr/bin/env bash
if systemctl --user is-active --quiet tuvpn.service; then
  echo '{"text":"🛡"}'
else
  echo '{"text":""}'
fi
