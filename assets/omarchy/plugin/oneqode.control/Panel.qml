import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "oneqode.control"
  ipcTarget: "oneqode.control"
  manageIpc: true

  property var status: Model.emptyStatus()
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool night: Model.isNight(status.theme)
  property bool lightMode: false
  readonly property bool showLabel: setting("showLabel", false) === true
  readonly property string themeValue: night ? "night" : (status.isOqTheme ? "day" : "")
  readonly property url logo: Qt.resolvedUrl(lightMode ? "assets/oneqode-ink.svg" : "assets/oneqode-mono.svg")
  readonly property url logoBrand: Qt.resolvedUrl(night ? "assets/oneqode-dark.svg" : "assets/oneqode-light.svg")

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/light.mode"
    watchChanges: true
    printErrors: false
    onLoaded: root.lightMode = true
    onLoadFailed: root.lightMode = false
    onFileChanged: reload()
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function runControl(args) {
    if (actionProc.running) return
    actionProc.command = ["oneqode-control"].concat(args)
    actionProc.running = true
  }

  onOpenedChanged: if (opened) refresh()
  Component.onCompleted: refresh()

  Process {
    id: statusProc
    command: ["oneqode-control", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.status = Model.parseStatus(text)
    }
  }

  Process {
    id: actionProc
    onExited: Qt.callLater(root.refresh)
  }

  Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
  Timer { interval: 2000; running: root.opened; repeat: true; onTriggered: root.refresh() }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: logoIcon
    tooltipText: "OneQode · " + root.status.themeLabel
    onPressed: function(b) {
      if (b === Qt.RightButton) root.runControl(["theme", "toggle"])
      else root.toggle()
    }
  }

  Component {
    id: logoIcon
    Logo {
      anchors.fill: parent
      source: root.logo
      color: root.fg
      tint: true
    }
  }

  KeyboardPanel {
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: fittedContentWidth(Style.space(380))
    contentHeight: fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        PanelHero {
          title: "OneQode"
          meta: root.status.themeLabel + (root.status.autoEnabled ? " · " + root.status.period : "")
          detail: root.status.autoEnabled ? "AUTO" : "MANUAL"
          foreground: root.fg
          fontFamily: root.fontFamily
          iconComponent: Component {
            Logo {
              width: Style.font.display
              height: Style.font.display
              source: root.logoBrand
              color: root.fg
              tint: false
            }
          }
        }

        PanelSeparator { foreground: root.fg }

        PanelSectionHeader {
          text: "THEME"
          foreground: root.fg
          fontFamily: root.fontFamily
        }

        ButtonGroup {
          width: parent.width
          foreground: root.fg
          fontFamily: root.fontFamily
          value: root.themeValue
          options: [
            { value: "day", label: "Light Glass" },
            { value: "night", label: "Night Ride" }
          ]
          onChanged: function(v) { root.runControl(["theme", v]) }
        }

        Toggle {
          width: parent.width
          label: "Auto day / night"
          description: root.status.sunrise !== ""
            ? ("Sunrise " + root.status.sunrise + " · sunset " + root.status.sunset)
            : "Brisbane solar schedule"
          checked: root.status.autoEnabled
          foreground: root.fg
          fontFamily: root.fontFamily
          onClicked: root.runControl(["auto", "toggle"])
        }

        PanelSeparator { foreground: root.fg }

        PanelSectionHeader {
          text: "KEYBOARD"
          foreground: root.fg
          fontFamily: root.fontFamily
        }

        ButtonGroup {
          width: parent.width
          foreground: root.fg
          fontFamily: root.fontFamily
          value: root.status.effect
          options: [
            { value: "heatmap", label: "Heatmap" },
            { value: "solid", label: "Solid" },
            { value: "off", label: "Off" }
          ]
          onChanged: function(v) { root.runControl(["keyboard", "effect", v]) }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "Brightness  " + root.status.brightness + "%"
            color: Qt.darker(root.fg, 1.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }

          PanelSlider {
            width: parent.width
            bar: root.bar
            minimum: 20
            maximum: 100
            step: 10
            integer: true
            tickCount: 5
            value: root.status.brightness
            onReleased: function(v) {
              root.runControl(["keyboard", "brightness", String(Math.round(v))])
            }
          }
        }
      }
    }
  }
}
