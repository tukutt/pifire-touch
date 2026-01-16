import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 480
    minimumWidth: 800
    minimumHeight: 480
    maximumWidth: 800
    maximumHeight: 480
    title: "PiFire Touch"
    color: "#000000"

    // Define global palette
    property color primaryColor: "#40C4FF" // Cyan / Light Blue A400
    property color accentColor: "#FF3D00" // Deep Orange / Red for active Selection
    property color backgroundColor: "#000000"
    property color surfaceColor: "#121212" // Very dark grey for bars
    property color textColor: "#FFFFFF"
    property color inactiveColor: "#90A4AE" // Light grey for inactive items
    
    // Font Loader for FontAwesome
    FontLoader {
        id: faFont
        source: "../assets/fonts/FA-Free-Solid.otf"
    }

    // Global Strings
    Strings { id: stringsComp }
    property alias strings: stringsComp

    // Status Bar
    Rectangle {
        id: statusBar
        width: parent.width
        height: 60
        color: "transparent"
        z: 10 
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            
            // LEFT: CLOCK (Moved from Right)
            Text {
                id: clockText
                text: Qt.formatTime(new Date(), "hh:mm")
                color: textColor
                font.pixelSize: 32
                font.bold: true
                
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            Item { Layout.fillWidth: true }
            
            // CENTER: Hardware Icons & P-Mode
            RowLayout {
                spacing: 40
                Layout.alignment: Qt.AlignCenter
                
                // Fan
                Text {
                    text: "\uf863" 
                    font.family: faFont.name
                    font.pixelSize: 28
                    color: bridge.outpins["fan"] ? "#00E676" : "#444" 
                    visible: true
                    
                    RotationAnimation on rotation {
                        from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                        running: bridge.outpins["fan"]
                    }
                }

                // Auger
                Text {
                    text: "\uf101" 
                    font.family: faFont.name
                    font.pixelSize: 28
                    color: bridge.outpins["auger"] ? "#00E676" : "#444"
                    
                    width: 28
                    height: 28
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    opacity: bridge.outpins["auger"] ? 1.0 : 1.0
                    
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: bridge.outpins["auger"]
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                    }
                }

                // Igniter
                Text {
                    text: "\uf06d" 
                    font.family: faFont.name
                    font.pixelSize: 28
                    color: bridge.outpins["igniter"] ? "#FF3D00" : "#444"
                    opacity: bridge.outpins["igniter"] ? 1.0 : 0.5
                    
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: bridge.outpins["igniter"]
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                    }
                }
                
                // P-Mode
                // P-Mode / Lid Indicator
                Item {
                    width: 50; height: 30
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                             if (bridge.mode === "Smoke") {
                                 pModePopup.open()
                             }
                        }
                    }

                    // Case 1: P-Mode (Not in Hold)
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        visible: bridge.mode !== "Hold"
                        Text {
                            text: "P"
                             color: "#888"
                             font.pixelSize: 24
                             font.bold: true
                        }
                        Text {
                            text: bridge.pMode
                            color: window.primaryColor
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }
                    
                    // Case 2: Lid (In Hold)
                    Text {
                        anchors.centerIn: parent
                        visible: bridge.mode === "Hold"
                        text: bridge.lidOpen ? "\uf52b" : "\uf52a" // Door Open / Door Closed
                        font.family: faFont.name
                        font.pixelSize: 28
                        color: bridge.lidOpen ? "#D32F2F" : "#777" // Red if open, Gray if closed
                    }
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // RIGHT: COOK TIMER (Chrono)
            Text {
                id: chronoText
                property int elapsedSeconds: 0
                
                visible: bridge.startTime > 0 && bridge.mode !== "Stop" && bridge.mode !== "Error"
                text: {
                    var h = Math.floor(elapsedSeconds / 3600);
                    var m = Math.floor((elapsedSeconds % 3600) / 60);
                    var s = elapsedSeconds % 60;
                    return (h < 10 ? "0"+h : h) + ":" + (m < 10 ? "0"+m : m) + ":" + (s < 10 ? "0"+s : s)
                }
                color: "#448AFF"
                font.pixelSize: 28
                font.bold: true
                
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: {
                        if (bridge.startTime > 0) {
                            var now = new Date().getTime() / 1000;
                            chronoText.elapsedSeconds = Math.max(0, Math.floor(now - bridge.startTime));
                        } else {
                            chronoText.elapsedSeconds = 0;
                        }
                    }
                }
            }
        }
    }

    // Main Content + Sidebar Layout
    RowLayout {
        anchors.top: statusBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom 
        spacing: 0

        // LEFT SIDEBAR
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 90
            color: "#080808"
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                
                // Helper for Side Button
                component SideButton: Button {
                    id: sBtn
                    property string iconCode: ""
                    property string labelText: "Label"
                    property int targetIndex: 0
                    property var targetComponent: null
                    
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    checkable: true
                    // Exclusive Group Logic managed manually or via ButtonGroup if we added one, 
                    // but simple logic: Uncheck others when clicked is fine, OR use autoExclusive property if we share a parent?
                    // Best way: Bind checked state to a centralized 'currentIndex' property.
                    checked: mainNavIndex === targetIndex
                    
                    background: Rectangle { 
                        color: sBtn.checked ? "#1A1A1A" : "transparent"
                        
                        // Active indicator line on left
                        Rectangle {
                            width: 4; height: parent.height
                            anchors.left: parent.left
                            color: window.accentColor
                            visible: sBtn.checked
                        }
                    }
                    
                    contentItem: ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: iconCode
                            font.family: faFont.name 
                            font.pixelSize: 28 
                            color: sBtn.checked ? window.accentColor : inactiveColor
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: labelText
                            font.pixelSize: 12
                            color: sBtn.checked ? window.accentColor : inactiveColor
                            font.bold: sBtn.checked
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    onClicked: {
                        if (mainNavIndex !== targetIndex) {
                            mainNavIndex = targetIndex
                            if (targetComponent) stackView.replace(targetComponent)
                        }
                    }
                }

                // NAVIGATION ITEMS
                SideButton { 
                    iconCode: "\uf3fd"; labelText: strings.nav_dashboard
                    targetIndex: 0; targetComponent: dashboardTab 
                }
                SideButton { 
                    iconCode: "\uf201"; labelText: strings.nav_history
                    targetIndex: 1; targetComponent: graphTab 
                }
                SideButton { 
                    iconCode: "\uf1b3"; labelText: strings.nav_pellets 
                    targetIndex: 2; targetComponent: pelletTab 
                }
                SideButton { 
                    iconCode: "\uf02d"; labelText: strings.nav_recipe 
                    targetIndex: 3; targetComponent: recipeTab 
                }
                
                // Spacer to push settings to bottom? Or just keep list top aligned
                Item { Layout.fillHeight: true }

                SideButton { 
                    iconCode: "\uf013"; labelText: strings.nav_settings 
                    targetIndex: 4; targetComponent: settingsTab 
                }
            }
            
            // Vertical Divider
            Rectangle {
                width: 1; height: parent.height
                anchors.right: parent.right
                color: "#222"
            }
        }

        // MAIN CONTENT
        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: dashboardTab 
            clip: true // Important since sidebar is overlaying or next to it
            
            // Define Transitions
            pushEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            pushExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }
            replaceEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            replaceExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }

            // Define Components 
            Component { id: dashboardTab; Dashboard {} }
            Component { id: graphTab; Graph {} }
            Component { id: pelletTab; Pellet {} }
            Component { 
                id: recipeTab
                Item {
                    Text {
                        anchors.centerIn: parent
                        text: "Recette\n(À implémenter)"
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 20
                    }
                }
            }
            Component { id: settingsTab; ControlPanel {} }
        }
    }

    // P-Mode Selection Popup
    Popup {
        id: pModePopup
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 400
        height: 300
        modal: true
        dim: true
        enter: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 200 } }
        
        background: Rectangle {
            color: "#222"
            border.color: window.primaryColor
            border.width: 2
            radius: 12
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            
            Text {
                text: "Sélection Mode P"
                color: window.primaryColor
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            GridLayout {
                columns: 5
                rowSpacing: 10
                columnSpacing: 10
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Repeater {
                    model: 10 // 0 to 9
                    delegate: Button {
                        text: index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        background: Rectangle {
                            color: "#333"
                            radius: 8
                            border.color: "#444"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: 20
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            bridge.setPMode(index)
                            pModePopup.close()
                        }
                    }
                }
            }
            
            // Cancel Button
            Button {
                text: "Annuler"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                background: Rectangle {
                    color: "#444"
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: pModePopup.close()
            }
        }
    }

    // STATE TRACKING
    property int mainNavIndex: 0
}
