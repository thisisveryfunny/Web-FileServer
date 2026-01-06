const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const app = express();

const dir = '/srv/files';

const storage = multer.diskStorage({
  destination: dir,
  filename: (req, file, cb) => {
    cb(null, file.originalname.trim());
  }
});

const upload = multer({ storage });

app.post('/upload', upload.single('file'), (req, res) => {
  console.log(req.file.filename)
  res.json({ success: true, filename: req.file.filename.trim() });
});

app.get('/get-files', async (req, res) => {
    const files = await fs.promises.readdir(dir, {withFileTypes: true});
    const filesList = [];
    for (const file of files) {
        const fullPath = path.join(dir, file.name);
        const stats = await fs.promises.stat(fullPath);
        const time = stats.mtime.toDateString();
        filesList.push({
            name: file.name,
            size: stats.size,
            time: time
        });
    }
    return res.json({ files: filesList });
});

app.get('/download', (req, res) => {
  const filename = decodeURIComponent(req.query.file);
  const filepath = path.join(dir, filename);
  if (!fs.existsSync(filepath)) {
    return res.status(404).json({ error: 'File not found' });
  }
  res.download(filepath);
});

app.delete('/delete/:file', (req, res) => {
  const filename = decodeURIComponent(req.params.file);
  console.log(filename);
  const filepath = path.join(dir, filename);
  if (!fs.existsSync(filepath)) {
    return res.status(404).json({ error: 'File not found' });
  }
  fs.unlinkSync(filepath);
  res.json({ success: true, message: 'File deleted successfully' });
});

app.listen(3000, () => console.log('Server running on :3000'));
