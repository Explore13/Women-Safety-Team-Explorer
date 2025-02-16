// const express = require("express");
// const { spawn } = require("child_process");
// const path = require("path");
// const fs = require("fs");

// const app = express();
// app.use(express.json());
// app.use("/uploads", express.static("uploads"));

// app.post("/predict", (req, res) => {
//   const { filename } = req.body;

//   console.log("📩 Received request for:", filename);

//   if (!filename) {
//     console.error("❌ No filename provided in request.");
//     return res.status(400).json({ error: "No audio filename provided" });
//   }

//   const filePath = path.join(__dirname, "uploads", filename);
//   console.log("📂 Checking file:", filePath);

//   if (!fs.existsSync(filePath)) {
//     console.error("❌ File not found:", filePath);
//     return res.status(404).json({ error: "Audio file not found" });
//   }

//   console.log("🚀 Running Python script...");
//   const pythonProcess = spawn("python", ["index.py", filePath]);

//   let result = "";

//   pythonProcess.stdout.on("data", (data) => {
//     console.log("📨 Python Output:", data.toString());
//     result += data.toString();
//   });

//   pythonProcess.stderr.on("data", (data) => {
//     console.error("❌ Python Error:", data.toString());
//   });

//   pythonProcess.on("close", (code) => {
//     console.log("🔄 Python script exited with code:", code);

//     if (code === 0) {
//       try {
//         const parsedResult = JSON.parse(result);
//         console.log("✅ Sending response:", parsedResult);
//         res.json(parsedResult); // Send parsed JSON response
//       } catch (error) {
//         console.error("❌ Error parsing JSON:", error.message);
//         console.error("🔍 Raw result:", result);
//         res.status(500).json({
//           error: "Error parsing result from Python script",
//           message: error.message,
//         });
//       }
//     } else {
//       console.error("❌ Python script execution failed.");
//       res.status(500).json({ error: "Python script failed" });
//     }
//   });
// });

// const PORT = 5000;
// app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));

import dotenv from "dotenv";
import express from "express";
import multer from "multer";
import { spawn } from "child_process";
import path from "path";
import fs from "fs";
import ffmpeg from "fluent-ffmpeg";
import { sendSMS } from "./sendSms.js";
import { uploadAudioToFirebase } from "./uploadAudio.js";

dotenv.config();

export { express, multer, spawn, path, fs, ffmpeg, sendSMS };

const app = express();
app.use(express.json());
app.use("/uploads", express.static("uploads"));

const FAST2SMS_API_KEY = process.env.YOUR_FAST2SMS_API_KEY;

const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (req, file, cb) => {
    const timestamp = Date.now();
    cb(null, `${timestamp}.m4a`);
  },
});

const upload = multer({ storage });

app.post("/predict", upload.single("file"), async (req, res) => {
  let { trustedContacts } = req.body;

  if (
    !trustedContacts ||
    (typeof trustedContacts !== "string" && !Array.isArray(trustedContacts))
  ) {
    console.error("❌ Trusted contacts missing or invalid format.");
    return res.status(400).json({
      error: "Trusted contacts are required and must be a string or an array",
    });
  }

  const m4aFilePath = req.file.path;
  const wavFilePath = m4aFilePath.replace(".m4a", ".wav");

  console.log(`📥 Uploaded file: ${m4aFilePath}`);
  console.log(`🔄 Converting to: ${wavFilePath}`);

  ffmpeg(m4aFilePath)
    .toFormat("wav")
    .on("end", async () => {
      console.log("✅ Conversion complete. Running Python script...");

      fs.unlink(m4aFilePath, (err) => {
        if (err) console.error("⚠️ Error deleting .m4a file:", err);
        else console.log(`🗑️  Deleted: ${m4aFilePath}`);
      });

      let firebaseUrl;
      try {
        console.log("📥 Uploading file:", wavFilePath);
        firebaseUrl = await uploadAudioToFirebase(wavFilePath);
        console.log("🔥 Firebase URL:", firebaseUrl);
      } catch (error) {
        console.error("❌ Firebase Upload Error:", error);
        return res
          .status(500)
          .json({ error: "Failed to upload audio to Firebase" });
      }

      const pythonProcess = spawn("python", ["index.py", wavFilePath]);
      let result = "";

      pythonProcess.stdout.on("data", (data) => {
        console.log("📨 Python Output:", data.toString());
        result += data.toString();
      });

      pythonProcess.stderr.on("data", (data) => {
        console.error("❌ Python Error:", data.toString());
      });

      pythonProcess.on("close", (code) => {
        console.log("🔄 Python script exited with code:", code);

        fs.unlink(wavFilePath, (err) => {
          if (err) console.error("⚠️ Error deleting .wav file:", err);
          else console.log(`🗑️  Deleted: ${wavFilePath}`);
        });

        if (code === 0) {
          try {
            const parsedResult = JSON.parse(result);
            const message = `*Gender Classification Results*

Males: ${parsedResult.male}  
Females: ${parsedResult.female}  

📂 *Download Processed Audio:* [Click Here](${firebaseUrl})  

🛡️ Stay Safe! 🚀`;

            const finalResult = {
              ...parsedResult,
              trustedContacts,
              message,
              firebaseUrl,
            };

            // sendSMS(message, trustedContacts, FAST2SMS_API_KEY);
            console.log("✅ Sending response:", finalResult);

            res.json(finalResult);
          } catch (error) {
            console.error("❌ Error parsing JSON:", error.message);
            res.status(500).json({
              error: "Error parsing result from Python script",
              message: error.message,
            });
          }
        } else {
          console.error("❌ Python script execution failed.");
          res.status(500).json({ error: "Python script failed" });
        }
      });
    })
    .on("error", (err) => {
      console.error("❌ Conversion error:", err);
      res.status(500).json({ error: "Failed to convert audio file" });
    })
    .save(wavFilePath);
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () =>
  console.log(`🚀 Server running on http://localhost:${PORT}`)
);
