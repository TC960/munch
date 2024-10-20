from flask import Flask, request
from recipe_list import generate_recipe_list
from step_gen import generate_steps

app = Flask(__name__)

@app.route('/get_recipe_list', methods=['POST'])
def get_recipe_list():
    data = request.files
    file = data.get('image')
    result = generate_recipe_list(file)
    return result

@app.route('/get_instructions', methods=['POST'])
def get_instructions():
    data = request.get_json()
    recipe = data.get('recipe')
    ingredients = data.get('ingredients')
    result = generate_steps(recipe, ingredients)
    return result


if __name__ == "__main__":
    app.run()
