import sys

import numpy as np
from PIL import Image, ImageOps

if __name__ == "__main__":
    print("Processing image...")
    print(f"Received inputs: {sys.argv}")
    assert len(sys.argv) == 2, "Image path must be passed!"
    path = sys.argv[1]

    # load image, discard alpha (if present)
    img = Image.open(path).convert("RGB")

    # remove menu and indicators
    data = np.array(img)
    menu_is_open = img.getpixel((38, 1839)) == (0, 0, 0)
    print(f"The menu is {'is' if menu_is_open else 'is not'} open")
    if menu_is_open:
        # remove the entire menu, and the x in the top right corner
        data[:, :120, :] = 255
        data[40:81, 1324:1364, :] = 255
    else:
        # remove only the menu indicator circle
        data[40:81, 40:81, :] = 255

    # Remove the compass from the top left
    data[30:79, 25:79] = [255, 255, 255]

    # Remove page range
    print("Removing page range")
    data[590:806, 1820:1851] = [255, 255, 255]

    # crop to the bounding box
    img = Image.fromarray(data).convert("RGB")
    bbox = ImageOps.invert(img).getbbox()
    img = img.crop(bbox)

    # set alpha channel
    data = np.array(img.convert("RGBA"))
    # copy inverted red channel to alpha channel, so that the background is transparent
    # (could have also used blue or green here, doesn't matter)
    data[..., -1] = 255 - data[..., 0]
    img = Image.fromarray(data)

    border_size = 4
    border_color = (0, 0, 0)  # Black color

    # Add border to the image
    img = ImageOps.expand(img, border=border_size, fill=border_color)

    img.save(path)
    print("Saved modified image.")
