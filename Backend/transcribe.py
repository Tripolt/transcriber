import sys
import whisper

def transcribe_audio(audio_path):
    model = whisper.load_model("base")
    result = model.transcribe(audio_path, language='de')
    print(result["text"])

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Bitte geben Sie den Pfad zur Audiodatei an.")
        sys.exit(1)
    audio_path = sys.argv[1]
    transcribe_audio(audio_path)
