import google.generativeai as genai
import sys
import json

def main():
    # Replace with your Gemini API key
    api_key = "AIzaSyDtxljF3n95aH8VdY5TXOAiwgHShzjBTOo"
    genai.configure(api_key=api_key)

    # Get the prompt from command-line arguments
    prompt = sys.argv[1]

    # Create the model
    model = genai.GenerativeModel("gemini-1.5-flash")

    # Generate content
    response = model.generate_content(prompt)

    # Print the response in JSON format
    print(json.dumps({"text": response.text}, ensure_ascii=False))

if __name__ == "__main__":
    main()
