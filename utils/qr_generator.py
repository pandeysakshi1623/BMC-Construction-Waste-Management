import qrcode
import base64
from io import BytesIO
import os

def generate_qr_file(data: str, filename: str) -> str:
    """
    Generates a QR code for the given string data, saves it as a PNG file, 
    and returns its public static URL.
    """
    os.makedirs("uploads", exist_ok=True)
    
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    
    filepath = os.path.join("uploads", filename)
    img.save(filepath, format="PNG")
    
    return f"/static/{filename}"
