.pragma library

function emptyLocation() {
  return { name: "", timezone: "", latitude: null, longitude: null }
}

function parseLocation(data) {
  var loc = data && data.location
  if (!loc || typeof loc !== "object") return emptyLocation()
  var lat = parseFloat(loc.latitude)
  var lon = parseFloat(loc.longitude)
  return {
    name: String(loc.name || ""),
    timezone: String(loc.timezone || ""),
    latitude: isNaN(lat) ? null : lat,
    longitude: isNaN(lon) ? null : lon
  }
}

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
      keyboardPresent: data.keyboardPresent === true,
      location: parseLocation(data)
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
    keyboardPresent: false,
    location: emptyLocation()
  }
}

function isNight(theme) {
  return String(theme || "") === "omarchy-oq-night-ride"
}

function locationLabel(loc) {
  if (loc && loc.name) return loc.name
  if (loc && loc.timezone) return loc.timezone
  return "Not set"
}

function locationPreset(timezone) {
  switch (String(timezone || "")) {
    case "Australia/Brisbane": return "brisbane"
    case "Asia/Hong_Kong": return "hong-kong"
    case "Australia/Sydney": return "sydney"
    default: return ""
  }
}

function parseLocationSearch(raw) {
  try {
    var data = JSON.parse(String(raw || "{}"))
    var results = data.results
    if (!results || !results.length) return []
    var out = []
    for (var i = 0; i < results.length; i++) {
      var r = results[i]
      if (!r || !r.name || !r.timezone || r.latitude === undefined || r.longitude === undefined)
        continue
      out.push({
        name: String(r.name),
        description: String(r.description || ""),
        latitude: r.latitude,
        longitude: r.longitude,
        timezone: String(r.timezone)
      })
    }
    return out
  } catch (e) {
    return []
  }
}

function locationCommit(suggestions, selectedIndex) {
  var choices = suggestions || []
  if (!choices.length) return null
  var index = Math.max(0, Math.min(parseInt(selectedIndex, 10) || 0, choices.length - 1))
  var suggestion = choices[index]
  if (!suggestion || !suggestion.timezone) return null
  return suggestion
}
