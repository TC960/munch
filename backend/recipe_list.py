import google.generativeai as genai
import os

genai.configure(api_key=os.environ["GEMINI_API_KEY"])

def generate_recipe_list(filepath):
    model = genai.GenerativeModel("gemini-1.5-pro-002")
    file = genai.upload_file(filepath, mime_type="image/jpeg")
    template = '''
    Generate a list of all possible recipes using only the ingredients in the image.
    Group recipes by time of day.
    Omit all instructions, only give names.
    Add the preparation time to each recipe.
    Keep in mind that the recipes are for a college student, they should be easy to make.
    Format your response as a JSON, using the following template:
    {{
    "detected_ingredients": [
    <strings>,
    ],
    "breakfast": [
    {{"recipe": <name of dish>, "prep_time": <prep time in minutes>}},
    ],
    "lunch": [
    {{"recipe": <name of dish>, "prep_time": <prep time in minutes>}},
    ],
    "dinner": [
    {{"recipe": <name of dish>, "prep_time": <prep time in minutes>}},
    ],
    "snacks": [
    {{"recipe": <name of dish>, "prep_time": <prep time in minutes>}},
    ]
    }}
    '''

    result = model.generate_content(
        [file, '\n\n', template]
    )
    return result.text


if __name__ == '__main__':
    result = generate_recipe_list('data/groceries2.jpg')
    with open("Output.txt","w") as file:
        file.write(result)