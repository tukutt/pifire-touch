import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.3

Page {
    id: graphPage
    background: Rectangle { color: "#121212" }

    property var currentSeriesMap: ({})

    Component.onCompleted: {
        bridge.fetchHistory("60")
        bridge.startHistoryStream()
    }
    
    Component.onDestruction: {
        bridge.stopHistoryStream()
    }

    Connections {
        target: bridge
        function onHistoryDataChanged(data) {
            updateGraph(data)
        }
        function onHistoryPointChanged(pointData) {
            // pointData = { x: timestamp_ms, temps: { Grill: 200, ... } }
            var xVal = pointData.x || new Date().getTime()
            var temps = pointData.temps || pointData 
            
            for (var key in temps) {
                if (currentSeriesMap[key]) {
                    var val = temps[key]
                    var series = currentSeriesMap[key]
                    series.append(xVal, val)
                }
            }
            
            // Scroll Axis
            if (xVal > axisX.max.getTime()) {
                var diff = xVal - axisX.max.getTime()
                // Move window forward
                axisX.min = new Date(axisX.min.getTime() + diff)
                axisX.max = new Date(xVal)
            }
        }
    }

    function updateGraph(seriesList) {
        chart.removeAllSeries()
        currentSeriesMap = {}

        var minX = new Date().getTime()
        var maxX = minX + 60000 
        var minY = 1000
        var maxY = 0
        var hasPoints = false

        for (var i = 0; i < seriesList.length; i++) {
            var sData = seriesList[i]
            var sName = sData.name
            var points = sData.points
            
            // Create Series
            var series = chart.createSeries(ChartView.SeriesTypeLine, sName, axisX, axisY)
            series.width = 2
            
            // Style
            if (sName === "Grill") {
                series.color = "#FF9800"
                series.width = 3
            } else if (sName === "Probe1") { series.color = "#E91E63"
            } else if (sName === "Probe2") { series.color = "#2196F3"
            } else if (sName === "Probe3") { series.color = "#4CAF50"
            } else if (sName === "SetPoint") {
                series.color = "#444"
                series.style = Qt.DotLine
            }
            
            for (var j = 0; j < points.length; j++) {
                var p = points[j]
                var xTs = p.x
                var yVal = p.y
                
                series.append(xTs, yVal)
                
                if (!hasPoints) {
                    minX = xTs; maxX = xTs; minY = yVal; maxY = yVal
                    hasPoints = true
                } else {
                    if (xTs < minX) minX = xTs
                    if (xTs > maxX) maxX = xTs
                    if (yVal < minY) minY = yVal
                    if (yVal > maxY) maxY = yVal
                }
            }
            
            currentSeriesMap[sName] = series
        }
        
        // Adjust Axis
        if (hasPoints) {
            axisX.min = new Date(minX)
            axisX.max = new Date(maxX)
        }
        
        // Min Y constrained to -20
        var calculatedMinY = Math.max(-20, minY - 10)
        if (minY < -20) calculatedMinY = minY - 5 
        else calculatedMinY = -20
        
        axisY.min = calculatedMinY
        axisY.max = maxY + 20
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Title & Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            
            Text {
                text: "Historique"
                color: "white"
                font.bold: true
                font.pixelSize: 24
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: "Rafraîchir (60m)"
                onClicked: bridge.fetchHistory("60")
                background: Rectangle { color: "#333"; radius: 5 }
                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }

            Button {
                text: "Zoom Reset"
                onClicked: chart.zoomReset()
                background: Rectangle { color: "#333"; radius: 5 }
                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }

        // Chart Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ChartView {
                id: chart
                anchors.fill: parent
                theme: ChartView.ChartThemeDark
                antialiasing: true
                legend.alignment: Qt.AlignBottom
                legend.labelColor: "white"
                backgroundColor: "#1e1e1e"
                
                // Axes
                DateTimeAxis {
                    id: axisX
                    format: "hh:mm"
                    labelsColor: "#AAA"
                    gridLineColor: "#333"
                }

                ValueAxis {
                    id: axisY
                    min: -20; max: 400
                    labelFormat: "%d"
                    labelsColor: "#AAA"
                    gridLineColor: "#333"
                }
            }
            
            // Pinch to Zoom support
            PinchArea {
                anchors.fill: parent
                onPinchStarted: {
                    // console.log("Pinch Started")
                }
                onPinchUpdated: (pinch) => {
                    chart.zoom(pinch.scale)
                    // Clamp Y
                    if (axisY.min < -20) axisY.min = -20
                    if (axisY.max > 600) axisY.max = 600
                }
                onPinchFinished: {
                    // Verify bounds or snap back if needed
                }
                
                // Pan support (Drag)
                MouseArea {
                    anchors.fill: parent
                    drag.target: null 
                    property real lastX
                    property real lastY
                    
                    onPressed: {
                        lastX = mouseX
                        lastY = mouseY
                    }
                    
                    onPositionChanged: {
                        var dx = mouseX - lastX
                        var dy = mouseY - lastY
                        if (pressed) {
                            chart.scrollLeft(dx)
                            chart.scrollUp(dy)
                            
                            // Clamp Y Range [-20, 600]
                            var currentRange = axisY.max - axisY.min
                            
                            if (axisY.min < -20) {
                                axisY.min = -20
                                axisY.max = -20 + currentRange
                            }
                            if (axisY.max > 600) {
                                axisY.max = 600
                                axisY.min = 600 - currentRange
                            }
                        }
                        lastX = mouseX
                        lastY = mouseY
                    }
                }
            }
        }
    }
}
