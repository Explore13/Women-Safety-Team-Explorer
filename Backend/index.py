import numpy as np
import librosa
import tensorflow as tf
import torch
import soundfile as sf
import sys
import json
import os

# Suppress TensorFlow warnings and logs
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
tf.get_logger().setLevel("ERROR")

# Set UTF-8 encoding for Windows (fixes Unicode issues)
sys.stdout.reconfigure(encoding="utf-8")

# Load pre-trained gender classification model
try:
    model = tf.keras.models.load_model("model/gender_classifier.h5")
except Exception as e:
    print(json.dumps({"error": f"Failed to load model: {str(e)}"}))
    sys.exit(1)

# Load Silero VAD
try:
    vad_model, utils = torch.hub.load("snakers4/silero-vad", "silero_vad", force_reload=True)
    get_speech_timestamps = utils[0]
except Exception as e:
    print(json.dumps({"error": f"Failed to load VAD model: {str(e)}"}))
    sys.exit(1)

def extract_features(audio):
    """Extracts MFCC features from the given audio signal."""
    mfcc = librosa.feature.mfcc(y=audio, sr=16000, n_mfcc=20)
    features = np.mean(mfcc.T, axis=0)
    return features

def detect_speakers(audio_path):
    """Detects speech segments and extracts unique voices."""
    try:
        audio, sr = librosa.load(audio_path, sr=16000)
        sf.write("temp.wav", audio, sr)
    except Exception as e:
        print(json.dumps({"error": f"Failed to load audio: {str(e)}"}))
        sys.exit(1)

    audio_tensor = torch.tensor(audio, dtype=torch.float32)
    
    try:
        speech_segments = get_speech_timestamps(audio_tensor, vad_model, sampling_rate=16000)
    except Exception as e:
        print(json.dumps({"error": f"VAD processing error: {str(e)}"}))
        sys.exit(1)

    unique_speakers = []
    for segment in speech_segments:
        start, end = int(segment["start"]), int(segment["end"])
        speaker_audio = audio[start:end]
        unique_speakers.append(speaker_audio)

    return unique_speakers

def classify_genders(speakers):
    """Classifies gender for each unique voice and counts them."""
    male_count, female_count = 0, 0
    speaker_results = []

    for idx, speaker in enumerate(speakers):
        features = extract_features(speaker)
        features = np.expand_dims(features, axis=0)
        
        try:
            prediction = model.predict(features, verbose=0)
            threshold = float(prediction[0][0])
            gender = "Male" if threshold < 0.8 else "Female"
        except Exception as e:
            print(json.dumps({"error": f"Classification error: {str(e)}"}))
            sys.exit(1)

        speaker_results.append({"speaker": idx + 1, "threshold": threshold, "gender": gender})

        if gender == "Male":
            male_count += 1
        else:
            female_count += 1

    return male_count, female_count

def classify_audio(audio_path):
    """Main function to process audio and return JSON results."""
    speakers = detect_speakers(audio_path)
    male_count, female_count = classify_genders(speakers)

    # Delete temporary file after processing
    try:
        os.remove("temp.wav")
    except Exception as e:
        print(json.dumps({"error": f"Failed to delete temp.wav: {str(e)}"}))

    # Return JSON output
    result = {
        "male_count": male_count,
        "female_count": female_count
    }
    
    print(json.dumps(result))  # Ensure ONLY JSON is printed

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No audio file provided"}))
        sys.exit(1)

    audio_file = sys.argv[1]
    classify_audio(audio_file)
