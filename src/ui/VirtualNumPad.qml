import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: numPadPopup
    
    // Properties to interface with
    property var targetField: null
    property string displayText: ""
    
    // Internal state
    // We bind to the target field's text, but we might want to edit a buffer
    // For simplicity, let's edit the targetField directly or emission signals
    
    signal input(string key)
    signal backspace()
    signal clear()
    signal submit()
    
    modal: true
    focus: true
    dim: true
    closePolicy: Popup.CloseOnPressOutside
    
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 300
    height: 400
    
    background: Rectangle {
        color: "#222"
        border.color: "#40C4FF" // primaryColor
        border.width: 2
        radius: 10
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10
        
        // Display area (preview)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#111"
            border.color: "#444"
            radius: 5
            
            Text {
                anchors.centerIn: parent
                text: numPadPopup.targetField ? numPadPopup.targetField.text : ""
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }
        }
        
        // Keypad Grid
        GridLayout {
            columns: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            rowSpacing: 10
            columnSpacing: 10
            
            // Helper component for keys
            component KeyBtn: Button {
                property string keyVal: text
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                background: Rectangle {
                    color: parent.pressed ? "#40C4FF" : "#333"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.pressed ? "black" : "white"
                    font.pixelSize: 24
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                   if (numPadPopup.targetField) {
                       numPadPopup.targetField.text = numPadPopup.targetField.text + keyVal
                   }
                }
            }
            
            KeyBtn { text: "1" }
            KeyBtn { text: "2" }
            KeyBtn { text: "3" }
            
            KeyBtn { text: "4" }
            KeyBtn { text: "5" }
            KeyBtn { text: "6" }
            
            KeyBtn { text: "7" }
            KeyBtn { text: "8" }
            KeyBtn { text: "9" }
            
            // Bottom Row
            KeyBtn { text: "." }
            KeyBtn { text: "0" }
            
            // Backspace
            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: Rectangle {
                    color: parent.pressed ? "#FF3D00" : "#442"
                    radius: 5
                }
                contentItem: Text {
                    text: "←" // or icon
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (numPadPopup.targetField && numPadPopup.targetField.text.length > 0) {
                        numPadPopup.targetField.text = numPadPopup.targetField.text.slice(0, -1)
                    }
                }
            }
        }
        
        // Action Row
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 10
            
            Button {
                text: "Clear"
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: Rectangle { color: "#444"; radius: 5 }
                contentItem: Text { text: "Clear"; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: if (numPadPopup.targetField) numPadPopup.targetField.text = ""
            }
            
            Button {
                text: "OK"
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: Rectangle { color: "#40C4FF"; radius: 5 }
                contentItem: Text { text: "OK"; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: {
                    numPadPopup.submit()
                    numPadPopup.close()
                }
            }
        }
    }
}
