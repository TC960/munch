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

ingredients = "eggs, onions, tomatoes, bell peppers, cheese, milk, corn, brocolli, bread"

template = """You are a generative AI model with ubiquitous knowledge all possible 
 recipes using all sorts of combinations of foods. You are also very clear, coherent
 and concise with the way you respond, not giving too much bullshit.
 Generate me a list of all possible recipes using only the ingredients provided. 
 Keep the format grouping recipes on the time of day. 
 Omit all instructions, only give names.
 Add the preparation time to each recipe.
 The ingredients are {ingredients}.
 Keep in mind that the recipes are for a college student, they should be easy to make.
 Format your response as a JSON, using the following template:
 {{
  "Breakfast": [
    {{"recipe": <name of dish>, "prep_time": <prep time in minutes>}},
  ],
  "Lunch": [
    {{"recipe": <name of dish>, "prep_time": <prep time in minutes>}}, 
  ],
  "Dinner": [
    {{"recipe": <name of dish>, "prep_time": <prep time in minutes>}},
  ],
  "Snacks": [
    {{"recipe": <name of dish>, "prep_time": <prep time in minutes>}},
  ]
 }}
"""

chatPrompt = ChatPromptTemplate.from_template(template)
chain = chatPrompt | llm | parser

result = chain.invoke({"ingredients":ingredients})
with open("Output.txt","w") as file:
    file.write(result)