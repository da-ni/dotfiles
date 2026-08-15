import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui

Ui.Panel {
  id: root
  moduleName: "dn.work-vpn"

  property bool connected: false
  property bool busy: false
  property string vpnName: "Work VPN"
  property string lastError: ""
  property string otp: ""
  property bool otpOpen: false
  property int desiredConnected: -1
  readonly property bool displayConnected: desiredConnected === -1 ? connected : desiredConnected === 1
  readonly property bool transitioning: busy || desiredConnected !== -1
  readonly property string connectionState: {
    if (desiredConnected === 1 && !connected) return "Connecting…"
    if (desiredConnected === 0 && connected) return "Disconnecting…"
    return displayConnected ? "Connected" : "Disconnected"
  }
  readonly property int refreshIntervalSec: Math.max(2, Number(settings.refreshIntervalSec || 5))
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!statusProcess.running) statusProcess.running = true
  }

  function run(action) {
    if (busy) return
    if (action === "connect" && otp.trim() === "") {
      lastError = "Enter the one-time code first."
      otpField.forceActiveFocus()
      return
    }
    busy = true
    lastError = ""
    if (action === "connect") desiredConnected = 1
    else if (action === "disconnect") desiredConnected = 0
    actionProcess.command = action === "connect"
      ? ["omarchy-work-vpn", "connect", "--otp", otp.trim()]
      : ["omarchy-work-vpn", action]
    actionProcess.running = true
    if (action === "connect") otp = ""
    if (action === "connect" || action === "disconnect") transitionTimeout.restart()
  }

  onConnectedChanged: {
    if (connected) otpOpen = false
    if (desiredConnected !== -1 && connected === (desiredConnected === 1)) {
      desiredConnected = -1
      transitionTimeout.stop()
    }
  }

  Process {
    id: statusProcess
    command: ["omarchy-work-vpn", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          const status = JSON.parse(text || "{}")
          root.connected = String(status.class || "") === "connected"
          const firstLine = String(status.tooltip || "").split("\n")[0]
          if (firstLine) root.vpnName = firstLine.replace(/ (connected|disconnected)$/, "")
        } catch (error) {
          root.connected = false
        }
      }
    }
  }

  Process {
    id: actionProcess
    property string output: ""
    stdout: StdioCollector { onStreamFinished: actionProcess.output += text }
    stderr: StdioCollector { onStreamFinished: actionProcess.output += text }
    onRunningChanged: {
      if (running) {
        output = ""
      } else {
        root.busy = false
        if (exitCode !== 0) {
          root.lastError = String(output || "VPN action failed").trim()
          root.desiredConnected = -1
          transitionTimeout.stop()
        }
        actionProcess.command = []
        refreshDelay.restart()
      }
    }
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshDelay
    interval: 700
    repeat: true
    property int attempts: 0
    onTriggered: {
      root.refresh()
      attempts += 1
      if (attempts >= 8) stop()
    }
    onRunningChanged: if (running) attempts = 0
  }

  Timer {
    id: transitionTimeout
    interval: 15000
    onTriggered: root.desiredConnected = -1
  }

  Ui.BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.displayConnected ? "󰒘" : "󰦝"
    opacity: root.displayConnected ? 1.0 : 0.55
    onPressed: function() { root.toggle() }
  }

  Ui.KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: otpField
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(360))

    Column {
      id: content
      width: parent.width
      spacing: Style.spacing.panelGap

      Ui.PanelHero {
        width: parent.width
        title: "VPN"
        meta: root.connectionState
        foreground: root.foreground
        fontFamily: root.fontFamily
        iconOpacity: root.displayConnected ? 1.0 : 0.5
        iconComponent: Component {
          Text {
            text: root.displayConnected ? "󰒘" : "󰦝"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
          }
        }
        trailingControl: Component {
          Ui.ToggleSwitch {
            checked: root.displayConnected
            busy: root.transitioning
            foreground: root.foreground
            enabled: !root.transitioning && (root.connected || root.otp.trim() !== "")
            onToggled: root.run(root.connected ? "disconnect" : "connect")
          }
        }
      }

      Text {
        visible: root.lastError !== ""
        width: parent.width
        text: root.lastError
        color: root.urgent
        wrapMode: Text.WordWrap
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Ui.PanelSeparator {
        foreground: root.foreground
      }

      Column {
        width: parent.width
        spacing: Style.spacing.labelGap

        Ui.PanelSectionHeader {
          text: "KNOWN CONNECTIONS"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Ui.CursorSurface {
          id: connection
          width: parent.width
          current: root.displayConnected
          hasCursor: rowMouse.containsMouse
          foreground: root.foreground
          implicitHeight: rowBody.implicitHeight + (otpArea.visible ? otpArea.implicitHeight + Style.spacing.md : 0)

          MouseArea {
            id: rowMouse
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: rowBody.implicitHeight
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: !root.displayConnected && !root.transitioning ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: !root.transitioning
            onClicked: {
              if (root.displayConnected) return
              root.otpOpen = true
              Qt.callLater(function() { otpField.forceActiveFocus() })
            }
          }

          Item {
            id: rowBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            implicitHeight: Math.max(vpnIcon.implicitHeight, vpnInfo.implicitHeight, lockIndicator.implicitHeight) + Style.spacing.rowPaddingX

            Text {
              id: vpnIcon
              text: "󰒘"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: lockIndicator
              text: "󰌾"
              color: Qt.darker(root.foreground, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              id: vpnInfo
              spacing: Style.space(1)
              anchors.left: vpnIcon.right
              anchors.leftMargin: Style.space(10)
              anchors.right: lockIndicator.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter

              Text {
                text: root.vpnName
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                visible: root.displayConnected || root.transitioning
                height: visible ? implicitHeight : 0
                text: root.connectionState
                color: root.displayConnected ? root.foreground : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
                width: parent.width
              }
            }
          }

          Item {
            id: otpArea
            visible: root.otpOpen && !root.displayConnected
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: rowMouse.bottom
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            anchors.topMargin: Style.space(4)
            implicitHeight: otpField.implicitHeight + Style.spacing.rowGap

            Ui.TextField {
              id: otpField
              anchors.left: parent.left
              anchors.right: submitOtp.left
              anchors.top: parent.top
              anchors.rightMargin: Style.space(6)
              placeholderText: "One-time code"
              inputMethodHints: Qt.ImhDigitsOnly
              foreground: root.foreground
              enabled: !root.transitioning
              text: root.otp
              onTextChanged: if (text !== root.otp) root.otp = text
              onAccepted: root.run("connect")
              Keys.onEscapePressed: {
                root.otpOpen = false
                root.otp = ""
              }
            }

            Ui.PanelActionButton {
              id: submitOtp
              anchors.right: parent.right
              anchors.verticalCenter: otpField.verticalCenter
              iconText: "󰄬"
              tooltipText: "Connect"
              foreground: root.foreground
              fontFamily: root.fontFamily
              enabled: !root.transitioning && root.otp.trim() !== ""
              onClicked: root.run("connect")
            }
          }
        }

      }
    }
  }
}
