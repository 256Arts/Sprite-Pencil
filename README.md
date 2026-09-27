# Sprite Pencil

<img src="https://www.256arts.com/spritepencil/icon_spencil.png" alt="Sprite Pencil icon" width="128" align="right">

A pixel-art editor for drawing sprites, icons, and other small images.

[Download on the App Store](https://apps.apple.com/app/sprite-pencil/id1437835952) · [256arts.com/spritepencil](https://www.256arts.com/spritepencil/)

<img src="https://www.256arts.com/spritepencil/shot1.webp" alt="The pixel canvas open for editing, with the tool bar and a palette inspector" width="300"> <img src="https://www.256arts.com/spritepencil/shot2.webp" alt="Choosing a color palette, including Lospec and Building Bricks palettes" width="300">

## Features

- **Pencil, eraser, and fill tools** — plus highlight and shadow tools for shading pixel art.
- **Symmetry and dithering** — mirror strokes while drawing, and lay down checkered dither patterns.
- **Color palettes** — handpicked palettes, seasonal picks, Building Bricks colors, or import any palette from Lospec.
- **Flip, rotate, and outline** — quick whole-sprite transforms alongside full undo/redo history.
- **Files-based documents** — sprites are plain PNG files, browsable and shareable through the system document browser and iCloud Drive.
- **Home Screen widget** — pin a saved sprite to your Home Screen.
- **iMessage stickers** — draw and send sprites right inside Messages.
- iPhone, iPad, Mac, and Apple Vision Pro.

## Building

Open `Sprite Pencil.xcodeproj` in Xcode and run the **Sprite Pencil** scheme (or **Sprite Pencil Messages** for the iMessage extension). The drawing engine ships as the external Swift package `SpritePencilKit`, resolved automatically by Xcode. See [`AGENTS.md`](AGENTS.md) for architecture.
