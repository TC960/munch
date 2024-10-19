import os 
from dotenv import load_dotenv
import asyncio
from lmnt.api import Speech
import json

load_dotenv()
LMNT_API_KEY = os.getenv("LMNT_API_KEY")

with open("Output2.txt","r") as file:
    result = json.load(file)

TEXT_TO_SPEECH = result['instructions']

VOICE_ID = 'lily'

async def main():
    async with Speech() as speech:
        connection = await speech.synthesize_streaming(VOICE_ID)
        t1 = asyncio.create_task(reader_task(connection))
        t2 = asyncio.create_task(writer_task(connection))
        await asyncio.gather(t1, t2)

async def reader_task(connection):
    """Streams audio data from LMNT and writes it to `output.mp3`."""
    with open('output.mp3', 'wb') as f:
        async for message in connection:
            f.write(message['audio'])

async def writer_task(connection):
    """Sends each string individually from a list to LMNT for speech synthesis, with a delay."""
    for instruction in TEXT_TO_SPEECH:

        # Append each string (text) to the connection one by one
        await connection.append_text(instruction)
        print(f"Speaking: {instruction}")  # Optionally print each string being processed
        
        # Simulate waiting for your "next" command by pausing for 5 seconds
        print("Waiting for 'next' command...")
        await asyncio.sleep(5)  # Simulating wait time

    # After all the strings are sent, finish the connection
    await connection.finish()


asyncio.run(main())