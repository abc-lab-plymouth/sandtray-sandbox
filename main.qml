import QtQuick 2.3
import QtQuick.Window 2.2
import QtWebSockets 1.0

Window {
    id: window1
    visible: true
    visibility: Window.FullScreen
    function appendMessage(message) {
        messageBox.text += "\n" + message
    }
    WebSocketServer {
        id: server
        listen: true
        port: 42898
        onClientConnected: {
            webSocket.onTextMessageReceived.connect(function(message) {
                appendMessage(qsTr("Received: %1").arg(message));
                var cmd = JSON.parse(message)
                if(cmd["cmd"] === "gaze") {
                    if("x" in cmd) sandtray.gaze_x_position = cmd["x"]
                    if("y" in cmd) sandtray.gaze_y_position = cmd["y"]
                }
                if(cmd["cmd"] === "marker") {
                    if (sandtray.state == "marker_mode") {
                        sandtray.state = "";
                    } else {
                        sandtray.state = "marker_mode";
                    }
                }

                webSocket.sendTextMessage(qsTr("ack"));
            });
        }
        onErrorStringChanged: {
            appendMessage(qsTr("Server error: %1").arg(errorString));
        }
    }

    Rectangle {
        id: sandtray
        anchors.fill: parent
        visible: true

        // current position of the gaze, in mm. (0,0) is the center of the sandtray.
        property real gaze_x_position: 10
        property real gaze_y_position: 100

        MouseArea {
            anchors.fill: parent
            onClicked: {
                sandtray.state == "marker_mode" ? sandtray.state = "" : sandtray.state = "marker_mode";
            }
            drag {
                target: gaze_tracker
                axis: Drag.XandYAxis
            }
        }

        Text {
            id: messageBox
            text: "Sandtray websocket server: " + server.url
        }

        Rectangle {
            id: gaze_tracker
            color: "orange"
            width: 40; height: 40
            radius: 20
            x: Screen.width / 2 + Screen.pixelDensity * sandtray.gaze_x_position - gaze_tracker.width / 2
            y: Screen.height / 2 + Screen.pixelDensity * sandtray.gaze_y_position - gaze_tracker.height / 2

            Rectangle {
                color: "yellow"
                width: 6; height: 6
                radius: 3
                anchors.centerIn: parent
            }
        }

        Rectangle {
            id: marker
            anchors.fill:parent
            anchors.centerIn: parent
            color: "white"

            opacity: 0.0

            Image {
                width: Screen.pixelDensity * 250
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                source: "rc/709.png"
            }

            Timer {
                interval: 2000; running:parent.opacity === 1.0; repeat:false
                onTriggered: sandtray.state = ""
            }
        }

        states: [
            State {
                name: "marker_mode"
                PropertyChanges { target: marker; opacity: 1.0 }
            }
        ]

        transitions: [
            Transition {
                NumberAnimation { target: marker
                    properties: "opacity"; duration: 200;easing.type: Easing.InOutQuad   }
            }]
    }

}
