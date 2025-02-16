import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { storage } from "./config/firebaseConfig.js";
import fs from "fs";

export const uploadAudioToFirebase = async (localFilePath) => {
  const fileName = `audio/${Date.now()}.wav`; // Firebase path
  const storageRef = ref(storage, fileName);

  try {
    const fileBuffer = fs.readFileSync(localFilePath);
    await uploadBytes(storageRef, fileBuffer);
    const downloadURL = await getDownloadURL(storageRef);

    console.log("✅ File uploaded successfully:", downloadURL);
    return downloadURL;
  } catch (error) {
    console.error("❌ Firebase Upload Error:", error);
    throw new Error("Failed to upload audio");
  }
};
