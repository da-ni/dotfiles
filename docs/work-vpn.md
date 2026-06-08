# Work VPN

`omarchy-work-vpn` wraps OpenConnect for a one-click Omarchy workflow:

- Waybar VPN icon next to networking
- desktop launcher named `Work VPN`
- private local config in `~/.config/work-vpn/config`
- password stored in the Secret Service keyring via `secret-tool`
- two-factor code prompted on each connection

## Setup

Install OpenConnect:

```bash
yay -S openconnect
```

Create and edit the local config:

```bash
omarchy-work-vpn setup
$EDITOR ~/.config/work-vpn/config
```

Set at least:

```bash
VPN_SERVER="vpn.example.com"
VPN_USERNAME="your.username"
```

If your work VPN needs a specific OpenConnect protocol, set `OPENCONNECT_PROTOCOL` to values such as `anyconnect`, `gp`, `pulse`, `f5`, or `fortinet`.

These local settings model the old manual command shape:

```bash
OPENCONNECT_AUTHGROUP="your-auth-group"
OPENCONNECT_USER_AGENT="AnyConnect OpenConnect"
OPENCONNECT_NO_EXTERNAL_AUTH=1
OPENCONNECT_PASSWORD_ON_STDIN=1
OPENCONNECT_BACKGROUND=1
OPENCONNECT_EXTRA_ARGS=()
```

During OpenConnect's connect hook, the wrapper runs:

```bash
resolvectl dnsovertls tun0 no
```

This is implemented as an OpenConnect vpnc-script hook, not as a timeout loop. OpenConnect runs the hook when the tunnel is configured and passes the tunnel interface as `TUNDEV`.

Override these if the tunnel interface, auth group, or base vpnc script differs:

```bash
VPN_INTERFACE="tun0"
DISABLE_DNS_OVER_TLS=1
OPENCONNECT_SCRIPT_BASE="/etc/vpnc/vpnc-script"
```

## Usage

```bash
omarchy-work-vpn connect
omarchy-work-vpn disconnect
omarchy-work-vpn status
omarchy-work-vpn command
```

The Waybar icon runs `omarchy-work-vpn toggle`.

`omarchy-work-vpn command` prints the exact OpenConnect command without passwords or two-factor codes. Use it to verify that your `--authgroup` value is being passed.

## Notes

DTLS is OpenConnect's Datagram TLS transport for VPN traffic. It is unrelated to DNS-over-TLS. This wrapper does not disable DTLS by default because the manual TU flow only needed DNS-over-TLS disabled on `tun0`.

OpenConnect needs elevated privileges to create the tunnel and routes. If you want the click path to avoid a sudo password prompt after setup, add a narrowly scoped sudoers rule for OpenConnect on this machine rather than storing the sudo password.
