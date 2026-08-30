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
  readonly property color fg: bar ? bar.barForeground : Color.bar.text
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool night: Model.isNight(status.theme)
  readonly property bool showLabel: setting("showLabel", false) === true
  readonly property string themeValue: night ? "night" : (status.isOqTheme ? "day" : "")
  readonly property url logoBrand: Qt.resolvedUrl(night ? "assets/oneqode-dark.svg" : "assets/oneqode-light.svg")
  readonly property string locationPreset: Model.locationPreset(status.location.timezone)
  readonly property string locationTitle: Model.locationLabel(status.location)

  property bool editingLocation: false
  property bool savingLocation: false
  property var locationSuggestions: []
  property int suggestionIndex: 0

  function controlInvocation(args) {
    return ["bash", "-c",
      'cmd="$HOME/.local/bin/oneqode-control"; if [ ! -x "$cmd" ]; then cmd=oneqode-control; fi; exec "$cmd" "$@"',
      "oneqode-control"].concat(args)
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function runControl(args) {
    if (actionProc.running) return
    actionProc.command = controlInvocation(args)
    actionProc.running = true
  }

  function startEditingLocation() {
    editingLocation = true
    savingLocation = false
    locationSuggestions = []
    suggestionIndex = 0
    Qt.callLater(function() {
      locationField.text = root.locationTitle === "Not set" ? "" : root.status.location.name
      locationField.selectAll()
      locationField.forceActiveFocus()
    })
  }

  function cancelEditingLocation() {
    editingLocation = false
    savingLocation = false
    locationSuggestions = []
    suggestionIndex = 0
    searchDebounce.stop()
    Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
  }

  function requestSearch() {
    var query = locationField.text.trim()
    if (query.length < 2) {
      locationSuggestions = []
      return
    }
    if (searchProc.running) searchProc.running = false
    searchProc.command = controlInvocation(["location", "search", query])
    searchProc.running = true
  }

  function commitSuggestion(item) {
    if (!item || !item.timezone) return
    savingLocation = true
    editingLocation = false
    locationSuggestions = []
    runControl(["location", "set", item.name, String(item.latitude), String(item.longitude), item.timezone])
  }

  function commitHighlighted() {
    var item = Model.locationCommit(locationSuggestions, suggestionIndex)
    if (item) commitSuggestion(item)
  }

  function applyPreset(value) {
    savingLocation = true
    editingLocation = false
    locationSuggestions = []
    runControl(["location", "preset", value])
  }

  onOpenedChanged: if (opened) refresh(); else cancelEditingLocation()
  Component.onCompleted: refresh()

  Process {
    id: statusProc
    command: root.controlInvocation(["status", "--json"])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.status = Model.parseStatus(text)
        if (!root.editingLocation) root.savingLocation = false
      }
    }
  }

  Process {
    id: actionProc
    onExited: {
      root.savingLocation = false
      Qt.callLater(root.refresh)
    }
  }

  Process {
    id: searchProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.locationSuggestions = root.editingLocation ? Model.parseLocationSearch(text) : []
        root.suggestionIndex = 0
      }
    }
  }

  Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
  Timer { interval: 2000; running: root.opened; repeat: true; onTriggered: root.refresh() }
  Timer {
    id: searchDebounce
    interval: 300
    onTriggered: root.requestSearch()
  }

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
      blocked: root.editingLocation
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
            : "Solar schedule"
          checked: root.status.autoEnabled
          foreground: root.fg
          fontFamily: root.fontFamily
          onClicked: root.runControl(["auto", "toggle"])
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          Item {
            visible: !root.editingLocation
            width: parent.width
            height: idleLoc.implicitHeight

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.startEditingLocation()
            }

            Row {
              id: idleLoc
              width: parent.width
              spacing: Style.space(8)

              Text {
                text: "Location"
                color: Qt.darker(root.fg, 1.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.2
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: root.locationTitle
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                visible: root.status.location.timezone !== ""
                text: root.status.location.timezone
                color: Qt.darker(root.fg, 1.5)
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          TextField {
            id: locationField
            visible: root.editingLocation
            width: parent.width
            enabled: !root.savingLocation
            placeholderText: "Search city"
            foreground: root.fg
            font.family: root.fontFamily
            onTextChanged: if (root.editingLocation && !root.savingLocation) searchDebounce.restart()
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                root.cancelEditingLocation()
                event.accepted = true
              } else if (event.key === Qt.Key_Down) {
                if (root.suggestionIndex < root.locationSuggestions.length - 1)
                  root.suggestionIndex++
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                if (root.suggestionIndex > 0) root.suggestionIndex--
                event.accepted = true
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.commitHighlighted()
                event.accepted = true
              }
            }
          }

          Column {
            visible: root.editingLocation && !root.savingLocation && root.locationSuggestions.length > 0
            width: parent.width
            spacing: 0

            Repeater {
              model: root.locationSuggestions

              Rectangle {
                required property var modelData
                required property int index
                width: parent.width
                height: suggestionRow.implicitHeight + Style.space(12)
                radius: Style.cornerRadius
                color: index === root.suggestionIndex
                  ? Style.hoverFillFor(root.fg, Color.accent)
                  : "transparent"

                Row {
                  id: suggestionRow
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(8)

                  Text {
                    text: modelData.name
                    color: index === root.suggestionIndex
                      ? Style.hoverStateColor(root.fg, Color.accent)
                      : root.fg
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                  Text {
                    visible: text !== ""
                    text: modelData.description
                    color: Qt.darker(root.fg, 1.5)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onPositionChanged: root.suggestionIndex = index
                  onClicked: root.commitSuggestion(modelData)
                }
              }
            }
          }

          ButtonGroup {
            visible: root.editingLocation
            width: parent.width
            foreground: root.fg
            fontFamily: root.fontFamily
            value: root.locationPreset
            options: [
              { value: "brisbane", label: "Brisbane" },
              { value: "hong-kong", label: "Hong Kong" },
              { value: "sydney", label: "Sydney" }
            ]
            onChanged: function(v) { root.applyPreset(v) }
          }
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
