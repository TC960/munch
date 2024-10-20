from flask import Flask, request, jsonify
from recipe_list import generate_recipe_list
from step_gen import generate_steps

app = Flask(__name__)

final_steps = ""

@app.route('/get_recipe_list', methods=['POST'])
def get_recipe_list():
    data = request.files
    file = data.get('image')
    result = generate_recipe_list(file.stream)
    return result.strip(" \n`json")

@app.route('/get_instructions', methods=['POST'])
def get_instructions():
    data = request.get_json()
    recipe = data.get('recipe')
    ingredients = data.get('ingredients')
    result = generate_steps(recipe, ingredients)
    final_steps = result.strip(" \n`json")
    return result.strip(" \n`json")


if __name__ == "__main__":
    app.run(host='localhost', port=8000)
