#!/bin/bash

# Zmienne
APP_DIR="/opt/pipaint"
ICON_PATH="/usr/share/icons/hicolor/scalable/apps/pipaint.svg"

echo "🚀 Rozpoczynam instalację PiPaint Pro..."

# 1. Instalacja zależności
sudo apt update
sudo apt install -y python3 python3-tk python3-pil python3-pil.imagetk

# 2. Tworzenie struktury katalogów
sudo mkdir -p $APP_DIR

# 3. Zapisywanie kodu źródłowego bezpośrednio do /opt
echo "📝 Tworzenie plików aplikacji..."
sudo bash -c "cat << 'EOF' > $APP_DIR/paint.py
import tkinter as tk
from tkinter import colorchooser, filedialog, messagebox
from PIL import Image, ImageDraw, ImageTk
import random

class PiPaint:
    def __init__(self, root):
        self.root = root
        self.root.title('PiPaint Pro - RPi 5 Edition')
        self.root.geometry('1200x800')
        
        self.color = '#000000'
        self.brush_size = 5
        self.tool = 'pen'
        self.history = []
        self.start_x = None
        self.start_y = None
        self.temp_rect = None

        self.image = Image.new('RGB', (2000, 2000), 'white')
        self.draw = ImageDraw.Draw(self.image)
        self.setup_ui()

    def setup_ui(self):
        sidebar = tk.Frame(self.root, bg='#1e1e2e', width=160)
        sidebar.pack(side=tk.LEFT, fill=tk.Y)

        tk.Label(sidebar, text='PI-PAINT', fg='#cdd6f4', bg='#1e1e2e', font=('Arial', 14, 'bold')).pack(pady=20)

        # Narzędzia
        btn_opts = {'bg': '#313244', 'fg': 'white', 'relief': 'flat', 'pady': 5}
        tk.Button(sidebar, text='🖌 Pędzel', command=lambda: self.set_tool('pen'), **btn_opts).pack(fill=tk.X, padx=10, pady=2)
        tk.Button(sidebar, text='💨 Spray', command=lambda: self.set_tool('spray'), **btn_opts).pack(fill=tk.X, padx=10, pady=2)
        tk.Button(sidebar, text='⬛ Kwadrat', command=lambda: self.set_tool('rect'), **btn_opts).pack(fill=tk.X, padx=10, pady=2)
        tk.Button(sidebar, text='🧼 Gumka', command=lambda: self.set_tool('eraser'), **btn_opts).pack(fill=tk.X, padx=10, pady=2)

        tk.Button(sidebar, text='🎨 KOLOR', bg=self.color, command=self.change_color).pack(fill=tk.X, padx=10, pady=20)
        
        self.size_scale = tk.Scale(sidebar, from_=1, to=100, orient=tk.HORIZONTAL, bg='#1e1e2e', fg='white', highlightthickness=0)
        self.size_scale.set(5)
        self.size_scale.pack(fill=tk.X, padx=10)

        tk.Button(sidebar, text='↩ Cofnij', bg='#fab387', command=self.undo).pack(fill=tk.X, padx=10, pady=10)
        tk.Button(sidebar, text='💾 Zapisz', bg='#a6e3a1', command=self.save).pack(side=tk.BOTTOM, fill=tk.X, padx=10, pady=5)
        tk.Button(sidebar, text='🗑 Czyść', bg='#f38ba8', command=self.clear).pack(side=tk.BOTTOM, fill=tk.X, padx=10, pady=5)

        self.canvas = tk.Canvas(self.root, bg='white', highlightthickness=0)
        self.canvas.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

        self.canvas.bind('<Button-1>', self.press)
        self.canvas.bind('<B1-Motion>', self.move)
        self.canvas.bind('<ButtonRelease-1>', self.release)

    def set_tool(self, mode): self.tool = mode

    def change_color(self):
        c = colorchooser.askcolor(color=self.color)[1]
        if c: self.color = c

    def press(self, event):
        self.start_x, self.start_y = event.x, event.y
        self.history.append(self.image.copy())
        if len(self.history) > 20: self.history.pop(0)

    def move(self, event):
        size = self.size_scale.get()
        col = 'white' if self.tool == 'eraser' else self.color
        
        if self.tool in ['pen', 'eraser']:
            self.canvas.create_line(self.start_x, self.start_y, event.x, event.y, width=size, fill=col, capstyle=tk.ROUND, smooth=True)
            self.draw.line([self.start_x, self.start_y, event.x, event.y], fill=col, width=size)
            self.start_x, self.start_y = event.x, event.y
        
        elif self.tool == 'spray':
            for _ in range(size):
                sx, sy = event.x + random.randint(-size, size), event.y + random.randint(-size, size)
                self.canvas.create_oval(sx, sy, sx+1, sy+1, outline=col, fill=col)
                self.draw.point([sx, sy], fill=col)
        
        elif self.tool == 'rect':
            if self.temp_rect: self.canvas.delete(self.temp_rect)
            self.temp_rect = self.canvas.create_rectangle(self.start_x, self.start_y, event.x, event.y, outline=col, width=size)

    def release(self, event):
        if self.tool == 'rect' and self.start_x is not None:
            self.draw.rectangle([self.start_x, self.start_y, event.x, event.y], outline=self.color, width=self.size_scale.get())
            self.temp_rect = None
        self.start_x = self.start_y = None

    def undo(self):
        if self.history:
            self.image = self.history.pop()
            self.draw = ImageDraw.Draw(self.image)
            self.refresh()

    def refresh(self):
        self.canvas.delete('all')
        self.tk_img = ImageTk.PhotoImage(self.image)
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self.tk_img)

    def clear(self):
        self.canvas.delete('all')
        self.draw.rectangle([0,0,2000,2000], fill='white')
        self.history.clear()

    def save(self):
        path = filedialog.asksaveasfilename(defaultextension='.png')
        if path: self.image.crop((0,0,self.canvas.winfo_width(), self.canvas.winfo_height())).save(path)

if __name__ == '__main__':
    root = tk.Tk()
    app = PiPaint(root)
    root.mainloop()
EOF"

# 4. Tworzenie aktywatora Desktop
echo "🖥 Tworzenie skrótu na pulpicie..."
DESKTOP_FILE="[Desktop Entry]
Name=PiPaint Pro
Comment=Maluj na Raspberry Pi 5
Exec=python3 $APP_DIR/paint.py
Icon=art-editor
Terminal=false
Type=Application
Categories=Graphics;
"
echo "$DESKTOP_FILE" | sudo tee /usr/share/applications/pipaint.desktop > /dev/null
echo "$DESKTOP_FILE" > ~/Desktop/PiPaint.desktop
chmod +x ~/Desktop/PiPaint.desktop

echo "✅ Gotowe! Uruchom PiPaint z pulpitu."
