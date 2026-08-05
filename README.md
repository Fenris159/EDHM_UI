<img src="Courrier-UEX/resources/SC-Courrier-UEX_Logo_01.png" alt="SC-Courrier-UEX Preview" width="200">

# Courrier-UEX

**A desktop companion for Star Citizen traders and haulers.**  
Plan profitable trade routes, find ship rentals, and optimize multi-stop cargo runs — powered by live UEX Corp data. 100% standalone and EAC-safe.

![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)
![Downloads](https://img.shields.io/github/downloads/YOURUSER/REPO/total)
![License](https://img.shields.io/badge/license-MIT-green)

[Install](#installation) • [Features](#features) • [Screenshots](#screenshots) • [Quick Start](#quick-start) • [FAQ](#faq) • [Support](#support)

---

## Screenshots

![Trade Route Planner](Courrier-UEX/resources/ScreenShot_01.jpg)

![Cargo Mission Planner](Courrier-UEX/resources/ScreenShot_02.jpg)

---

## Description

Courrier-UEX is a desktop companion app built for Star Citizen traders, haulers, and cargo pilots. It pulls live data from the UEX Corp API and wraps it in a fast, purpose-built interface so you don't have to tab out to a browser mid-session to plan a run.

Instead of juggling spreadsheets or browser tabs, open Courrier-UEX, check your route, and get back into the black.

&gt; **Disclaimer:** Courrier-UEX is an unofficial, fan-made tool. It is not affiliated with, endorsed by, or sponsored by Cloud Imperium Games or Roberts Space Industries. Star Citizen, Squadron 42, Roberts Space Industries, and Cloud Imperium are trademarks of Cloud Imperium Rights LLC/Ltd. All game data is sourced from UEX Corp, a fan-made, community-driven platform not affiliated with CIG.

---

## Installation

1. Go to the [Releases](../../releases) page.
2. Download the latest `.exe` installer.
3. Run the installer and follow the setup steps.
4. Launch Courrier-UEX from the Start Menu or Desktop shortcut.

### (Optional) Become a UEX Datarunner

Courrier-UEX can also submit data back to UEX Corp — contributing prices, stock, and other trade data to help keep the community database accurate. To do this, you'll need a UEX account, and the app will prompt you for your UEX login credentials.

This is entirely optional and not required for any of the app's core functionality — if you don't plan on contributing data, just leave the login fields blank.

---

## Quick Start

1. **Launch** the app and select your ship's cargo capacity.
2. **Search** for a commodity (e.g., *Agricium*) or item.
3. **Click Plan Route** to see the most profitable buy/sell path.
4. **(Optional)** Log in with your UEX account to contribute live data back to the community.

---

## Features

- **Commodities & Items Lookup** — Find the best places to buy or sell any commodity or item, with live pricing pulled from UEX.
- **Trade Route Planner** — Calculates the most profitable buy/sell routes between locations, filtered by your ship's cargo capacity.
- **Ship Rental Finder** — Quickly locate where to rent any ship (e.g., "where can I rent a Vulture?").
- **Cargo Mission Planner** — Plan multi-pickup / multi-drop hauling routes with an optimized stop order, per-leg task tracking, and a run timer to keep your mission on track.
- **Dark Mode, Fast Search, and Minimal UI** — Built to stay out of your way while you play.

---

## Requirements

- **Windows 10/11** (64-bit)
- **Internet connection** — The app queries the UEX Corp API for live trade/commodity data. On launch, it also does a single, one-time check for app updates. It does not run any background service or persistent connection — the app only talks to the network when you're actively using it or on startup.
- **No Star Citizen files are read, modified, or accessed.** Courrier-UEX runs entirely independent of the game client and is EAC-safe by design (it's a standalone companion app, not an in-game overlay or injector).

---

## Built With

- Electron / Vite / Vue / PrimeVue
- UEX Corp API

---

## FAQ

**Is this really EAC-safe?**  
Yes. Courrier-UEX is a completely standalone desktop application. It does not read, modify, or inject into Star Citizen in any way. It communicates only with the UEX Corp API over the internet.

**Do I need a UEX account to use the app?**  
No. A UEX account is only required if you want to contribute live price and stock data back to the community database. All core features work without logging in.

**The app says it can't reach UEX Corp. What do I do?**  
Check your internet connection and ensure your firewall or antivirus isn't blocking the app. Courrier-UEX needs outbound HTTPS access to fetch live data.

---

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

---

## Support

If you find Courrier-UEX useful, consider supporting development:

<a href="https://www.buymeacoffee.com/blue.mystic" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>


---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- **UEX Corp** — For building and maintaining the API and community-driven data that powers this tool.
