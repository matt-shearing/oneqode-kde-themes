/*
    SPDX-FileCopyrightText: 2024 OneQode
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Window 2.15

Rectangle {
    id: root
    color: "#F5F5F5"

    property int stage

    onStageChanged: {
        if (stage == 1) {
            introAnimation.running = true
        }
    }

    // Subtle gradient overlay
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#FFFFFF" }
            GradientStop { position: 1.0; color: "#E8E8E8" }
        }
        opacity: 0.7
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
            color: "#333333"
        }

        // Tagline
        Text {
            id: tagline
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logoText.bottom
            anchors.topMargin: 8
            text: "Light Glass"
            font.family: "Inter"
            font.pixelSize: 16
            font.weight: Font.Normal
            color: "#00D4FF"
        }

        // Progress bar
        Rectangle {
            id: progressBar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: tagline.bottom
            anchors.topMargin: 40
            width: 200
            height: 2
            color: "#E0E0E0"
            radius: 1

            Rectangle {
                id: progressFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: (root.stage / 6) * parent.width
                color: "#00D4FF"
                radius: 1

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
