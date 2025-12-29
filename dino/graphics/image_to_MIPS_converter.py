import os
from PIL import Image

def convert_interactive():
    print("--- Image to MIPS Converter ---")
    
    path_input = input("Enter image path: ").strip('"')
    
    try:
        width_input = int(input("Enter Width: "))
        height_input = int(input("Enter Height: "))
    except ValueError:
        print("Error: Please enter valid numbers!")
        return

    try:
        img = Image.open(path_input)
        img = img.convert('RGB')
        img = img.resize((width_input, height_input))
        
        pixels = list(img.getdata())
        
        print("\n" + "="*30)
        print(f".eqv IMG_W {width_input}")
        print(f".eqv IMG_H {height_input}")
        print("image_data: .word")
        
        for i, pixel in enumerate(pixels):
            r, g, b = pixel
            hex_color = "0x00{:02X}{:02X}{:02X}".format(r, g, b)
            
            if i % width_input == 0:
                print("\n    ", end="")
            
            print(f"{hex_color}", end="")
            
            if i != len(pixels) - 1:
                print(", ", end="")
                
        print("\n")
        print("="*30)

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    convert_interactive()
    input("\nPress Enter to exit...")