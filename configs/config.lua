local Config = {}

-- Sprache zentral steuern
Config.Language = "de"

Config.App = {
  Name = "dispatch_phone",
  Label = "Dispatch",

  -- optional: lege web/public/dispatch.png an -> nach build: web/build/dispatch.png
  Icon = "web/build/icon.svg",

  IconBackground = { angle = 45, colors = { "#0ea5e9", "#22c55e" } },
  Default = false,
  PreInstalled = false,
}

Config.Dispatch = {
  DurationSeconds = 300,
  DefaultPriority = "medium",

  Sounds = {
    police = "notification.mp3",
    ambulance = "notification2.mp3",
  },

  Blip = {
    Enabled = true,
    police = { sprite = 60, color = 3, size = 0.9, shortRange = false, label = "Dispatch" },
    ambulance = { sprite = 61, color = 1, size = 0.9, shortRange = false, label = "Dispatch" },
  }
}

Config.Dispatch.CooldownSeconds = 180 -- 3 Minuten

Config.Departments = {
  { id = "sasp",    label = "SASP",     tabletJob = "sasp" },
  -- { id = "sheriff", label = "SHERIFFS", tabletJob = "police" },
  { id = "sams",     label = "SAMS",      tabletJob = "sams" },
  --{ id = "acls",    label = "ACLS",     tabletJob = "ambulance" },
}

_G.Config = Config
return Config