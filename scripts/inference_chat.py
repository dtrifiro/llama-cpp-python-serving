import json
import sys
import os

system_prompt = "You are an helpful assistant. Your aim is to help the user by answering questions truthfully. If you do not know the answer to a question, state so. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If it makes sense, try to reply reasoning step by step."


def bold(text: str) -> str:
    return f"\033[1;37m{text}\033[0m"


def cyan(text: str) -> str:
    return f"\033[1;36m{text}\033[0m"


def green(text: str) -> str:
    return f"\033[1;32m{text}\033[0m"


try:
    import requests
except ImportError:
    print("Please `pip install requests`", file=sys.stderr)
    sys.exit(1)


isvc_url = os.getenv("ISVC_URL")

if not isvc_url:
    print(
        "Please set isvc url: `ISVC_URL=$(kubectl get isvc llama-cpp-python -o jsonpath='{.status.components.predictor.url}')`"
    )
    sys.exit(1)


def usage():
    print(f"Usage: {sys.argv[0]} [prompt]")


def do_request(text: str, history: list[tuple[str, str | None]]) -> str:
    system = f"{history[0][0]}\n\n"

    template = "### Instructions:\n{instructions}\n\n### Response:\n{response}"
    conversation = [system]
    for message, answer in (
        *history[1:],
        (text, None),
    ):
        conversation.append(
            template.format(instructions=message, response=answer or "")
        )
    prompt = "\n".join(conversation)

    payload = {
        "prompt": prompt,
        "stop": ["###"],
        "max_tokens": 512,
    }
    response = requests.post(f"{isvc_url}/v1/completions", json=payload)
    response.raise_for_status()

    if os.getenv("DEBUG"):
        print(
            json.dumps(
                response.json(),
                indent=2,
            )
        )
    text = response.json()["choices"][0]["text"]
    return text


def main():
    print(bold("-> Querying isvc at:"), isvc_url)
    print(bold("-> system prompt is:"), system_prompt)
    print()

    print(bold("-> Interactive chat begins:"))

    history = [
        (system_prompt, None),
    ]

    got_initial_message = bool(sys.argv[1:])

    fmt_size = len("assistant")
    user_prompt = green("User".ljust(fmt_size) + " > ")
    assistant_prompt = cyan("Assistant".ljust(fmt_size) + " > ")

    while True:
        try:
            if got_initial_message:
                text = " ".join(sys.argv[1:])
                print(f"{user_prompt}{text}")
                got_initial_message = False
            else:
                text = input(user_prompt)
            answer = do_request(text, history)
            history.append((text, answer))
            print(f"{assistant_prompt}{answer}")
        except (KeyboardInterrupt, EOFError):
            print("\nDumping conversation to history.json")
            with open("history.json", "w") as fh:
                json.dump(history, fh)
            break

    print("-> Bye!")


if __name__ == "__main__":
    main()
