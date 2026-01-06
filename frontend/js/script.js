const div = document.getElementById('files');
const table = $('<table></table>');
table.append('<tr><th>File Name</th><th>Size</th><th>Date</th><th>Actions</th></tr>');
div.appendChild(table[0]);

function formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    const k = 1024;
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + units[i];
}

async function getFiles(){
    const response = await fetch('/api/files');
    const data = await response.json();
    data.files.forEach(f => {
        table.append(`<tr>
            <td>${f.name}</td>
            <td>${formatFileSize(f.size)}</td>
            <td>${f.time}</td>
            <td>
                <div id="actions">
                    <button onclick="downloadFile('${encodeURIComponent(f.name)}')">Download</button>
                    <button onclick="deleteFile('${encodeURIComponent(f.name)}')">Delete</button>  
                </div>

            </td>
        </tr>`);
    });
}


async function deleteFile(fname){
    const response = await fetch(`/api/delete/${encodeURIComponent(fname)}`, { method: 'DELETE' });
    if (response.ok) {
        location.reload();
    }
};

async function downloadFile(fname) {
    location.href = `/api/download?file=${encodeURIComponent(fname)}`;
}

const dropZone = document.querySelector('body');

// Prevent default drag behaviors on the document
['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    dropZone.addEventListener(eventName, preventDefaults, false);
});

function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
}

// Add visual feedback when dragging over
['dragenter', 'dragover'].forEach(eventName => {
    dropZone.addEventListener(eventName, () => {
        dropZone.classList.add('drag-over');
    }, false);
});

['dragleave', 'drop'].forEach(eventName => {
    dropZone.addEventListener(eventName, () => {
        dropZone.classList.remove('drag-over');
    }, false);
});

// Handle dropped files
dropZone.addEventListener('drop', handleFileDrop, false);

async function handleFileDrop(e) {
    const files = e.dataTransfer.files;
    
    if (files.length === 0) return;
    
    // Upload each file
    for (const file of files) {
        await uploadFile(file);
    }
    
    // Refresh the file list after upload
    location.reload();
}

async function uploadFile(file) {
    const formData = new FormData();
    formData.append('file', file);
    
    try {
        const response = await fetch('/api/upload', {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            throw new Error(`Upload failed: ${response.statusText}`);
        }
        
        console.log(`Successfully uploaded: ${file.name}`);
        return await response.json();
    } catch (error) {
        console.error(`Error uploading ${file.name}:`, error);
        alert(`Failed to upload ${file.name}`);
    }
}
