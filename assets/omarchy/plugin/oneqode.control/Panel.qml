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
  manageIpc: false

  property var status: Model.emptyStatus()
  property bool cursorActive: false
  property int focusIndex: 0
  readonly property bool night: Model.isNight(status.theme)
  readonly property bool showLabel: setting("showLabel", false) === true
  readonly property var themeChoices: [
    { id: "day", label: "Light Glass" },
    { id: "night", label: "Night Ride" }
  ]
  readonly property var effectChoices: [
    { id: "heatmap", label: "Heatmap" },
    { id: "solid", label: "Solid" },
    { id: "off", label: "Off" }
  ]
  readonly property var brightnessChoices: [40, 70, 100]
  readonly property int controlCount: 8

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function runControl(args) {
    if (actionProc.running) return
    actionProc.command = ["oneqode-control"].concat(args)
    actionProc.running = true
  }

  function setTheme(which) { runControl(["theme", which]) }
  function setAuto(which) { runControl(["auto", which]) }
  function setEffect(which) { runControl(["keyboard", "effect", which]) }
  function setBrightness(value) { runControl(["keyboard", "brightness", String(value)]) }

  function activateFocused() {
    if (focusIndex === 0) setTheme("day")
    else if (focusIndex === 1) setTheme("night")
    else if (focusIndex === 2) setAuto(status.autoEnabled ? "off" : "on")
    else if (focusIndex === 3) setEffect("heatmap")
    else if (focusIndex === 4) setEffect("solid")
    else if (focusIndex === 5) setEffect("off")
    else if (focusIndex === 6) setBrightness(70)
    else if (focusIndex === 7) setBrightness(100)
  }

  IpcHandler {
    target: "oneqode.control"
    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
  }

  onOpenedChanged: if (opened) refresh()

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

  Timer { interval: 4000; running: true; repeat: true; onTriggered: root.refresh() }
  Timer { interval: 2000; running: root.opened; repeat: true; onTriggered: root.refresh() }

  Component.onCompleted: refresh()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.showLabel ? "OQ" : "◈"
    slotSize: Style.bar.iconSlot * (root.showLabel ? 1.6 : 1)
    tooltipText: "OneQode · " + root.status.themeLabel
    onPressed: function(b) {
      if (b === Qt.RightButton) root.setTheme("toggle")
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        root.cursorActive = true
        if (dx !== 0) root.focusIndex = Math.max(0, Math.min(root.controlCount - 1, root.focusIndex + dx))
        else if (dy !== 0) root.focusIndex = Math.max(0, Math.min(root.controlCount - 1, root.focusIndex + dy))
      }
      onActivateRequested: if (root.cursorActive) root.activateFocused()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroMark.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroMark
            text: "◈"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroMark.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "OneQode"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
            }

            Text {
              text: root.status.themeLabel + (root.status.autoEnabled ? " · auto " + root.status.period : " · manual")
              color: root.bar.foreground
              opacity: 0.65
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(20)
          Column {
            width: (parent.width - parent.spacing) / 2
            spacing: Style.spacing.labelGap
            InfoPair { label: "Sunrise"; value: root.status.sunrise || "—" }
            InfoPair { label: "Sunset"; value: root.status.sunset || "—" }
          }
          Column {
            width: (parent.width - parent.spacing) / 2
            spacing: Style.spacing.labelGap
            InfoPair { label: "Keyboard"; value: root.status.keyboardPresent ? "Framework 16" : "Not found" }
            InfoPair { label: "Lights"; value: root.status.effect + " · " + root.status.brightness + "%" }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "THEME"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            id: themeRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing) / 2

            Repeater {
              model: root.themeChoices
              Button {
                required property var modelData
                required property int index
                width: themeRow.cellWidth
                text: modelData.label
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: (modelData.id === "night" && root.night) || (modelData.id === "day" && !root.night && root.status.isOqTheme)
                hasCursor: root.cursorActive && root.focusIndex === index
                onClicked: root.setTheme(modelData.id)
                onHovered: function(h) { if (h) { root.cursorActive = true; root.focusIndex = index } }
              }
            }
          }

          Button {
            width: parent.width
            text: root.status.autoEnabled ? "Auto day / night is on" : "Auto day / night is off"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            active: root.status.autoEnabled
            hasCursor: root.cursorActive && root.focusIndex === 2
            onClicked: root.setAuto("toggle")
            onHovered: function(h) { if (h) { root.cursorActive = true; root.focusIndex = 2 } }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "KEYBOARD"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            id: effectRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing * 2) / 3

            Repeater {
              model: root.effectChoices
              Button {
                required property var modelData
                required property int index
                width: effectRow.cellWidth
                text: modelData.label
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: root.status.effect === modelData.id
                hasCursor: root.cursorActive && root.focusIndex === (3 + index)
                onClicked: root.setEffect(modelData.id)
                onHovered: function(h) { if (h) { root.cursorActive = true; root.focusIndex = 3 + index } }
              }
            }
          }

          Row {
            id: brightRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing * 2) / 3

            Repeater {
              model: root.brightnessChoices
              Button {
                required property var modelData
                required property int index
                width: brightRow.cellWidth
                text: modelData + "%"
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: root.status.brightness === modelData
                hasCursor: root.cursorActive && root.focusIndex === (6 + Math.min(index, 1))
                onClicked: root.setBrightness(modelData)
              }
            }
          }
        }
      }
    }
  }

  component InfoPair: Row {
    property string label: ""
    property string value: ""
    width: parent.width
    spacing: Style.space(8)
    Text {
      text: label
      color: root.bar.foreground
      opacity: 0.6
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
    Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
    Text {
      text: value
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }
}
