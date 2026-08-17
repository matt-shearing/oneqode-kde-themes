import QtQuick
import QtQuick.Effects
import qs.Commons

Item {
  id: root
  property url source: ""
  property color color: Color.foreground
  property bool tint: true

  Image {
    id: src
    anchors.fill: parent
    source: root.source
    sourceSize.width: Math.round(width * 2)
    sourceSize.height: Math.round(height * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    visible: !root.tint
  }

  MultiEffect {
    anchors.fill: src
    source: src
    visible: root.tint
    colorization: 1.0
    colorizationColor: root.color
  }
}
