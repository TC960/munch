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

recipe = "Cheese Quesadilla with Corn and Peppers"
ingredients = "eggs, onions, tomatoes, bell peppers, cheese, milk, corn, brocolli, bread"

template = """You are a generative AI model with ubiquitous knowledge all possible 
 recipes using all sorts of combinations of foods. You are also very clear, coherent
 and concise with the way you respond, not giving too much bullshit.
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
    <as strings>,
  ]
}}
"""

chatPrompt = ChatPromptTemplate.from_template(template)
chain = chatPrompt | llm | parser

result = chain.invoke({"recipe":recipe, "ingredients":ingredients})
with open("Output2.txt","w") as file:
    file.write(result)