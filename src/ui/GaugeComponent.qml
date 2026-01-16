import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: gauge
    property real temperature: 0
    property real setPoint: 0
    property string units: "F" // "C" or "F"
    
    signal setPointClicked()

    // Configuration based on Units
    // Size config
    width: 300
    height: 300
    
    // --- LOGIC ---
    property bool isF: units === "F"
    property real maxTemp: isF ? 600 : 300
    property real startAngleDeg: 140
    property real totalAngleDeg: 260 // 400 - 140

    function valueToAngle(val) {
        var ratio = Math.max(0, Math.min(val, maxTemp)) / maxTemp;
        return (startAngleDeg + (ratio * totalAngleDeg));
    }
    
    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var centerX = width / 2;
            var centerY = height / 2;
            var diameter = Math.min(width, height);
            var radius = diameter / 2 - 10;
            
            // --- 1. Background Case ---
            var gradient = ctx.createLinearGradient(0, 0, width, height);
            gradient.addColorStop(0, "#F0F0F0");
            gradient.addColorStop(0.2, "#888");
            gradient.addColorStop(0.5, "#FFF");
            gradient.addColorStop(0.8, "#888");
            gradient.addColorStop(1, "#555");
            
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius + 10, 0, 2 * Math.PI);
            ctx.fillStyle = gradient;
            ctx.fill();
            
            // Inner Rim
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
            ctx.fillStyle = "#111";
            ctx.fill();
            
            // Face
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius - 3, 0, 2 * Math.PI);
            ctx.fillStyle = "#000"; 
            ctx.fill();
            
            // --- Helpers ---
            function degToRad(deg) { return deg * Math.PI / 180; }
            function valToRad(val) { return degToRad(valueToAngle(val)); }
            
            // --- 3. Zones ---
            var z1 = isF ? 225 : 107;
            var z2 = isF ? 325 : 162;
            var z3 = isF ? 500 : 260;
            
            var bandWidth = 35; 
            var bandRadius = radius - 65; 
            
            function drawBand(s, e, col, label, textColor) {
                if (s >= maxTemp) return;
                var effectiveE = Math.min(e, maxTemp);
                
                ctx.beginPath();
                ctx.arc(centerX, centerY, bandRadius, valToRad(s), valToRad(effectiveE), false);
                ctx.lineWidth = bandWidth;
                ctx.strokeStyle = col;
                ctx.stroke();
                
                // Separators
                var endA = valToRad(effectiveE);
                ctx.beginPath();
                var rIn = bandRadius - bandWidth/2;
                var rOut = bandRadius + bandWidth/2;
                ctx.moveTo(centerX + rIn * Math.cos(endA), centerY + rIn * Math.sin(endA));
                ctx.lineTo(centerX + rOut * Math.cos(endA), centerY + rOut * Math.sin(endA));
                ctx.lineWidth = 2;
                ctx.strokeStyle = "white";
                ctx.stroke();

                // Label
                if (label) {
                    var midVal = (s + effectiveE) / 2;
                    var midAngle = valToRad(midVal);
                    
                    ctx.font = "900 14px sans-serif";
                    ctx.fillStyle = textColor ? textColor : "white";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    
                    var totalWidth = ctx.measureText(label).width;
                    var letterSpacing = 2; 
                    totalWidth += (label.length - 1) * letterSpacing;
                    
                    var textRadius = bandRadius;
                    var totalAngleWidth = totalWidth / textRadius;
                    var currentAngle = midAngle - (totalAngleWidth / 2);
                    
                    for (var i = 0; i < label.length; i++) {
                        var letter = label[i];
                        var letterWidth = ctx.measureText(letter).width;
                        var letterAngle = letterWidth / textRadius;
                        var spacingAngle = letterSpacing / textRadius;
                        var drawAngle = currentAngle + (letterAngle / 2);
                        
                        ctx.save();
                        ctx.translate(centerX + textRadius * Math.cos(drawAngle), centerY + textRadius * Math.sin(drawAngle));
                        ctx.rotate(drawAngle + Math.PI/2);
                        ctx.fillText(letter, 0, 0);
                        ctx.restore();
                        
                        currentAngle += letterAngle + spacingAngle;
                    }
                }
            }
            
            drawBand(0, z1, "#003f5c", "SMOKE", "white");       
            drawBand(z1, z2, "#d62828", "BBQ", "white");     
            drawBand(z2, z3, "#fcbf49", "GRILL", "black");     
            drawBand(z3, maxTemp, "#f77f00", "SEAR", "white"); 
            
            // --- 4. Ticks & Numbers ---
            ctx.fillStyle = "white";
            ctx.strokeStyle = "white";
            ctx.font = "bold 20px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            
            var step = isF ? 50 : 25; 
            var labelStep = isF ? 50 : 50; 
            
            for (var t = 0; t <= maxTemp; t += step) {
                var a = valToRad(t);
                var cos = Math.cos(a);
                var sin = Math.sin(a);
                
                var rTickOut = radius - 30; 
                var rTickIn = (t % labelStep === 0) ? radius - 45 : radius - 38; 
                
                ctx.lineWidth = (t % labelStep === 0) ? 3 : 2;
                ctx.beginPath();
                ctx.moveTo(centerX + rTickIn * cos, centerY + rTickIn * sin);
                ctx.lineTo(centerX + rTickOut * cos, centerY + rTickOut * sin);
                ctx.stroke();
                
                if (t % labelStep === 0) {
                    var rNum = radius - 15; 
                    ctx.save();
                    ctx.translate(centerX + rNum * cos, centerY + rNum * sin);
                    ctx.rotate(a + Math.PI/2);
                    ctx.fillText(t.toString(), 0, 0);
                    ctx.restore();
                }
            }
            
            // --- 5. Branding ---
            ctx.font = "bold 16px sans-serif";
            ctx.fillStyle = "#DDD";
            ctx.fillText("PIFIRE", centerX, centerY + 30);
            
            ctx.font = "bold 14px sans-serif";
            ctx.fillStyle = "#AAA";
            ctx.fillText("°" + units, centerX, centerY + 50);
        }
    }
    
    // Trigger repaint only on config changes (Units), not every temp change
    onUnitsChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()

    // --- NEEDLE (QML Item) ---
    Item {
        id: needleItem
        width: 300 // Match parent approx
        height: 300
        anchors.centerIn: parent
        
        // Rotation Center
        // We want to rotate the whole Item? Or just the rectangle inside?
        // Better: Rotate this Item container.
        // But rotation origin is center by default, which is correct (gauge center).
        
        rotation: valueToAngle(gauge.temperature)
        
        Behavior on rotation {
            SpringAnimation { spring: 2; damping: 0.2; modulus: 360 }
        }
        
        // The Needle Graphic
        // Drawn pointing to RIGHT (0 deg for normal math) or DOWN?
        // valueToAngle returns ~140 to 400 degrees.
        // 0 degrees in QML rotation is 12 o'clock? No, usually standard screen coordinates (positive X, right).
        // 140 deg is bottom-right? 
        // in QML rotation: 0 is Up? 
        // Actually, simple test: valueToAngle(min) = 140.
        // We want needle at 140 deg.
        // If we draw needle pointing at 0 deg (Right), then rotating 140 puts it at 140.
        // So we should draw the needle pointing to 0 degrees (Right) relative to center.
        
        Rectangle {
            width: (gauge.width / 2) - 25 // Length
            height: 6
            color: "#D32F2F" 
            x: gauge.width / 2 // Start at center
            y: (gauge.height / 2) - 3 // Centered vertically
            
            // We want it to pivot around (0, height/2) of this rectangle?
            // No, the parent Item rotates around its center.
            // So we just place the needle starting from center, extending out.
            // transformOrigin: Item.Left // Not needed if parent rotates
        }
        
        // Tail
        Rectangle {
            width: 25
            height: 6
            color: "#D32F2F"
            x: (gauge.width / 2) - 25
            y: (gauge.height / 2) - 3
        }
    }
    
    // --- MOUSE AREA (Whole Gauge) ---
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: gauge.setPointClicked()
    }
    
    // --- DIGITAL READOUT ---
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: gauge.width * 0.3
        spacing: 5
        
        Text {
            text: Math.round(gauge.temperature)
            color: "white"
            font.family: "Arial"
            font.bold: true
            font.pixelSize: 48
            Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
            text: gauge.setPoint > 0 ? Math.round(gauge.setPoint) : "-"
            color: "#FF9800"
            font.family: "Arial"
            font.bold: true
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
