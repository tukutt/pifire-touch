import QtQuick 2.15

QtObject {
    id: strings
    property string language: "en" 
    
    // Bind to the dynamic dictionary from Bridge
    property var db: bridge.langData 

    // Helper to switch - Now calls bridge
    function toggle() {
        var newLang = (language === "fr" ? "en" : "fr")
        setLang(newLang)
    }
    
    function setLang(code) {
        language = code
        bridge.setLanguage(code)
    }

    // --- STRINGS BINDINGS ---
    // If key missing, fallback to key name or empty string
    
    // Navigation
    readonly property string nav_dashboard: db["nav_dashboard"] || "nav_dashboard"
    readonly property string nav_history: db["nav_history"] || "nav_history"
    readonly property string nav_pellets: db["nav_pellets"] || "nav_pellets"
    readonly property string nav_recipe: db["nav_recipe"] || "nav_recipe"
    readonly property string nav_settings: db["nav_settings"] || "nav_settings"

    // Dashboard
    readonly property string dash_control_title: db["dash_control_title"] || "dash_control_title"
    readonly property string dash_startup: db["dash_startup"] || "dash_startup"
    readonly property string dash_smoke: db["dash_smoke"] || "dash_smoke"
    readonly property string dash_monitor: db["dash_monitor"] || "dash_monitor"
    readonly property string dash_prime: db["dash_prime"] || "dash_prime"
    readonly property string dash_shutdown: db["dash_shutdown"] || "dash_shutdown"
    readonly property string dash_stop: db["dash_stop"] || "dash_stop"
    readonly property string dash_target: db["dash_target"] || "dash_target"
    
    readonly property string dash_confirm_start_title: db["dash_confirm_start_title"] || "dash_confirm_start_title"
    readonly property string dash_confirm_start_msg: db["dash_confirm_start_msg"] || "dash_confirm_start_msg"
    readonly property string dash_btn_cancel: db["dash_btn_cancel"] || "dash_btn_cancel"
    readonly property string dash_btn_apply: db["dash_btn_apply"] || "dash_btn_apply"
    readonly property string dash_btn_letsgo: db["dash_btn_letsgo"] || "dash_btn_letsgo"
    
    readonly property string dash_prime_title: db["dash_prime_title"] || "dash_prime_title"
    readonly property string dash_prime_msg: db["dash_prime_msg"] || "dash_prime_msg"
    readonly property string dash_target_title: db["dash_target_title"] || "dash_target_title"
    
    // Status
    readonly property string status_lid_open: db["status_lid_open"] || "status_lid_open"
    readonly property string status_probes: db["status_probes"] || "status_probes"
    readonly property string status_no_probes: db["status_no_probes"] || "status_no_probes"
    
    // Settings
    readonly property string settings_title: db["settings_title"] || "settings_title"
    readonly property string settings_language: db["settings_language"] || "settings_language"
    readonly property string settings_units: db["settings_units"] || "settings_units"
    readonly property string settings_server_title: db["settings_server_title"] || "settings_server_title"
    readonly property string settings_server_placeholder: db["settings_server_placeholder"] || "settings_server_placeholder"
}
