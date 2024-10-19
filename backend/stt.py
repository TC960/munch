import os
from dotenv import load_dotenv
import json
from deepgram import (
    DeepgramClient,
    PrerecordedOptions,
    FileSource,
)
from google.generativeai.types.content_types import *
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser


load_dotenv()

# Path to the audio file (placeholder, will wait on user input)
AUDIO_FILE = "Output.mp3"

DEEPGRAM_API_KEY = os.getenv("DEEPGRAM_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
parser = StrOutputParser()
llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash-002", api_key=GEMINI_API_KEY)
template =  """You are a fast and accurate text analysis model. Your job is to analyse
a short sentence. The sentence will be spoken in coherent english. The output must be 
chosen from 1 of 5 possible keywords: 
1)START 
2) RESTART
3) NEXT
4) BACK 
5) REPLAY
USE THIS AS AN ABSOLUTE LAST RESORT, but if you dare feel ambiguity, then you
can merely return the keyword "UNINTELLIGIBLE" if you feel you dont understand 
what is being said or how to comprehend it. The response you have to analyse is {response}
THE OUTPUT MUST BE ONE OF THE ABOVE MENTIONED KEYWORDS."""

def callUserInput():
    try:
        # STEP 1 Create a Deepgram client using the API key
        deepgram = DeepgramClient(DEEPGRAM_API_KEY)

        with open(AUDIO_FILE, "rb") as file:
            buffer_data = file.read()

        payload: FileSource = {
            "buffer": buffer_data,
        }

        #STEP 2: Configure Deepgram options for audio analysis
        options = PrerecordedOptions(
            model="nova-2",
            smart_format=True,
        )

        # STEP 3: Call the transcribe_file method with the text payload and options
        response = deepgram.listen.rest.v("1").transcribe_file(payload, options)

        chatPrompt = ChatPromptTemplate.from_template(template)
        chain = chatPrompt | llm | parser

        result = chain.invoke({"response":response})
        # STEP 4: Save the response for later use
        with open("response.json","w") as file:
            data = result.to_json(indent=4)
            json.dump(data, file, indent = 4)
        #response.json now has one of the 6 keywords
    except Exception as e:
        print(f"Exception: {e}")


if __name__ == "__main__":
    callUserInput()
