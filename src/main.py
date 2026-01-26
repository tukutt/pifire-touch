import sys
import os

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl, QCoreApplication, QTimer

# Import our bridge logic
from bridge import PiFireBridge

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("PiFire Touch")
    app.setOrganizationName("PiFire")
    
    # Instantiate the bridge (Backend logic) - Parent appropriately
    print("Main: Creating Bridge...")
    bridge = PiFireBridge(app)
    
    engine = QQmlApplicationEngine()
    
    # Expose the bridge to QML as a global property "bridge"
    print("Main: Setting Context Property 'bridge'...")
    engine.rootContext().setContextProperty("bridge", bridge)
    
    # Load the main QML file
    # Requires absolute path or robust relative path logic
    current_dir = os.path.dirname(os.path.abspath(__file__))
    qml_file = os.path.join(current_dir, "ui", "main.qml")
    
    engine.load(QUrl.fromLocalFile(qml_file))
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    # Handle KeyboardInterrupt (Ctrl+C) nicely allowing Qt to cleanup
    import signal
    def handle_sigint(signum, frame):
        print("\nStopping PiFire Touch...")
        app.quit()
        
    signal.signal(signal.SIGINT, handle_sigint)
    
    # Timer to let the python interpreter run periodically to catch signals
    # (Qt event loop can block python signals otherwise)
    timer = QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None) 
    
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
