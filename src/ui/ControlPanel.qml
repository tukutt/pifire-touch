import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: settingsPage
    background: Rectangle { color: window.backgroundColor }

    header: ToolBar {
        background: Rectangle { color: window.surfaceColor }
        RowLayout {
            anchors.fill: parent
            Text {
                text: window.strings.settings_title
                color: window.textColor
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 20
        contentHeight: settingsCol.height
        clip: true

        ColumnLayout {
            id: settingsCol
            width: parent.width
            spacing: 15

            // --- LANGUAGE ---
            Rectangle {
                Layout.fillWidth: true
                height: 70
                color: window.surfaceColor
                radius: 10
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: window.strings.settings_language
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text {
                            text: window.strings.language === "fr" ? "Français" : "English"
                            color: "#888"
                            font.pixelSize: 14
                        }
                    }
                    
                    // Toggle Switch
                    Rectangle {
                        width: 120
                        height: 40
                        color: "transparent"
                        border.color: "#444"
                        border.width: 1
                        radius: 20
                        clip: true
                        
                        Row {
                            anchors.fill: parent
                            
                            // FR Option
                            Rectangle {
                                width: 60
                                height: 40
                                color: window.strings.language === "fr" ? window.primaryColor : "transparent"
                                radius: 20
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "FR"
                                    color: window.strings.language === "fr" ? "black" : "#888"
                                    font.bold: true
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: window.strings.setLang("fr")
                                }
                            }
                            
                            // EN Option
                            Rectangle {
                                width: 60
                                height: 40
                                color: window.strings.language === "en" ? window.primaryColor : "transparent"
                                radius: 20
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "EN"
                                    color: window.strings.language === "en" ? "black" : "#888"
                                    font.bold: true
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: window.strings.setLang("en")
                                }
                            }
                        }
                    }
                }
            }

            // --- SERVER ADDRESS ---
            Rectangle {
                Layout.fillWidth: true
                height: customIpField.visible ? 160 : 100
                color: window.surfaceColor
                radius: 10
                Behavior on height { NumberAnimation { duration: 200 } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: window.strings.settings_server_title
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    // Selection Buttons
                    RowLayout {
                        spacing: 10
                        Layout.fillWidth: true
                        
                        // Helper Component for Radio-like Button
                        component ServerOptionBtn: Rectangle {
                            id: sob
                            property string mode: ""
                            property string label: ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: 35
                            color: bridge.serverSelection === mode ? window.primaryColor : "transparent"
                            border.color: "#444"
                            border.width: 1
                            radius: 8
                            
                            Text {
                                anchors.centerIn: parent
                                text: parent.label
                                color: bridge.serverSelection === parent.mode ? "black" : "#BBB"
                                font.bold: true
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: bridge.setServerConfig(sob.mode, customIpField.text)
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        ServerOptionBtn { mode: "pifire"; label: "pifire.local" }
                        ServerOptionBtn { mode: "localhost"; label: "localhost" }
                        ServerOptionBtn { mode: "custom"; label: "IP/URL..." }
                    }

                    // Custom IP Input
                    TextField {
                        id: customIpField 
                        Layout.fillWidth: true
                        placeholderText: window.strings.settings_server_placeholder
                        text: bridge.serverIp
                        visible: bridge.serverSelection === "custom"
                        color: "black" 
                        font.pixelSize: 16
                        
                        // Prevent native virtual keyboard from popping up if possible
                        inputMethodHints: Qt.ImhDigitsOnly 
                        readOnly: true // We use our custom keypad
                        
                        background: Rectangle {
                            color: "#EEE" 
                            border.color: customIpField.activeFocus ? window.primaryColor : "#ccc"
                            radius: 5
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                numPad.targetField = customIpField
                                numPad.open()
                            }
                        }

                        onEditingFinished: {
                             if (bridge.serverSelection === "custom") {
                                 bridge.setServerConfig("custom", text)
                                 focus = false
                             }
                        }
                    }
                    
                    VirtualNumPad {
                        id: numPad
                        parent: Overlay.overlay
                        onSubmit: {
                             if (bridge.serverSelection === "custom") {
                                 bridge.setServerConfig("custom", customIpField.text)
                             }
                        }
                    }
                    
                }
            }
        }
    }
}
