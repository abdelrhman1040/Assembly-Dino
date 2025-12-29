# MIPS Dino Run 🦖

A fully functional clone of the famous Chrome "No Internet" Dino game, written entirely in **MIPS Assembly Language**. This project demonstrates low-level programming concepts, memory manipulation, and real-time graphics rendering using the MARS Simulator.

![MIPS](https://img.shields.io/badge/Language-MIPS_Assembly-red)
![Simulator](https://img.shields.io/badge/Simulator-MARS_4.5-blue)
![Status](https://img.shields.io/badge/Status-Complete-green)

## 🎮 Game Overview
The player controls a dinosaur running through an endless desert. The goal is to survive as long as possible by jumping over obstacles (cactuses). The game features:
* **Real-time Rendering:** Graphics are drawn directly to the memory address of the Bitmap Display.
* **Physics Engine:** Custom logic for gravity, jumping velocity, and ground collision.
* **Collision Detection:** Pixel-perfect calculation to detect when the dino hits an obstacle.
* **Score Tracking:** The score increases as the game progresses.

## 🛠️ Prerequisites
To run this game, you need:
1.  **Java Runtime Environment (JRE)** installed on your machine.
2.  **MARS (MIPS Assembler and Runtime Simulator)**. You can download it [here](http://courses.missouristate.edu/KenVollmar/MARS/).

## ⚙️ Configuration & How to Run
Because this game uses the **Bitmap Display**, the simulator settings must be exact for the graphics to render correctly.

1.  Open `DinoGame.asm` (or your main file name) in MARS.
2.  Go to **Tools** -> **Bitmap Display**.
3.  Configure the Bitmap Display with the following settings:
    * **Unit Width:** 8
    * **Unit Height:** 8
    * **Display Width:** 256 (or 512 depending on your specific code)
    * **Display Height:** 256 (or 512)
    * **Base Address for Display:** `$gp` (Global Pointer)
4.  Click **"Connect to MIPS"** in the Bitmap Display window.
5.  Go to **Tools** -> **Keyboard and Display MMIO Simulator** (required for keyboard input).
6.  Click **"Connect to MIPS"** in the MMIO window.
7.  Assemble the code (`F3`) and Run (`F5`).

## 🕹️ Controls
* **W** or **Spacebar**: Jump
* **R**: Restart the game (after Game Over)

## 🧠 Technical Details
This project was developed as part of an Electronics and Communications Engineering (ECE) curriculum. Key technical implementations include:
* **Memory Mapping:** Direct writing to the `$gp` heap to manipulate pixel colors.
* **Input Polling:** Checking the Memory Mapped IO address `0xffff0000` for keyboard interrupts.
* **Sprite Management:** Storing pixel data for the dinosaur and obstacles in the `.data` segment.

## 👨‍💻 Author
**Abdelrahman Alaa**
* Student at Nile University (ECE)
* [Link to your LinkedIn or Portfolio if you want]

---
*Note: This project is for educational purposes to demonstrate computer architecture concepts.*
