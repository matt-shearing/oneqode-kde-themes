/*
    SPDX-FileCopyrightText: 2024 OneQode
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Window 2.15

Rectangle {
    id: root
    color: "#1A1A2E"

    property int stage

    onStageChanged: {
        if (stage == 1) {
            introAnimation.running = true
        }
    }

    // Subtle gradient overlay (synthwave style)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1A1A2E" }
            GradientStop { position: 0.5; color: "#16213E" }
            GradientStop { position: 1.0; color: "#0F0F1A" }
        }
    }

    // Center content
    Item {
        id: content
        anchors.centerIn: parent
        width: 400
        height: 200
        opacity: 0

        // Logo text
        Text {
            id: logoText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: 20
            text: "OneQode"
            font.family: "Inter"
            font.pixelSize: 48
            font.weight: Font.Light
            color: "#FFFFFF"
        }

        // Tagline
        Text {
            id: tagline
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logoText.bottom
            anchors.topMargin: 8
            text: "Night Ride"
            font.family: "Inter"
            font.pixelSize: 16
            font.weight: Font.Normal
            color: "#FF00FF"
        }

        // Progress bar
        Rectangle {
            id: progressBar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: tagline.bottom
            anchors.topMargin: 40
            width: 200
            height: 2
            color: "#2A2A4A"
            radius: 1

            Rectangle {
                id: progressFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: (root.stage / 6) * parent.width
                radius: 1

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#FF00FF" }
                    GradientStop { position: 1.0; color: "#00D4FF" }
                }

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    // Intro animation
    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: 500
        easing.type: Easing.InOutQuad
    }
}
