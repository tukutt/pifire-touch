import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: dashboardPage
    background: Rectangle { color: window.backgroundColor }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // COLUMN 1: PELLETS (Left)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 120
            color: window.surfaceColor
            radius: 12
            border.color: "#333"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10
                
                // Header Icon/Text
                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2
                    Text {
                        text: "\uf4c0" // Box/Bucket icon
                        font.family: faFont.name
                        font.pixelSize: 20
                        color: "#AAA"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: window.strings.nav_pellets
                        font.pixelSize: 12
                        font.bold: true
                        color: "#888"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // Vertical Bar Container
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#333" // Lighter background
                    radius: 8
                    border.color: "#444"
                    border.width: 1
                    clip: true
                    
                    // Fill (Animated)
                    Rectangle {
                        id: pelletFill
                        property int level: bridge.hopper["level"] !== undefined ? bridge.hopper["level"] : 50 
                        
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height * (level / 100)
                        radius: 8
                        
                        // Dynamic Color Gradient
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: pelletFill.level > 50 ? "#81C784" : (pelletFill.level > 20 ? "#FFF176" : "#E57373") } // Lighter tops
                            GradientStop { position: 1.0; color: pelletFill.level > 50 ? "#388E3C" : (pelletFill.level > 20 ? "#FBC02D" : "#D32F2F") } // Darker bottoms
                        }

                        Behavior on height { NumberAnimation { duration: 1000; easing.type: Easing.OutBounce } }
                    }
                    
                    // Glass Shine Effect
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#22FFFFFF" }
                            GradientStop { position: 0.4; color: "transparent" }
                        }
                        radius: 8
                    }
                    
                    // Content Overlay (Text)
                    Item {
                        anchors.fill: parent
                        
                        // Percentage Text (Top)
                        Text {
                            anchors.top: parent.top
                            anchors.topMargin: 15
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (bridge.hopper["level"] !== undefined ? bridge.hopper["level"] : "50") + "%"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 22
                            style: Text.Outline; styleColor: "#000000"
                        }

                        // Pellet Name
                        Text {
                            anchors.centerIn: parent
                            text: bridge.hopper["name"] !== undefined ? bridge.hopper["name"] : "Unknown"
                            rotation: -90
                            color: "white"
                            font.bold: true
                            font.pixelSize: 16
                            // Shadow for readability
                            style: Text.Outline; styleColor: "#000000"
                        }
                }
            }
        }
        }

        // COLUMN 2: ANALOG GAUGE (Center)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: "transparent" // Or surfaceColor if preferred
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                
                // Status Text / S+
                // Status Text / S+ / Prime Timer (Header)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 40
                    spacing: 10
                    
                    Text {
                        text: bridge.status
                        color: "#AAA"
                        font.pixelSize: 24
                        font.bold: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlPopup.open()
                        }
                    }


                    
    // Shared Components
    component DashboardButton: Rectangle {
        property string label
        property string icon
        property color btnColor: "#333"
        property color iconColor: "white"
        property bool isEnabled: true
        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: isEnabled ? btnColor : "#222"
        radius: 12
        border.color: isEnabled ? Qt.lighter(btnColor, 1.2) : "#333"
        border.width: 1
        opacity: isEnabled ? 1.0 : 0.4
        clip: true

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            enabled: parent.isEnabled
            hoverEnabled: true
            onEntered: if(parent.isEnabled) parent.border.color = "white"
            onExited: if(parent.isEnabled) parent.border.color = Qt.lighter(parent.btnColor, 1.2)
            onPressed: parent.scale = 0.95
            onReleased: parent.scale = 1.0
            onClicked: parent.clicked()
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: icon
                font.family: faFont.name
                font.pixelSize: 32
                color: isEnabled ? iconColor : "#777"
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: label
                color: isEnabled ? "white" : "#777"
                font.bold: true
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // --- POPUPS ---

    // 1. Control Popup (Main Menu)
    Popup {
        id: controlPopup
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 600
        height: 380
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        dim: true
        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 150 }
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
            }
        }

        background: Rectangle {
            color: "#1e1e1e"
            border.color: "#333"
            border.width: 2
            radius: 16
            layer.enabled: true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            Text {
                text: window.strings.dash_control_title
                color: "white"
                font.pixelSize: 26
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                rowSpacing: 15
                columnSpacing: 15

                // Rules:
                // Stop/Prime: Prime, Startup, Monitor, Stop
                // Monitor: Startup, Stop
                // Startup: Smoke, Stop
                // Smoke: Stop, Shutdown, Smoke Plus
                // Hold: Smoke, Stop, Shutdown, Smoke Plus

                // 1. Startup Button
                // Visible in: Stop, Prime, Monitor, Reignite
                DashboardButton { 
                    label: window.strings.dash_startup
                    icon: "\uf04b" // Play
                    iconColor: "#4CAF50"
                    visible: (bridge.mode === "Stop" || bridge.mode === "Prime" || bridge.mode === "Monitor" || bridge.mode === "Error" || bridge.mode === "Reignite")
                    onClicked: confirmPopup.open()
                }
                
                // 2. Smoke Mode Button
                // Visible in: Startup, Hold, Reignite, Shutdown
                DashboardButton { 
                    label: window.strings.dash_smoke
                    icon: "\uf0c2" // Cloud
                    iconColor: "#B388FF"
                    visible: (bridge.mode === "Startup" || bridge.mode === "Hold" || bridge.mode === "Reignite" || bridge.mode === "Shutdown")
                    onClicked: { bridge.sendCommand("smoke"); controlPopup.close() }
                }
                
                // 3. Monitor Button
                // Visible in: Stop, Prime, Error
                DashboardButton { 
                    label: window.strings.dash_monitor
                    icon: "\uf06e" // Eye
                    iconColor: "#29B6F6"
                    visible: (bridge.mode === "Stop" || bridge.mode === "Prime" || bridge.mode === "Error")
                    onClicked: { bridge.sendCommand("monitor"); controlPopup.close() }
                }

                // 4. Prime Button
                // Visible in: Stop, Prime, Error
                DashboardButton { 
                    label: window.strings.dash_prime
                    icon: "\uf06d" // Fire
                    iconColor: "#FF5722"
                    visible: (bridge.mode === "Stop" || bridge.mode === "Prime" || bridge.mode === "Error")
                    onClicked: primePopup.open()
                }

                // 5. Shutdown Button
                // Visible in: Smoke, Hold, Startup
                DashboardButton { 
                    label: window.strings.dash_shutdown
                    icon: "\uf011" // Power
                    iconColor: "#FFC107"
                    visible: (bridge.mode === "Smoke" || bridge.mode === "Hold" || bridge.mode === "Startup")
                    onClicked: { bridge.sendCommand("shutdown"); controlPopup.close() }
                }

                // 6. Smoke Plus (New)
                // Visible in: Smoke, Hold, Shutdown
                DashboardButton {
                    label: "Smoke Plus " + (bridge.sPlus ? "(ON)" : "(OFF)")
                    icon: "\uf0c2"
                    iconColor: bridge.sPlus ? "#00E676" : "#777"
                    btnColor: bridge.sPlus ? "#333" : "#222"
                    border.color: bridge.sPlus ? "#00E676" : "#333"
                    visible: (bridge.mode === "Smoke" || bridge.mode === "Hold" || bridge.mode === "Shutdown")
                    onClicked: { 
                         bridge.toggleSmokePlus(bridge.sPlus); 
                         controlPopup.close() 
                    }
                }

                // 7. STOP (Emergency) - Always Visible
                DashboardButton { 
                    label: window.strings.dash_stop
                    icon: "\uf04d" 
                    btnColor: "#D32F2F"
                    onClicked: { bridge.sendCommand("stop"); controlPopup.close() }
                }

                // 8. Set Target Temp (New)
                DashboardButton {
                    label: window.strings.dash_target
                    icon: "\uf2c8" // Thermometer  
                    iconColor: "#FF9800"
                    // Visible in: Hold, Smoke, Startup, Shutdown, Reignite
                    visible: (bridge.mode === "Hold" || bridge.mode === "Smoke" || bridge.mode === "Shutdown" || bridge.mode === "Startup" || bridge.mode === "Reignite")
                    onClicked: { 
                        tempPopup.open(); 
                        controlPopup.close() 
                    }
                }
            }
            
            // Close footer
            Text {
                text: "Appuyez à l'extérieur pour fermer"
                color: "#666"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // 2. Startup Confirmation Popup
    Popup {
        id: confirmPopup
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 400
        height: 250
        modal: true
        dim: true

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 150 }
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
            }
        }

        background: Rectangle {
            color: "#222"
            border.color: "#FF9800"
            border.width: 2
            radius: 16
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            Text {
                text: window.strings.dash_confirm_start_title
                color: "#FF9800"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: window.strings.dash_confirm_start_msg
                color: "#DDD"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                // Cancel Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: "#444"
                    radius: 12
                    border.color: "#555"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: "\uf00d"
                            font.family: faFont.name
                            font.pixelSize: 20
                            color: "white"
                        }
                        Text {
                            text: window.strings.dash_btn_cancel
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: confirmPopup.close()
                        onPressed: parent.scale = 0.98
                        onReleased: parent.scale = 1.0
                    }
                }

                // Start Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: "#4CAF50"
                    radius: 12
                    border.color: "#66BB6A"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: "\uf04b"
                            font.family: faFont.name
                            font.pixelSize: 20
                            color: "white"
                        }
                        Text {
                            text: window.strings.dash_btn_letsgo
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            bridge.sendCommand("startup")
                            confirmPopup.close()
                            controlPopup.close()
                        }
                        onPressed: parent.scale = 0.98
                        onReleased: parent.scale = 1.0
                    }
                }
            }
        }
    }

    // 3. Prime Selection Popup
    Popup {
        id: primePopup
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 700
        height: 400
        modal: true
        dim: true

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 150 }
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
            }
        }

        background: Rectangle {
            color: "#222"
            border.color: "#FF5722"
            border.width: 2
            radius: 16
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 15

            Text {
                text: window.strings.dash_prime_title
                color: "#FF5722"
                font.pixelSize: 26
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: window.strings.dash_prime_msg
                color: "#888"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                rowSpacing: 15
                columnSpacing: 15

                // Headers (Optional, or just implied)
                
                // 10g
                DashboardButton {
                    label: "10g & STOP"; icon: "\uf04d"; iconColor: "#ff7043"
                    onClicked: { bridge.sendPrime(10, 'Stop'); primePopup.close(); controlPopup.close() }
                }
                DashboardButton {
                    label: "25g & STOP"; icon: "\uf04d"; iconColor: "#ff7043"
                    onClicked: { bridge.sendPrime(25, 'Stop'); primePopup.close(); controlPopup.close() }
                }
                DashboardButton {
                    label: "50g & STOP"; icon: "\uf04d"; iconColor: "#ff7043"
                    onClicked: { bridge.sendPrime(50, 'Stop'); primePopup.close(); controlPopup.close() }
                }

                // Startup Line
                DashboardButton {
                    label: "10g & START"; icon: "\uf04b"; iconColor: "#66BB6A"
                    onClicked: { bridge.sendPrime(10, 'Startup'); primePopup.close(); controlPopup.close() }
                }
                DashboardButton {
                    label: "25g & START"; icon: "\uf04b"; iconColor: "#66BB6A"
                    onClicked: { bridge.sendPrime(25, 'Startup'); primePopup.close(); controlPopup.close() }
                }
                DashboardButton {
                    label: "50g & START"; icon: "\uf04b"; iconColor: "#66BB6A"
                    onClicked: { bridge.sendPrime(50, 'Startup'); primePopup.close(); controlPopup.close() }
                }
            }
            
            Rectangle {
                Layout.preferredHeight: 50
                Layout.fillWidth: true
                color: "#333"
                radius: 12
                border.color: "#444"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        text: "\uf00d"
                        font.family: faFont.name
                        font.pixelSize: 20 
                        color: "white"
                    }
                    Text {
                        text: window.strings.dash_btn_cancel
                        color: "white"
                        font.bold: true
                        font.pixelSize: 16
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: primePopup.close()
                    onPressed: parent.scale = 0.98
                    onReleased: parent.scale = 1.0
                }
            }
        }
    }

    // 4. Temperature Setpoint Popup
    Popup {
        id: tempPopup
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 500
        height: 320
        modal: true
        dim: true
        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        property int currentSetPoint: bridge.setPoint > 0 ? Math.round(bridge.setPoint) : minVal
        
        // Ranges and Steps based on User Request
        // C: 50-260, Step 1
        // F: 125-600, Step 5
        property int minVal: bridge.units === "C" ? 50 : 125
        property int maxVal: bridge.units === "C" ? 260 : 600
        property int stepVal: bridge.units === "C" ? 1 : 5

        // Helper function for changing values
        function changeTemp(direction) {
            var newVal = currentSetPoint + (direction * stepVal)
            if (direction > 0) {
                if (newVal <= maxVal) currentSetPoint = newVal
            } else {
                if (newVal >= minVal) currentSetPoint = newVal
            }
        }

        onOpened: {
            if (bridge.setPoint > 0) {
                currentSetPoint = Math.round(bridge.setPoint)
            } else {
                currentSetPoint = minVal
            }
        }

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 150 }
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
            }
        }

        background: Rectangle {
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2E2E2E" }
                GradientStop { position: 1.0; color: "#121212" }
            }
            border.color: "#FF9800"
            border.width: 1
            radius: 20
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            // Header
            Text {
                text: window.strings.dash_target_title
                color: "#AAAAAA"
                font.pixelSize: 22
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 2
            }

            Item { Layout.fillHeight: true } // Spacer

            // Main Control Row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 40

                // Minus Button
                Rectangle {
                    width: 80; height: 80; radius: 40
                    color: minusArea.pressed ? "#FF9800" : "#333"
                    border.color: minusArea.pressed ? "#FF9800" : "#555"
                    border.width: 2
                    
                    Text { 
                        text: "\uf068"
                        font.family: faFont.name
                        color: minusArea.pressed ? "black" : "white"
                        font.pixelSize: 32
                        anchors.centerIn: parent 
                    }
                    
                    MouseArea {
                        id: minusArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        Timer {
                            interval: 100; running: minusArea.pressed; repeat: true
                            onTriggered: tempPopup.changeTemp(-1)
                        }
                        onPressed: { parent.scale = 0.95; tempPopup.changeTemp(-1) }
                        onReleased: parent.scale = 1.0
                    }
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // Value Display
                Text {
                    text: tempPopup.currentSetPoint + "°"
                    color: "#FFFFFF"
                    font.pixelSize: 96
                    font.family: "Arial"
                    font.bold: true
                    style: Text.Outline
                    styleColor: "black"
                    Layout.alignment: Qt.AlignVCenter
                }

                // Plus Button
                Rectangle {
                    width: 80; height: 80; radius: 40
                    color: plusArea.pressed ? "#FF9800" : "#333"
                    border.color: plusArea.pressed ? "#FF9800" : "#555"
                    border.width: 2
                    
                    Text { 
                        text: "\uf067"
                        font.family: faFont.name
                        color: plusArea.pressed ? "black" : "white"
                        font.pixelSize: 32
                        anchors.centerIn: parent 
                    }
                    
                    MouseArea {
                        id: plusArea
                        anchors.fill: parent
                        hoverEnabled: true

                        Timer {
                            interval: 100; running: plusArea.pressed; repeat: true
                            onTriggered: tempPopup.changeTemp(1)
                        }
                        onPressed: { parent.scale = 0.95; tempPopup.changeTemp(1) }
                        onReleased: parent.scale = 1.0
                    }
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }

            Item { Layout.fillHeight: true } // Spacer

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#444"
            } 

            // Footer Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                // Cancel Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: "#333"
                    radius: 12
                    border.color: "#444"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: "\uf00d"
                            font.family: faFont.name
                            font.pixelSize: 20
                            color: "white"
                        }
                        Text {
                            text: window.strings.dash_btn_cancel
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: tempPopup.close()
                        onPressed: parent.scale = 0.98
                        onReleased: parent.scale = 1.0
                    }
                }

                // Apply Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: "#FF9800"
                    radius: 12
                    border.color: "#FB8C00"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: "\uf00c"
                            font.family: faFont.name
                            font.pixelSize: 20
                            color: "black"
                        }
                        Text {
                            text: window.strings.dash_btn_apply
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            bridge.setTargetTemp(tempPopup.currentSetPoint)
                            tempPopup.close()
                        }
                        onPressed: parent.scale = 0.98
                        onReleased: parent.scale = 1.0
                    }
                }
            }
        }
    }
                    
                    // Prime Timer (Top Next to Status)
                    Text {
                        id: primeTimerText
                        visible: bridge.mode === "Prime"
                        color: "#FF3D00"
                        font.pixelSize: 24
                        font.bold: true
                        text: "--"
                        
                        Timer {
                            interval: 500; running: bridge.mode === "Prime"; repeat: true
                            onTriggered: {
                                if (bridge.modeStartTime > 0 && bridge.primeDuration > 0) {
                                    var now = new Date().getTime() / 1000;
                                    var elapsed = now - bridge.modeStartTime;
                                    var remaining = Math.max(0, Math.ceil(bridge.primeDuration - elapsed));
                                    primeTimerText.text = remaining + "s";
                                } else {
                                    primeTimerText.text = "--";
                                }
                            }
                        }
                    }

                    // Startup Timer (Top Next to Status)
                    Text {
                        id: startupTimerText
                        visible: (bridge.mode === "Startup" || bridge.mode === "Reignite")
                        color: window.primaryColor
                        font.pixelSize: 24
                        font.bold: true
                        text: "--"
                        
                        Timer {
                            interval: 500; running: (bridge.mode === "Startup" || bridge.mode === "Reignite"); repeat: true
                            onTriggered: {
                                if (bridge.startTime > 0 && bridge.startDuration > 0) {
                                    var now = new Date().getTime() / 1000;
                                    var elapsed = now - bridge.startTime;
                                    var remaining = Math.max(0, Math.ceil(bridge.startDuration - elapsed));
                                    startupTimerText.text = remaining + "s";
                                } else {
                                    startupTimerText.text = "--";
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: bridge.sPlus
                    text: "SMOKE PLUS"
                    color: "#B388FF"
                    font.bold: true
                    font.pixelSize: 18
                }

                // Prime Mode Progress Bar (Above Gauge)
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: bridge.mode === "Prime"
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 10
                    color: "#333"
                    radius: 5
                    
                    Rectangle {
                        height: parent.height
                        width: parent.width * bridge.primeProgress
                        radius: 5
                        color: "#FF3D00"
                        Behavior on width { NumberAnimation { duration: 500 } }
                    }
                }

                // Startup / Reignite Progress Bar (Above Gauge)
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: (bridge.mode === "Startup" || bridge.mode === "Reignite")
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 10
                    color: "#333"
                    radius: 5
                    
                    Rectangle {
                        height: parent.height
                        width: parent.width * bridge.startupProgress
                        radius: 5
                        color: window.primaryColor
                        Behavior on width { NumberAnimation { duration: 500 } }
                    }
                }

                GaugeComponent {
                    temperature: bridge.grillTemp
                    setPoint: bridge.setPoint
                    units: bridge.units // "C" or "F"
                    Layout.alignment: Qt.AlignHCenter
                    
                    onSetPointClicked: {
                        console.log("Gauge Clicked. Mode:", bridge.mode)
                        if (bridge.mode === "Hold" || bridge.mode === "Smoke" || bridge.mode === "Shutdown" || bridge.mode === "Startup" || bridge.mode === "Reignite") {
                            tempPopup.open()
                        }
                    }
                }
                // Lid Open Warning (Centered)
                Rectangle {
                    Layout.preferredWidth: 250
                    Layout.preferredHeight: 40
                    color: "#D32F2F"
                    radius: 5
                    visible: bridge.lidOpen
                    Layout.alignment: Qt.AlignHCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "LID OPEN"
                        color: "white"
                        font.bold: true
                    }
                }


                



            }
        }

        // COLUMN 3: PROBES (Right)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 180
            color: window.surfaceColor
            radius: 10
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                
                // Probe List
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: bridge.probes
                    spacing: 12

                    delegate: Rectangle {
                        width: parent.width
                        height: 85
                        radius: 12
                        
                        // Subtle Gradient Background
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#2A2A2A" }
                            GradientStop { position: 1.0; color: "#222" }
                        }
                        
                        border.color: "#333"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 15

                            // Icon Container
                            Rectangle {
                                width: 45; height: 45
                                radius: 22.5
                                color: Qt.rgba(window.primaryColor.r, window.primaryColor.g, window.primaryColor.b, 0.15)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf2c9" // Thermometer Half
                                    font.family: faFont.name
                                    font.pixelSize: 22
                                    color: window.primaryColor
                                }
                            }

                            // Temp Data
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                // Probe Name
                                Text {
                                    text: modelData.name
                                    color: "#DDD"
                                    font.pixelSize: 15
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                // Current Temp (Large)
                                Text {
                                    text: modelData.temp + "°" + bridge.units
                                    color: "white"
                                    font.pixelSize: 28
                                    font.bold: true
                                }
                            }

                            // Target Temp (Badge style)
                            Rectangle {
                                visible: modelData.target > 0
                                width: 50; height: 40
                                color: "#333"
                                radius: 8
                                border.color: "#444"
                                
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 0
                                    
                                    Text {
                                        text: "\uf140" // Target Icon
                                        font.family: faFont.name
                                        font.pixelSize: 12
                                        color: "#888"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: modelData.target + "°"
                                        color: "#CCC"
                                        font.pixelSize: 14
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: bridge.probes.length === 0
                    text: window.strings.status_no_probes
                    color: "#555"
                    font.italic: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
