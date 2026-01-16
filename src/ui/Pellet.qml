import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: pelletPage
    background: Rectangle { color: window.backgroundColor }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "Pellet Manager"
            color: window.textColor
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            // Pellet Level Visualization
            Rectangle {
                Layout.preferredWidth: 100
                Layout.fillHeight: true
                color: window.surfaceColor
                radius: 10
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height * (bridge.hopper.req ? 0.2 : 0.8) // Low if req is true
                    color: bridge.hopper.req ? "#FF3D00" : window.primaryColor
                    radius: 10
                    
                    Text {
                        anchors.centerIn: parent
                        text: bridge.hopper.req ? "REFILL" : "OK"
                        color: "white"
                        font.bold: true
                    }
                }
            }

            // Pellet Details
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                
                Label { 
                    text: "Current Profile: Apple Wood" 
                    color: window.textColor 
                    font.pixelSize: 18
                }

                Label { 
                    text: bridge.outpins["auger"] ? "Auger: RUNNING" : "Auger: IDLE" 
                    color: bridge.outpins["auger"] ? "#00E676" : "#777"
                    font.pixelSize: 16
                    font.bold: true
                }
                
                Button {
                    text: "Change Profile"
                    flat: true
                    contentItem: Text { text: parent.text; color: window.primaryColor; font.pixelSize: 18 }
                }
            }
        }
    }
}
