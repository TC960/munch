import os
from dotenv import load_dotenv
from google.generativeai.types.content_types import *
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

parser = StrOutputParser()
llm = ChatGoogleGenerativeAI(model="gemini-1.5-pro-002", api_key=GEMINI_API_KEY)

def generate_steps(recipe, ingredients):
    template = """
    Give a 1-2 line description of the dish
    Detail the recipe to bake this item, for a serving size of one person. Include item names and quantities for the recipe.
    The recipe that I need instructions for is {recipe},
    using only the ingredients: {ingredients}.
    Keep in mind that the recipe is for a college student, it should be easy to make.
    Format your response as a JSON, using the following template:
    {{
    "name": <name of dish>,
    "description": <1-2 line summary about the dish>,
    "ingredients": {{
        <ingredient name>: <quantity>,
    }},
    "instructions": [
        <strings>,
    ]
    }}
    """

    chatPrompt = ChatPromptTemplate.from_template(template)
    chain = chatPrompt | llm | parser

    result = chain.invoke({"recipe":recipe, "ingredients":ingredients})
    return result


if __name__ == '__main__':
    recipe = "Enchiladas with black beans and sweet potato"
    ingredients = '["cut and peel carrots","brussels sprouts","sweet potatoes","romaine hearts","shishito peppers","cauliflower","peanut butter filled pretzel nuggets","blueberries","raspberries","dark sweet cherries","jasmine rice","whole wheat tortillas","farro","nonfat greek yogurt","high protein organic tofu","soy sauce","enchilada sauce","black beans","garbanzo beans","apples","bananas"]'
    result = generate_steps(recipe, ingredients)
    with open("Output2.txt","w") as file:
        file.write(result)