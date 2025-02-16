import axios from "axios";

export async function sendSMS(message, numbersArray, YOUR_FAST2SMS_API_KEY) {
  try {
    console.log(numbersArray);

    const response = await axios.post(
      "https://www.fast2sms.com/dev/bulkV2",
      new URLSearchParams({
        route: "q",
        message: message,
        flash: "0",
        numbers: numbersArray,
      }),
      {
        headers: {
          authorization: YOUR_FAST2SMS_API_KEY,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );

    console.log("✅ SMS Sent:", response.data);
  } catch (error) {
    console.error(
      "❌ SMS Sending Failed:",
      error.response?.data || error.message
    );
  }
}
