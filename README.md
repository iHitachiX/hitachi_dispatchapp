# hitachi_dispatchapp

A modern dispatch app for **17mov_Phone**, allowing players to send reports directly to dispatch through their in-game phone.

Fully compatible with **kartik-mdt**.

---

## ✨ Features

- Integration into 17mov Phone UI
- Create dispatch calls directly in-game
- Support for multiple departments
- Priority system (low, medium, high)
- Automatic location transmission (street name & coordinates)
- Option to send reports anonymously
- Per-department cooldown system
- Fully configurable departments with MDT category mapping

---

## 🔧 Dependencies

- [17mov_Phone](https://17movement.net/products/17mov_phone)
- [ox_lib](https://github.com/overextended/ox_lib)
- [kartik-mdt](https://kartikscripts.store/)

---

## ⚙️ Configuration

Departments are configured in `configs/config.lua`:

```lua
Config.Departments = {
    sasp = { label = "SASP", job = "sasp", mdtCategory = "police" },
    bcso = { label = "BCSO", job = "bcso", mdtCategory = "police" },
    sams = { label = "SAMS", job = "ambulance", mdtCategory = "ems" },
}
```

- `job` – the in-game job name
- `mdtCategory` – the kartik-mdt job category (from `Config.Jobs` in kartik-mdt)

---

## 🛠️ Tech Stack

The UI has been fully rewritten from **React + Redux** to **Svelte 5** with Vite.

**Bundle size:** ~20kb instead of ~60kb

---

## 📜 Credits

- Original author:  
  https://github.com/DerHobbs?tab=repositories