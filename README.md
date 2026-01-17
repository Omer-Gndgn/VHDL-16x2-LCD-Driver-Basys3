# VHDL 16x2 LCD Driver for Basys 3 FPGA
This project implements a VHDL-based driver for a standard HD44780 16x2 LCD module using the Digilent Basys 3 FPGA board (Artix-7). The driver handles the 4-bit initialization sequence and timing constraints to display static text on the screen.

## Features 
- **Pure VHDL:** Written in VHDL (IEEE 1164).
- **4-Bit Mode:** Uses only 6 I/O pins (4 Data + RS + E) to save FPGA resources.
- **Auto Initialization:** Implements the proper power-up and initialization sequence specified in the HD44780 datasheet.
- **Static Display:** Designed to display fixed text strings on both lines.
- **Custom Timing:** Delays are calculated for a 100 MHz system clock.

## Hardware Setup
- **FPGA Board:** Xilinx Basys 3 (Artix-7 XC7A35T)
- **Display:** Standard 16x2 LCD (HD44780 Controller)
- **Connection:** Pmod Header JA (Port A)

### Pinout Mapping (Pmod JA)

| FPGA Pin (JA) | LCD Pin | Function |
| :--- | :--- | :--- |
| **JA 1** (J1) | RS (4) | Register Select (0=Cmd, 1=Data) |
| **JA 2** (L2) | E (6) | Enable Signal |
| **JA 3** (J2) | D4 (11) | Data Bit 4 |
| **JA 4** (G2) | D5 (12) | Data Bit 5 |
| **JA 7** (H1) | D6 (13) | Data Bit 6 |
| **JA 8** (K2) | D7 (14) | Data Bit 7 |
| **GND** | RW (5) | Read/Write (Must be connected to GND) |
| **GND** | VSS (1) | Ground |
| **5V** | VDD (2) | Power Supply |

> **Note:** The `RW` pin on the LCD must be connected to GND since this driver only performs write operations.

###  Power Supply Note (Important)
Although the Basys 3 outputs 3.3V logic, standard HD44780 LCDs often require **5V for the backlight and VDD** to achieve good contrast. 

In this setup, an **Arduino Uno** was used solely as an external **5V Power Supply**:
1. **Arduino 5V** -> **LCD VDD (Pin 2)**
2. **Arduino GND** -> **LCD VSS (Pin 1)** & **FPGA GND** (Common Ground)

> **Warning:** When using an external power source (like Arduino), you **MUST** connect the external GND to the FPGA's GND (Common Ground). Otherwise, the signal reference will be lost, and the data transfer will fail.

## How to Use
1. Create a new project in Vivado targeting the Basys 3 board.
2. Add `LCD_16x2.vhd` as a design source.
3. Add `Basys3_LCD.xdc` as a constraint file.
4. Generate Bitstream and program the device.

## Demonstration
The project displays:
Line 1: "SAKARYA UNIV."
Line 2: "MUHENDISLIK" 

<img width="721" height="1600" alt="image" src="https://github.com/user-attachments/assets/ec5b7337-9f4f-48d7-8895-44560b4c0f52" />

## Author
**Abdullah Ömer Gündoğan**
Sakarya University - Electrical and Electronics Engineering
