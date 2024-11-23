const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const OpenAI = require('openai');
const Queue = require('bull');
const transcriptionQueue = new Queue('transcription');

dotenv.config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const app = express();
app.use(cors());

// Pfad zum 'uploads'-Verzeichnis
const uploadDir = path.join(__dirname, 'uploads');

// Verzeichnis erstellen, falls nicht vorhanden
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// Multer-Konfiguration
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});
const upload = multer({ storage: storage });

// Upload-Endpunkt
app.post('/upload', upload.single('audio'), (req, res) => {
  if (!req.file) {
    console.error('Keine Datei empfangen');
    return res.status(400).send('Keine Datei hochgeladen.');
  } else {
    console.log('Datei empfangen:', req.file);
  }

  const filePath = path.join(uploadDir, req.file.filename);

  // Überprüfen, ob die Datei existiert
  if (!fs.existsSync(filePath)) {
    console.error('Datei nicht gefunden:', filePath);
    return res.status(500).send('Datei nicht gefunden.');
  }

  // Python-Skript aufrufen
  const pythonProcess = spawn('python3', ['transcribe.py', filePath]);

  let transcript = '';

  pythonProcess.stdout.on('data', (data) => {
    transcript += data.toString();
  });

  pythonProcess.stderr.on('data', (data) => {
    console.error(`Fehler im Python-Skript: ${data}`);
  });

  pythonProcess.on('close', async (code) => {
    if (code !== 0) {
      return res.status(500).send('Fehler bei der Transkription.');
    }

    // Datei löschen
    fs.unlink(filePath, (err) => {
      if (err) {
        console.error('Fehler beim Löschen der Audiodatei:', err);
      }
    });

    // Zusammenfassung abrufen
    try {
      const summary = await getSummaryFromChatGPT(transcript);
      res.send(summary);
    } catch (error) {
      console.error('Fehler beim Abrufen der Zusammenfassung:', error);
      res.status(500).send('Fehler beim Abrufen der Zusammenfassung.');
    }
  });
});

// Funktion zum Abrufen der Zusammenfassung
async function getSummaryFromChatGPT(transcript) {
  if (!process.env.OPENAI_API_KEY) {
    throw new Error('OPENAI_API_KEY ist nicht gesetzt.');
  }

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      { role: 'system', content: 'Fasse den folgenden Text auf Deutsch zusammen.' },
      { role: 'user', content: transcript },
    ],
  });

  return completion.choices[0].message.content;
}
app.post('/upload', upload.single('audio'), async (req, res) => {
  if (!req.file) {
    console.error('No file received');
    return res.status(400).send('No file uploaded.');
  }

  const job = await transcriptionQueue.add({
    filePath: req.file.path,
  });

  // Respond immediately with the job ID
  res.json({ jobId: job.id });
});

// Server starten
const PORT = process.env.PORT || 8200;
app.listen(PORT, () => {
  console.log(`Server läuft auf Port ${PORT}`);
});