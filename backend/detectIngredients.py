import os
from dotenv import load_dotenv
import requests
from compressImage import JPEGSaveWithTargetSize
from PIL import Image

load_dotenv()
FOODVISOR_API_KEY = os.getenv("FOODVISOR_API_KEY")

# Load sample image
im = Image.open('data/groceries2.jpg')

# Save at best quality under 2MB
JPEGSaveWithTargetSize(im, "data/result.jpg", 2000000)

response = requests.post(
    url = "https://vision.foodvisor.io/api/1.0/en/analysis/",
    headers = {"Authorization": f"Api-Key {FOODVISOR_API_KEY}"},
    files= {'image': ('result.jpg', open('data/result.jpg', 'rb'), 'multipart/form-data', {'Expires': '0'})}
)

ingredients_list = set()
for i in response.json()['items']:
    for j in i['food']:
        ingredients_list.add(j['food_info']['display_name'])

print(response.status_code, ingredients_list)