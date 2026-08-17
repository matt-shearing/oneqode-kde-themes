.pragma library

function parseStatus(raw) {
  try {
    var data = JSON.parse(String(raw || "").trim())
    if (!data || typeof data !== "object") return emptyStatus()
    return {
      ok: data.ok === true,
      theme: String(data.theme || ""),
      themeLabel: String(data.themeLabel || "Unknown"),
      isOqTheme: data.isOqTheme === true,
      autoEnabled: data.autoEnabled === true,
      period: String(data.period || "unknown"),
      sunrise: String(data.sunrise || ""),
      sunset: String(data.sunset || ""),
      effect: String(data.effect || "heatmap"),
      effectId: Number(data.effectId || 0),
      brightness: Number(data.brightness || 100),
      keyboardPresent: data.keyboardPresent === true
    }
  } catch (e) {
    return emptyStatus()
  }
}

function emptyStatus() {
  return {
    ok: false,
    theme: "",
    themeLabel: "Unknown",
    isOqTheme: false,
    autoEnabled: false,
    period: "unknown",
    sunrise: "",
    sunset: "",
    effect: "heatmap",
    effectId: 45,
    brightness: 100,
    keyboardPresent: false
  }
}

function isNight(theme) {
  return String(theme || "") === "omarchy-oq-night-ride"
}
