# MIPS Dino Run 🦖

<img width="1084" height="549" alt="image" src="https://github.com/user-attachments/assets/e54ae5d3-c125-43f3-abda-7776e1eed4e9" />
<img width="1084" height="550" alt="image" src="https://github.com/user-attachments/assets/4f5b965d-2649-44d1-ac0f-9099623f48b2" />
<img width="1085" height="548" alt="image" src="https://github.com/user-attachments/assets/8e968b91-8c2a-4a46-bbff-eeaf5d54c3a1" />
<img width="1085" height="550" alt="image" src="https://github.com/user-attachments/assets/298a5969-8a11-4d8e-8a36-cfffcc28f22b" />


A fully functional clone of the famous Chrome "No Internet" Dino game, written entirely in **MIPS Assembly Language**. This project demonstrates low-level programming concepts, memory manipulation, and real-time graphics rendering using the MARS Simulator.

![MIPS](https://img.shields.io/badge/Language-MIPS_Assembly-red)
![Simulator](https://img.shields.io/badge/Simulator-MARS_4.5-blue)
![Status](https://img.shields.io/badge/Status-Complete-green)

## 🎮 Game Overview
* **Real-time Rendering:** Graphics are drawn directly to the memory address of the Bitmap Display.
* **Physics Engine:** Custom logic for gravity, jumping velocity, and ground collision.
* **Collision Detection:** Pixel-perfect calculation to detect when the dino hits an obstacle.

## 🛠️ Prerequisites
To run this game, you need:
1.  **Java Runtime Environment (JRE)** installed on your machine.
2.  **MARS (MIPS Assembler and Runtime Simulator)**. You can download it [here](http://courses.missouristate.edu/KenVollmar/MARS/).

## ⚙️ Configuration & How to Run
Because this game uses the **Bitmap Display**, the simulator settings must be exact for the graphics to render correctly.

1.  Open the `.asm` file in MARS.
2.  Go to **Tools** -> **Bitmap Display**.
3.  Set the following values:
    * **Unit Width in Pixels:** `4`
    * **Unit Height in Pixels:** `4`
    * **Display Width in Pixels:** `1024`
    * **Display Height in Pixels:** `512`
    * **Base address for display:** `0x10040000 (heap)`
4.  Click **"Connect to MIPS"** in the Bitmap Display window.
5.  Go to **Tools** -> **Keyboard and Display MMIO Simulator** (required for input).
6.  Click **"Connect to MIPS"** in the MMIO window.
7.  Assemble (`F3`) and Run (`F5`).

## 🕹️ Controls
**Spacebar**: Jump
**S**: To start the game

## 🧠 Technical Details
This project was developed as a final project for the **Computer Organization** course at Nile University.Key technical implementations include:
* **Memory Mapping:** Direct writing to the `0x10040000 (heap)` heap to manipulate pixel colors.
* **Input Polling:** Checking the Memory Mapped IO address `0xffff0000` for keyboard interrupts.
* **Sprite Management:** Storing pixel data for the dinosaur and obstacles in the `.data` segment.

## 👨‍💻 Team / Authors
* **Abdelrahman Alaa**
* **Amr Gaith**
* **Amro Mostafa**
* **Yara Alhussany**
* **Mohamed Medhat**

