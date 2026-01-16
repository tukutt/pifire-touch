import requests
import threading
import time
import json
import os
from PySide6.QtCore import QObject, Signal, Slot, QTimer, Property, Qt

class PiFireBridge(QObject):
    # Signals to notify QML of property changes
    grillTempChanged = Signal(int)
    probesChanged = Signal(list)
    setPointChanged = Signal(int)
    modeChanged = Signal(str)
    statusChanged = Signal(str)
    # Extended Signals
    outpinsChanged = Signal(dict)
    sPlusChanged = Signal(bool)
    lidOpenChanged = Signal(bool)
    timersChanged = Signal(list)
    startupProgressChanged = Signal(float)
    shutdownProgressChanged = Signal(float)
    startTimeChanged = Signal(float)
    primeDurationChanged = Signal(int)
    startDurationChanged = Signal(int)
    modeStartTimeChanged = Signal(float)
    primeProgressChanged = Signal(float)
    hopperChanged = Signal(dict)
    pModeChanged = Signal(str)
    unitsChanged = Signal(str)
    historyDataChanged = Signal(list)
    historyPointChanged = Signal(dict)
    
    # Internal Signal for Thread -> Main communication
    _apiResponseReceived = Signal(dict)

    langDataChanged = Signal(dict)
    
    # Server Config Signals
    serverAddressChanged = Signal(str)
    serverSelectionChanged = Signal(str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        print("PiFireBridge: Initializing...")
        self._grill_temp = 0
        self._probes = []
        self._set_point = 0
        self._mode = "Disconnected"
        self._status = "Connecting..."
        
        # Extended State
        self._outpins = {"fan": False, "auger": False, "igniter": False, "power": False}
        self._s_plus = False
        self._lid_open = False
        self._timers = []
        self._startup_progress = 0.0
        self._shutdown_progress = 0.0
        self._start_time = 0.0
        self._prime_duration = 0
        self._start_duration = 0
        self._history_active = False
        self._last_history_emit = 0
        self._mode_start_time = 0.0
        self._prime_progress = 0.0
        self._hopper = {}
        self._hopper_details = {} 
        self._p_mode = "--"
        self._units = "C"
        
        # I18n Init
        self._lang_data = {}
        self.load_language("fr")

        # New HTTPS URL configuration
        # Default configuration
        self._server_selection = "pifire" 
        self._custom_ip = "192.168.1.100" 
        self.base_url = "http://pifire.local" # Default resolved
        
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0',
            'Accept': '*/*',
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': f'{self.base_url}/events/'
        }
        
        self.load_config()
        
        # Threading State
        self._is_updating = False
        self._apiResponseReceived.connect(self._process_response)
        
        # Poll API every 100ms
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_status)
        self.timer.start(100)
        
        self._poll_counter = 0
        
        # Initial call
        self.update_status()

    def load_language(self, lang_code):
        path = f"assets/lang/{lang_code}.json"
        if not os.path.exists(path):
            # Fallback path if running from subdir? Or absolute?
            # Assuming CWD is project root
            # Try absolute if relative fails
             current_dir = os.path.dirname(os.path.abspath(__file__))
             path = os.path.join(current_dir, "assets", "lang", f"{lang_code}.json")
             
        try:
            if os.path.exists(path):
                with open(path, 'r', encoding='utf-8') as f:
                    self._lang_data = json.load(f)
                    print(f"Loaded language: {lang_code}")
                    self.langDataChanged.emit(self._lang_data)
            else:
                print(f"Language file not found: {path} (CWD: {os.getcwd()})")
        except Exception as e:
            print(f"Error loading language {lang_code}: {e}")

    # --- Properties exposed to QML ---
    
    @Property(int, notify=grillTempChanged)
    def grillTemp(self):
        return self._grill_temp

    @Property(list, notify=probesChanged)
    def probes(self):
        return self._probes

    @Property(int, notify=setPointChanged)
    def setPoint(self):
        return self._set_point

    @Property(str, notify=modeChanged)
    def mode(self):
        return self._mode

    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @Property(dict, notify=outpinsChanged)
    def outpins(self):
        return self._outpins

    @Property(bool, notify=sPlusChanged)
    def sPlus(self):
        return self._s_plus

    @Property(bool, notify=lidOpenChanged)
    def lidOpen(self):
        return self._lid_open

    @Property(float, notify=startupProgressChanged)
    def startupProgress(self):
        return self._startup_progress

    @Property(float, notify=shutdownProgressChanged)
    def shutdownProgress(self):
        return self._shutdown_progress

    @Property(float, notify=startTimeChanged)
    def startTime(self):
        return self._start_time

    @Property(int, notify=primeDurationChanged)
    def primeDuration(self):
        return self._prime_duration

    @Property(int, notify=startDurationChanged)
    def startDuration(self):
        return self._start_duration

    @Property(float, notify=modeStartTimeChanged)
    def modeStartTime(self):
        return self._mode_start_time

    @Property(float, notify=primeProgressChanged)
    def primeProgress(self):
        return self._prime_progress

    @Property(list, notify=timersChanged)
    def timers(self):
        return self._timers

    @Property(dict, notify=hopperChanged)
    def hopper(self):
        return self._hopper

    @Property(str, notify=pModeChanged)
    def pMode(self):
        return self._p_mode

    @Property(str, notify=unitsChanged)
    def units(self):
        return self._units

    @Property(list, notify=historyDataChanged)
    def historyData(self):
        return self._history_data

    @Property(dict, notify=langDataChanged)
    def langData(self):
        return self._lang_data

    @Slot(str, result=None)
    def setLanguage(self, lang_code):
        self.load_language(lang_code)

    # --- Server Configuration ---

    @Property(str, notify=serverAddressChanged)
    def serverIp(self):
        return self._custom_ip

    @Property(str, notify=serverSelectionChanged)
    def serverSelection(self):
        return self._server_selection

    @Slot(str, str, result=None)
    def setServerConfig(self, selection, ip):
        print(f"Bridge: Setting Server Config -> Mode: {selection}, IP: {ip}")
        self._server_selection = selection
        self._custom_ip = ip
        self.save_config()
        self.update_base_url()
        self.serverAddressChanged.emit(self._custom_ip)
        self.serverSelectionChanged.emit(self._server_selection)

    def load_config(self):
        try:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            path = os.path.join(current_dir, "config.json")
            if os.path.exists(path):
                with open(path, 'r') as f:
                    data = json.load(f)
                    self._server_selection = data.get('server_selection', 'pifire')
                    self._custom_ip = data.get('custom_ip', '')
                    print(f"Bridge: Config Loaded. Mode: {self._server_selection}, IP: {self._custom_ip}")
            else:
                 print("Bridge: No config file found. Using defaults.")
        except Exception as e:
            print(f"Bridge: Error loading config: {e}")
            
        self.update_base_url()

    def save_config(self):
        try:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            path = os.path.join(current_dir, "config.json")
            data = {
                'server_selection': self._server_selection,
                'custom_ip': self._custom_ip
            }
            with open(path, 'w') as f:
                json.dump(data, f)
            print("Bridge: Config saved.")
        except Exception as e:
             print(f"Bridge: Error saving config: {e}")

    def update_base_url(self):
        if self._server_selection == "localhost":
             self.base_url = "http://localhost"
        elif self._server_selection == "pifire":
             self.base_url = "http://pifire.local"
        else:
             # Custom
             url = self._custom_ip.strip()
             if not url:
                 url = "http://pifire.local" # Fallback
             
             if not url.startswith("http"):
                 url = "http://" + url
             self.base_url = url
             
        print(f"Bridge: Base URL updated to: {self.base_url}")
        # Re-init headers referer
        self.headers['Referer'] = f'{self.base_url}/events/'

    # --- Logic ---

    def update_status(self):
        if self._is_updating:
            return

        self._is_updating = True
        # Fetch hopper every time as requested by user
        fetch_hopper = True 
        
        threading.Thread(target=self._fetch_task, args=(fetch_hopper,), daemon=True).start()

    def _fetch_task(self, fetch_hopper):
        result = {"success": False, "data": {}, "hopper_data": None}
        try:
            # 1. Fetch Current Status
            response = requests.get(f"{self.base_url}/api/current", headers=self.headers, timeout=2, verify=False)
            if response.status_code in [200, 201]:
                result["success"] = True
                result["data"] = response.json()
            else:
                result["error"] = f"Error: {response.status_code}"
                self._apiResponseReceived.emit(result)
                return

            # 2. Fetch Hopper (Optional)
            if fetch_hopper:
                try:
                    h_response = requests.get(f"{self.base_url}/api/hopper", headers=self.headers, timeout=2, verify=False)
                    if h_response.status_code in [200, 201]:
                        result["hopper_data"] = h_response.json()
                except:
                    pass # Fail silently for hopper, main status is more important

            try:
                self._apiResponseReceived.emit(result)
            except RuntimeError:
                pass # App is shutting down
            
        except requests.exceptions.RequestException:
             # Fallback to mock logic if connection fails
             self._apiResponseReceived.emit({"success": False, "mock": True})
        except Exception as e:
             self._apiResponseReceived.emit({"success": False, "error": str(e)})

    def _process_response(self, result):
        self._is_updating = False
        
        if result.get("history_point"):
            # Handle Single Point Update from Stream
            h_data = result.get("data", {})
            # print(f"DEBUG Stream Data: {h_data}") # Uncomment to inspect if needed
            self.historyPointChanged.emit(h_data)
            return
        
        if result.get("history"):
             # Process History Data
             raw_data = result.get("data", {})
             # Normalize for QML: [ {name: "Grill", points: [{x,y},...]}, ... ]
             
             # PiFire structure usually: 
             # { "result": "OK", "data": { "time_labels": [...], "Grill": [...], ... } }
             # OR direct keys if via refresh?
             
             # Let's assume the payload IS the data or data is inside 'data'.
             actual_data = raw_data.get('data', raw_data) 
             
             labels = actual_data.get('time_labels', [])
             # labels are usually strings "HH:MM". ChartView needs X (timestamp or index) and Y.
             # If we only have labels, we might map them to index 0..N.
             
             series_list = []
             
             # Iterate keys to find probe data
             for key, values in actual_data.items():
                 # Structure: {'chart_data': [ {'label': 'Grill', 'data': [{'x':..., 'y':...}]}, ...]}
                 
                 if key == 'chart_data' and isinstance(values, list):
                     print(f"DEBUG Found chart_data with {len(values)} datasets")
                     for dataset in values:
                         if not isinstance(dataset, dict): continue
                         
                         name = dataset.get('label', 'Unknown')
                         raw_points = dataset.get('data', [])
                         # DEBUG: Inspect the first point to verify format
                         if len(raw_points) > 0:
                             print(f"DEBUG {name} First Point: {raw_points[0]}")
                         
                         points = []
                         for i, p in enumerate(raw_points):
                             if isinstance(p, dict):
                                 # Use 'x' (timestamp ms) and 'y' (temp)
                                 x = p.get('x')
                                 y = p.get('y')
                                 
                                 # Fallback to index if x missing
                                 x_val = float(x) if x is not None else float(i)
                                 
                                 if y is not None:
                                     points.append({"x": x_val, "y": float(y)})
                             else:
                                 # Fallback if just list of numbers
                                 points.append({"x": float(i), "y": float(p)})
                         
                         series_list.append({"name": name, "points": points})
                 
                 # Original fallback (if specific probe keys exist directly)
                 elif isinstance(values, list) and key not in ['time_labels', 'annotations', 'result']:
                     # ... (Old logic if mixed, but seems it's all in chart_data now)
                     pass

             self._history_data = series_list
                 
             self._history_data = series_list
             self.historyDataChanged.emit(self._history_data)
             return

        if result.get("success"):
            # print("Bridge: API Success") # Uncomment for verbose debug
            data = result["data"]
            
            # Merge Hopper Data if present
            if result.get("hopper_data"):
                h_data = result["hopper_data"]
                self._hopper_details = {
                    "level": h_data.get("hopper_level", 0),
                    "name": h_data.get("hopper_pellets", "Unknown")
                }
                # We also inject this into 'notify_data' parsing logic via override if needed, 
                # but since we merge in _parse_data using _hopper_details, we just need to set the attribute here.
                
            # Synthetic History Point Emission (1Hz)
            if self._history_active:
                now = time.time()
                if now - self._last_history_emit >= 1.0:
                    self._last_history_emit = now
                    
                    # Construct point data based on current state
                    # We utilize the RAW 'data' dict for current values to be accurate
                    curr = data.get('current', {})
                    p_temps = curr.get('P', {})
                    f_temps = curr.get('F', {})
                    
                    temps = {}
                    if 'Grill' in p_temps:
                        temps["Grill"] = int(float(p_temps['Grill']))
                    
                    # SetPoint
                    # Use existing self._set_point if tracked, or parse fresh
                    temps["SetPoint"] = self._set_point
                    
                    for pname, pval in f_temps.items():
                        temps[pname] = int(float(pval))
                        
                    point_data = {
                        "x": int(now * 1000), # ms timestamp
                        "temps": temps
                    }
                    self.historyPointChanged.emit(point_data)

            self._parse_data(data)
        elif result.get("mock"):
            print("Bridge: connection failed, using Mock Data")
            self._handle_mock_data()
        else:
            print(f"Bridge: Update Error: {result.get('error')}")
            self._status = result.get("error", "Unknown Error")
            self.statusChanged.emit(self._status)

    def _parse_data(self, data):
        # 1. Parse Status & Mode
        status_node = data.get('status', {})
        # ...
        
        # Debugging Temp
        p_current = data.get('current', {}).get('P', {})
        if 'Grill' in p_current:
             g_temp = p_current['Grill']
             # print(f"Bridge: Parsed Grill Temp: {g_temp}") 
             
        # ... rest of parsing logic stays same, just re-inserting method to ensure correct indentation/scope if needed
        # but replace_file_content needs context.
        
        new_mode = status_node.get('mode', 'Unknown')
        new_display_mode = status_node.get('display_mode', 'Unknown')
        
        if self._mode != new_mode:
            self._mode = new_mode
            self.modeChanged.emit(self._mode)
            
        if self._status != new_display_mode:
            self._status = new_display_mode
            self.statusChanged.emit(self._status)

        # Extended Status Parsing
        new_outpins = status_node.get('outpins', {})
        if self._outpins != new_outpins:
            self._outpins = new_outpins
            self.outpinsChanged.emit(self._outpins)

        new_lid_open = status_node.get('lid_open_detected', False)
        if self._lid_open != new_lid_open:
            self._lid_open = new_lid_open
            self.lidOpenChanged.emit(self._lid_open)

        new_s_plus = status_node.get('s_plus', False)
        if self._s_plus != new_s_plus:
            self._s_plus = new_s_plus
            self.sPlusChanged.emit(self._s_plus)
            
        new_p_mode = str(status_node.get('p_mode', '--'))
        if self._p_mode != new_p_mode:
            self._p_mode = new_p_mode
            self.pModeChanged.emit(self._p_mode)

        if self._p_mode != new_p_mode:
            self._p_mode = new_p_mode
            self.pModeChanged.emit(self._p_mode)

        # Mode Progress Parsing
        # Startup
        start_duration = status_node.get('start_duration', 0)
        
        if self._start_duration != start_duration:
            self._start_duration = start_duration
            self.startDurationChanged.emit(self._start_duration)

        startup_timestamp = status_node.get('startup_timestamp', 0)
        current_ts_ms = data.get('current', {}).get('TS', 0)
        current_ts = current_ts_ms / 1000.0 if current_ts_ms > 0 else 0
        
        new_startup_progress = 0.0
        if start_duration > 0 and startup_timestamp > 0 and current_ts > 0:
            elapsed = current_ts - startup_timestamp
            new_startup_progress = min(max(elapsed / start_duration, 0.0), 1.0)
            
        if self._startup_progress != new_startup_progress:
             self._startup_progress = new_startup_progress
             self.startupProgressChanged.emit(self._startup_progress)
             
        # Start Time (Global)
        if startup_timestamp != self._start_time:
            self._start_time = startup_timestamp
            self.startTimeChanged.emit(self._start_time)

        # Prime Duration & Mode Start Time
        prime_duration = status_node.get('prime_duration', 0)
        mode_start_time = status_node.get('start_time', 0)
        
        if self._prime_duration != prime_duration:
            self._prime_duration = prime_duration
            self.primeDurationChanged.emit(self._prime_duration)
            
        if self._mode_start_time != mode_start_time:
             self._mode_start_time = mode_start_time
             self.modeStartTimeChanged.emit(self._mode_start_time)

        # Calculate Prime Progress
        new_prime_progress = 0.0
        if prime_duration > 0 and mode_start_time > 0 and current_ts > 0:
            p_elapsed = current_ts - mode_start_time
            new_prime_progress = min(max(p_elapsed / prime_duration, 0.0), 1.0)
            
        if self._prime_progress != new_prime_progress:
            self._prime_progress = new_prime_progress
            self.primeProgressChanged.emit(self._prime_progress)

        # Shutdown
        shutdown_duration = status_node.get('shutdown_duration', 0)
        # shutdown_timestamp isn't explicit in API usually, but if mode is Shutdown we can guess or use a timer?
        # Actually API logic usually sends 'shutdown_duration' as remaining or static?
        # Let's check status 'shutdown_duration' usually static total.
        # But for now let's just expose the duration if needed, or if available, use it.
        # Actually, if display_mode is Shutdown, often we don't get a timestamp easily unless we track it
        # or if PiFire sends it. Let's stick to startup which is clean.
        
        new_units = status_node.get('units', 'C')
        if self._units != new_units:
            self._units = new_units
            self.unitsChanged.emit(self._units)

        # 2. Parse Grill Temp
        current = data.get('current', {})
        p_current = current.get('P', {})
        
        new_grill_temp = 0
        if 'Grill' in p_current:
            new_grill_temp = int(float(p_current['Grill']))
        
        if self._grill_temp != new_grill_temp:
            self._grill_temp = new_grill_temp
            self.grillTempChanged.emit(self._grill_temp)
            
        # 3. Parse Notify Data (Set Point, Timers, Hopper, Probe Targets)
        notify_data = data.get('notify_data', [])
        
        # Try to get set_point from current['PSP'] first (User specified location)
        current_data = data.get('current', {})
        new_set_point = int(float(current_data.get('PSP', 0)))
        
        # Fallback to status if not found (though user says it's in PSP)
        if new_set_point == 0:
             new_set_point = int(status_node.get('primary_setpoint', 0))
        if new_set_point == 0:
             new_set_point = int(status_node.get('set_point', 0))

        new_timers = []
        new_hopper = {}
        probe_targets = {} # Map 'ProbeName' -> target_temp
        probe_names = {} # Map 'ProbeName' -> Friendly Name
        
        # Probe Status for Enabled check
        probe_status = status_node.get('probe_status', {}).get('F', {}) # Food probes section
        
        for item in notify_data:
            # Set Point (Grill) - only use if we didn't find it in status
            if new_set_point == 0 and item.get('label') == 'Grill' and item.get('type') == 'probe':
                new_set_point = int(float(item.get('target', 0)))
            
            # Probe Targets & Names
            if item.get('label') != 'Grill' and item.get('type') == 'probe':
                label = item.get('label')
                target = int(float(item.get('target', 0)))
                probe_targets[label] = target
                if 'name' in item:
                    probe_names[label] = item['name']

            # Timers
            if item.get('type') == 'timer':
                new_timers.append(item)
                
            # Hopper
            if item.get('type') == 'hopper':
                new_hopper = item

        if self._set_point != new_set_point:
            self._set_point = new_set_point
            self.setPointChanged.emit(self._set_point)

        if self._timers != new_timers:
            self._timers = new_timers
            self.timersChanged.emit(self._timers)
            
        # Always merge persisted hopper details (level/name) into the current hopper state
        if self._hopper_details:
             new_hopper.update(self._hopper_details)
            
        if self._hopper != new_hopper:
            self._hopper = new_hopper
            self.hopperChanged.emit(self._hopper)

        # 4. Parse Probes (with Targets and Names)
        f_current = current.get('F', {})
        new_probes = []
        for key in sorted(f_current.keys()):
            # Check enabled string/bool in probe_status
            p_config = probe_status.get(key, {})
            is_enabled = p_config.get('enabled', False)
            if not is_enabled:
               continue
               
            temp = int(float(f_current[key]))
            target = probe_targets.get(key, 0) # Default to 0 if no target
            name = probe_names.get(key, key) # Default to key if no name
            new_probes.append({'name': name, 'temp': temp, 'target': target})
            
        if self._probes != new_probes:
            self._probes = new_probes
            self.probesChanged.emit(self._probes)

    def _handle_mock_data(self):
        # Only print once to avoid spamming
        # print("Bridge: Using Mock Data (Extended)")
        mock_json = {
            "current": {
                "AUX": {},
                "F": {"Probe1": 85, "Probe2": 90}, 
                "NT": {"Grill": 0, "Probe1": 0, "Probe2": 0},
                "P": {"Grill": 24},
                "PSP": 0
            },
            "notify_data": [
                {"condition": "equal_above", "label": "Grill", "target": 110, "type": "probe"},
                {"condition": "equal_above", "label": "Probe1", "target": 95, "type": "probe"}, # Mock Target
                {"keep_warm": False, "label": "Timer", "req": False, "shutdown": False, "type":"timer", "time_remaining": 300}, 
                {"keep_warm": False, "label": "Hopper", "last_check": 0, "req": True, "shutdown": False, "type":"hopper", "level": 80, "name": "Hickory"} # Mock Hopper Level
            ],
            "status": {
                "critical_error": False,
                "display_mode": "Startup",
                "lid_open_detected": True,
                "mode": "Startup",
                "outpins": {"auger": True, "fan": True, "igniter": False, "power": True},
                "s_plus": True,
                "p_mode": "4",
                "units": "C"
            }
        }
        self._parse_data(mock_json)

    # --- Slots called from QML ---

    @Slot(str, result=None)
    def sendCommand(self, command):
        """Generic command sender.
           command: 'startup', 'shutdown', 'smoke', 'hold', 'stop', 'monitor'
        """
        endpoint = "/api/control" 
        
        # Capitalize command for API (startup -> Startup)
        mode_str = command.capitalize() 
        # API expects JSON payload: {"updated": true, "mode": "Startup"}
        payload = {'updated': True, 'mode': mode_str}
        
        # Specific headers for Control
        control_headers = self.headers.copy()
        control_headers['Referer'] = f'{self.base_url}/dash/'
        control_headers['Content-Type'] = 'application/json; charset=utf-8'
        
        print(f"Sending command: {mode_str} data={payload}")
        
        threading.Thread(target=lambda: self._send_post(endpoint, payload, control_headers, is_json=True), daemon=True).start()

    @Slot(int, str, result=None)
    def sendPrime(self, amount, next_mode):
        """Send Prime command with amount and next mode."""
        endpoint = "/api/control"
        # Payload: {"updated": true, "mode": "Prime", "prime_amount": 10, "next_mode": "Stop"}
        payload = {
            'updated': True, 
            'mode': 'Prime', 
            'prime_amount': amount, 
            'next_mode': next_mode
        }
        
        control_headers = self.headers.copy()
        control_headers['Referer'] = f'{self.base_url}/dash/'
        control_headers['Content-Type'] = 'application/json; charset=utf-8'
        
        print(f"Sending Prime: {amount}g -> {next_mode}")
        threading.Thread(target=lambda: self._send_post(endpoint, payload, control_headers, is_json=True), daemon=True).start()

    @Slot(bool, result=None)
    def toggleSmokePlus(self, current_state):
        """Toggle Smoke Plus mode."""
        endpoint = "/api/control"
        # Payload: {"s_plus": true/false}
        target_state = not current_state
        payload = {'s_plus': target_state}
        
        control_headers = self.headers.copy()
        control_headers['Referer'] = f'{self.base_url}/dash/'
        control_headers['Content-Type'] = 'application/json; charset=utf-8'
        
        print(f"Sending Smoke Plus: {target_state}")
        threading.Thread(target=lambda: self._send_post(endpoint, payload, control_headers, is_json=True), daemon=True).start()

    @Slot(int, result=None)
    def setPMode(self, p_mode):
        """Set P-Mode profile (0-9) via settings then trigger update."""
        
        def sequence():
            headers = self.headers.copy()
            headers['Referer'] = f'{self.base_url}/dash/'
            headers['Content-Type'] = 'application/json; charset=utf-8'
            
            # 1. Update Settings
            print(f"Setting P-Mode: {p_mode} -> /api/settings")
            try:
                requests.post(
                    f"{self.base_url}/api/settings", 
                    json={'cycle_data': {'PMode': p_mode}}, 
                    headers=headers, 
                    timeout=2, 
                    verify=False
                )
            except Exception as e:
                print(f"Error setting PMode: {e}")
                return

            # 2. Trigger Update
            print(f"Triggering Settings Update -> /api/control")
            try:
                requests.post(
                    f"{self.base_url}/api/control", 
                    json={'settings_update': True}, 
                    headers=headers, 
                    timeout=2, 
                    verify=False
                )
            except Exception as e:
                print(f"Error triggering update: {e}")

        threading.Thread(target=sequence, daemon=True).start()

    @Slot()
    def startHistoryStream(self):
        """Enable 1Hz history updates via polling."""
        print("DEBUG: Enabling History Updates (1Hz)")
        self._history_active = True

    @Slot()
    def stopHistoryStream(self):
        """Disable history updates."""
        self._history_active = False

    # Stream task removed in favor of polling emission in _process_response

    @Slot(int, result=None)
    def setTargetTemp(self, temp):
        """Set target temperature (switches to Hold mode)."""
        endpoint = "/api/control"
        # Payload: {"updated": true, "mode": "Hold", "primary_setpoint": 470}
        payload = {
            'updated': True,
            'mode': 'Hold',
            'primary_setpoint': temp
        }
        
        control_headers = self.headers.copy()
        control_headers['Referer'] = f'{self.base_url}/dash/'
        control_headers['Content-Type'] = 'application/json; charset=utf-8'
        
        print(f"Setting Target Temp: {temp} (Hold Mode)")
        threading.Thread(target=lambda: self._send_post(endpoint, payload, control_headers, is_json=True), daemon=True).start()

    @Slot(str, result=None)
    def fetchHistory(self, mins_str="60"):
        """Fetch history data (default last 60 mins)."""
        endpoint = "/history/refresh"
        payload = {"num_mins": mins_str}
        
        hist_headers = self.headers.copy()
        hist_headers['Referer'] = f'{self.base_url}/history/'
        hist_headers['Content-Type'] = 'application/json; charset=utf-8'
        hist_headers['Origin'] = self.base_url
        
        print(f"Fetching History: {mins_str} mins")
        threading.Thread(target=lambda: self._fetch_history_task(endpoint, payload, hist_headers), daemon=True).start()

    def _fetch_history_task(self, endpoint, payload, headers):
        try:
             response = requests.post(f"{self.base_url}{endpoint}", json=payload, headers=headers, timeout=5, verify=False)
             if response.status_code == 200:
                  json_data = response.json()
                  self._apiResponseReceived.emit({"success": True, "history": True, "data": json_data})
             else:
                  print(f"History Fetch Failed: {response.status_code}")
        except Exception as e:
             print(f"History Fetch Error: {e}")

    def _send_post(self, endpoint, data, headers, is_json=False):
        try:
            if is_json:
                requests.post(f"{self.base_url}{endpoint}", json=data, headers=headers, timeout=2, verify=False)
            else:
                requests.post(f"{self.base_url}{endpoint}", data=data, headers=headers, timeout=2, verify=False)
            # Force immediate logic update handled by next poll
        except Exception as e:
            print(f"Command failed: {e}") 

