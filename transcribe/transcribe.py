import whisperx
import threading
import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm
from whisperx.diarize import DiarizationPipeline

script_dir = os.path.dirname(os.path.abspath(__file__))

secrets_path = os.path.join(os.path.expanduser("~"), ".secrets")
if not os.path.exists(secrets_path):
    print(f"Missing .secrets file at {secrets_path}")
    sys.exit(1)
secrets = dict(line.strip().split("=", 1) for line in open(secrets_path) if "=" in line)
HF_TOKEN = secrets.get("HF_TOKEN")
if not HF_TOKEN:
    print("HF_TOKEN not found in .secrets")
    sys.exit(1)

device = "cpu"
cache_dir = script_dir
input_dir = os.path.join(script_dir, "to-transcribe")
output_dir = os.path.join(script_dir, "transcriptions")

AUDIO_EXTENSIONS = {".aac", ".mp3", ".wav", ".m4a", ".flac", ".ogg", ".mp4"}

if len(sys.argv) >= 2:
    audio_files = sys.argv[1:]
else:
    audio_files = [
        os.path.join(input_dir, f) for f in os.listdir(input_dir)
        if os.path.splitext(f)[1].lower() in AUDIO_EXTENSIONS
    ]
    if not audio_files:
        print(f"No audio files found in {input_dir}")
        sys.exit(1)
    print(f"Found {len(audio_files)} file(s) in to-transcribe/")

def run_with_spinner(label, fn, *args, **kwargs):
    result_box = [None]
    done = threading.Event()
    def run():
        result_box[0] = fn(*args, **kwargs)
        done.set()
    threading.Thread(target=run).start()
    with tqdm(bar_format="{desc} {elapsed} {bar}", desc=label, total=0) as pbar:
        while not done.wait(timeout=1):
            pbar.refresh()
    return result_box[0]

print("Loading models...")
whisper_model = whisperx.load_model("medium", device=device, compute_type="int8")
align_model, align_metadata = whisperx.load_align_model(language_code="en", device=device)
diarize_model = DiarizationPipeline(model_name="pyannote/speaker-diarization-3.1", token=HF_TOKEN, device=device)
model_lock = threading.Lock()

def process_file(audio_file):
    name = os.path.basename(audio_file)
    basename = os.path.splitext(name)[0]
    transcribe_cache = os.path.join(cache_dir, f"cache_{basename}_transcribe.json")
    align_cache = os.path.join(cache_dir, f"cache_{basename}_align.json")

    audio = whisperx.load_audio(audio_file)

    if os.path.exists(transcribe_cache):
        print(f"[{name}] Skipping transcription (cached)")
        with open(transcribe_cache) as f:
            result = json.load(f)
    else:
        with model_lock:
            result = run_with_spinner(f"[{name}] Transcribing", whisper_model.transcribe, audio, language="en")
        with open(transcribe_cache, "w") as f:
            json.dump(result, f)

    if os.path.exists(align_cache):
        print(f"[{name}] Skipping alignment (cached)")
        with open(align_cache) as f:
            result = json.load(f)
    else:
        with model_lock:
            result = run_with_spinner(f"[{name}] Aligning", whisperx.align, result["segments"], align_model, align_metadata, audio, device=device)
        with open(align_cache, "w") as f:
            json.dump(result, f)

    with model_lock:
        diarize_segments = run_with_spinner(f"[{name}] Detecting speakers", diarize_model, audio, min_speakers=2, max_speakers=2)
    result = whisperx.assign_word_speakers(diarize_segments, result)

    output_file = os.path.join(output_dir, basename + ".txt")
    with open(output_file, "w") as f:
        current_speaker = None
        for seg in result["segments"]:
            speaker = seg.get("speaker", "UNKNOWN")
            text = seg["text"].strip()
            start = seg["start"]
            minutes, seconds = int(start // 60), int(start % 60)
            if speaker != current_speaker:
                f.write(f"\n[{minutes:02d}:{seconds:02d}] {speaker}:\n")
                current_speaker = speaker
            f.write(f"{text} ")

    return audio_file, output_file

with ThreadPoolExecutor(max_workers=len(audio_files)) as executor:
    futures = {executor.submit(process_file, f): f for f in audio_files}
    for future in as_completed(futures):
        audio_file, output_file = future.result()
        print(f"\nDone: {os.path.basename(audio_file)} → {output_file}")
