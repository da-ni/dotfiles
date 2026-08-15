# Work VPN

`omarchy-work-vpn` wraps OpenConnect for a one-click Omarchy workflow:

- native Omarchy shell widget
- private local config in `~/.config/work-vpn/config`
- password stored in the Secret Service keyring via `secret-tool`
- two-factor code prompted on each connection

## Setup

Install OpenConnect:

```bash
yay -S openconnect
```

Install the root-owned helper and its narrowly scoped sudo rule once:

```bash
sudo install -Dm755 system/usr/local/libexec/omarchy-work-vpn-privileged /usr/local/libexec/omarchy-work-vpn-privileged
sudo install -Dm440 system/etc/sudoers.d/omarchy-work-vpn /etc/sudoers.d/omarchy-work-vpn
sudo visudo -cf /etc/sudoers.d/omarchy-work-vpn
```

Connect uses Quattro's built-in Polkit agent for its native administrator
password prompt. The sudoers rule grants passwordless access only to the
root-owned helper's no-argument `disconnect` operation. It does not grant
passwordless access to Connect, the user-editable launcher, or arbitrary
OpenConnect commands.

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

Clicking the Quattro widget opens a native panel with connection status and
Connect, Disconnect, and Configure actions. Password and OTP prompts remain
graphical. Connect uses Quattro's Polkit password panel; Disconnect does not
need an administrator password.

The plugin is stored in the dotfiles, but its bar placement remains a local
Quattro setting. Enable it once after applying the dotfiles:

```bash
omarchy plugin enable dn.work-vpn --section right --before omarchy.network
```

`omarchy-work-vpn command` prints the exact OpenConnect command without passwords or two-factor codes. Use it to verify that your `--authgroup` value is being passed.

## Notes

DTLS is OpenConnect's Datagram TLS transport for VPN traffic. It is unrelated to DNS-over-TLS. This wrapper does not disable DTLS by default because the manual TU flow only needed DNS-over-TLS disabled on `tun0`.

OpenConnect needs elevated privileges to create the tunnel and routes. If you want the click path to avoid a sudo password prompt after setup, add a narrowly scoped sudoers rule for OpenConnect on this machine rather than storing the sudo password.
