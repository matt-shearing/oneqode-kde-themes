import QtQuick
import QtQuick.Shapes
import qs.Commons

// The official knot, drawn as a path so the fill is always `color`.
// Qt SVG + MultiEffect does not reliably recolor this mark in the bar.
Item {
  id: root
  property url source: ""
  property color color: Color.bar.text
  property bool tint: true

  readonly property real vbW: 131.23
  readonly property real vbH: 131.21
  readonly property string knotPath: "m124.11,35.96c-7.92-15.62-21.45-27.23-38.1-32.67C69.35-2.16,51.58-.8,35.95,7.12,20.33,15.05,8.73,28.58,3.28,45.23c-5.45,16.65-4.08,34.42,3.84,50.05,7.92,15.62,21.45,27.23,38.1,32.67,6.69,2.19,13.57,3.26,20.41,3.26,11.22,0,22.29-2.92,32.18-8.5-2.11.4-4.23.61-6.31.61-4.2,0-8.28-.78-12.05-2.29l-11.46-4.62c-6.07.28-12.23-.52-18.19-2.46-12.91-4.22-23.4-13.22-29.55-25.33-6.14-12.11-7.2-25.9-2.98-38.81C26,23.16,54.77,8.57,81.42,17.28c12.91,4.22,23.4,13.22,29.55,25.33,6.14,12.11,7.2,25.9,2.98,38.81-.52,1.6-1.79,4.68-1.79,4.68h0c-6.73,15.96-17.95,19.97-25.49,16.96l-31.42-12.67c-12.83-5.35-19.48-19.9-15.16-33.13,2.23-6.82,6.98-12.36,13.38-15.61,6.4-3.24,13.69-3.8,20.5-1.57,6.82,2.23,12.36,6.98,15.61,13.38,3.24,6.4,3.8,13.68,1.57,20.5-2.3,7.03-7.24,12.67-13.91,15.87-1.92.92-3.94,1.58-6.01,2.02,0,0,18.26,7.27,18.85,7.37,7.04-5.1,12.3-12.22,15.07-20.68,3.45-10.56,2.59-21.83-2.44-31.74-5.03-9.91-13.61-17.27-24.17-20.72-10.56-3.46-21.83-2.59-31.74,2.44-9.91,5.03-17.27,13.61-20.72,24.17-6.7,20.48,3.62,43.02,23.57,51.34l31.53,12.71c14.49,5.78,34.43-.92,44.58-24.98,0,0,1.55-3.8,2.19-5.75,5.45-16.65,4.08-34.42-3.84-50.05Z"

  Image {
    anchors.fill: parent
    source: root.source
    sourceSize.width: Math.round(width * 2)
    sourceSize.height: Math.round(height * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    visible: !root.tint
  }

  Shape {
    visible: root.tint
    width: root.vbW
    height: root.vbH
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    transform: Scale {
      xScale: root.width > 0 ? root.width / root.vbW : 1
      yScale: root.height > 0 ? root.height / root.vbH : 1
    }

    ShapePath {
      fillColor: root.color
      strokeWidth: 0
      PathSvg { path: root.knotPath }
    }
  }
}
