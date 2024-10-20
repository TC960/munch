import pymysql
import os
from dotenv import load_dotenv
from datetime import datetime
import json

# Load environment variables
load_dotenv()

# Database connection details
connection = pymysql.connect(
    host=os.getenv("MUNCHDB_SERVER"),
    user='admin',
    password=os.getenv("MUNCHDB_PASS"),
    database='munchdbdb',
    port=3306,
    ssl={'ca': 'singlestore_bundle.pem'},
)

# Function to add or update a recipe
def add_or_update_recipe(person_id, person_name, recipe_id, recipe_desc):
    try:
        with connection.cursor() as cursor:
            # Convert recipe_desc from string to dictionary
            recipe_dict = json.loads(recipe_desc)
            # Convert dictionary back to JSON string for storage
            recipe_json_str = json.dumps(recipe_dict)

            # Check if the recipe already exists based on recipe_id
            check_sql = "SELECT recipe_id FROM recipes WHERE recipe_id = %s AND person_id = %s"
            cursor.execute(check_sql, (recipe_id, person_id))
            result = cursor.fetchone()

            current_time = datetime.now()

            if result:
                # Update the recipe while preserving existing information
                update_sql = """
                    UPDATE recipes
                    SET person_name = %s, recipe_desc = %s, last_used = %s
                    WHERE recipe_id = %s AND person_id = %s
                """
                cursor.execute(update_sql, (person_name, recipe_json_str, current_time, recipe_id, person_id))
                print(f"Updated existing recipe for user: {person_name} with recipe ID: {recipe_id}")
            else:
                # Insert new recipe if it doesn't exist
                insert_sql = """
                    INSERT INTO recipes (person_id, recipe_id, person_name, recipe_desc, last_used)
                    VALUES (%s, %s, %s, %s, %s)
                """
                cursor.execute(insert_sql, (person_id, recipe_id, person_name, recipe_json_str, current_time))
                print(f"Inserted new recipe for user: {person_name} with recipe ID: {recipe_id}")

        connection.commit()  # Save the changes to the database
        print("Transaction committed successfully!")

    except Exception as e:
        print(f"Error: {e}")

# Example Usage
recipe_description = """{
  "name": "Quick Scrambled Eggs with Tomatoes and Onions",
  "description": "A simple and satisfying breakfast or light meal featuring scrambled eggs with sautéed tomatoes and onions, topped with cheese.",
  "ingredients": {
    "Eggs": 2,
    "Tomatoes": 0.5,
    "Cheese": "1/4 cup (shredded)",
    "Onions": 0.25,
    "Bread": "1 slice",
    "Jalapenos": "Optional, to taste (1/2 - 1 sliced)"
  },
  "instructions": [
    "Dice the onion and tomato. If using jalapenos, thinly slice them.",
    "Heat a small pan with a little oil or butter over medium heat.",
    "Add the onions to the pan and sauté for 2-3 minutes until softened.",
    "Add the tomatoes (and jalapenos if using) and cook for another 2-3 minutes.",
    "In a bowl, whisk the eggs with a fork. Season with salt and pepper.",
    "Pour the egg mixture into the pan with the vegetables. Stir gently as the eggs cook.",
    "Once the eggs are mostly set but still slightly moist, sprinkle the cheese on top.",
    "Remove from heat and let the cheese melt slightly from the residual heat.",
    "Toast the bread (optional).",
    "Serve the scrambled eggs with the toast. Enjoy!"
  ]
}

"""

# Add or update the recipe
add_or_update_recipe(1, 'Mohak', 101, recipe_description)  # Example recipe_id

# Close the database connection when done
connection.close()
