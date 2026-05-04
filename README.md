# PoE Kingsmarch Dust Calculator

An AutoHotkey v2 tool that provides an in-game overlay for Path of Exile to calculate and display the Disenchant (Dust) value of unique items.

[![License](https://img.shields.io/github/license/TeeraThew/PoE-Dust-Calculator?label=License)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/TeeraThew/PoE-Dust-Calculator?label=Latest%20Release)](https://github.com/TeeraThew/PoE-Dust-Calculator/releases/latest)

## 🌟 Features
- **Data Scraping:** Automatically fetches and updates the latest base dust values from [PoEDB](https://poedb.tw/us/Kingsmarch#Disenchant).
- **Dust Calculation:** Calculates dust values based on item level scaling. Factors in Quality, Influences, and Corrupted Implicits.

## 🚀 How to Run

### Option 1: Standalone Executable (Recommended)
1. Go to the [Releases](https://github.com/TeeraThew/PoE-Dust-Calculator/releases) page.
2. Download `dust_calculator.exe`.
3. Run the `.exe`. You do **not** need to install AutoHotkey.
   * *Note: Antivirus software may flag the .exe as a false positive. This is a common occurrence with compiled AHK scripts. You can always run from source if you prefer.*

### Option 2: Running from Source
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Clone this repository or download the ZIP.
3. Run `src/dust_calculator.ahk`.

## 🎮 How to Use
1. Ensure the script is running (check your Windows system tray for the icon).
2. In Path of Exile, hover your mouse over a **Unique Item** and press **F4**.
   * The script automatically triggers an "Advanced Description" copy, calculates the value, and displays the overlay.
   * **Tip:** For the most accurate calculation of Corrupted Implicits, use the **Advanced Description** (ensure your PoE settings allow for detailed tooltips).
4. **Closing the Overlay:** The overlay will automatically close after 2 seconds. Alternatively, you can Left-click or Right-click to close it.

## 🛠 Project Structure
- `src/`: Main AutoHotkey source code.  
- `data/`: Local storage for `dust_values.data` and metadata (created on first run).
- `dist/`: Compiled binaries.
- `logs/`: Debugging logs for troubleshooting and error tracking.

## 📊 Dust Calculation
The total dust is calculated as: 

$$
\text{TotalDust} = \text{Floor}(\text{BaseDust} \times \text{LevelMultiplier} \times \text{BonusFactor})
$$

- **Base Dust Value:** Base dust value for each unique item from [PoEDB](https://poedb.tw/us/Kingsmarch#Disenchant).
- **Item Level:** Multiplies the base dust value by the item level scaling factor.
- **Quality Bonus:** +2% per 1% Quality (40% at Q20).
- **Influence Bonus:** +50% per Influence type (Shaper, Elder, Conquerors).
- **Corruption Bonus:** +50% per Corrupted Implicit modifier.

## 📜 Credits
- Dust data sourced from [PoEDB](https://poedb.tw/us/Kingsmarch#Disenchant).
- Developed with [AutoHotkey v2](https://www.autohotkey.com/).

## ⚖️ License
This project is licensed under the [MIT License](https://github.com/TeeraThew/PoE-Dust-Calculator/blob/main/LICENSE)