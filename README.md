# Web-FileServer

This is a simple Web File Server for my home.
This application is installed on my home server.
Frontend: HTML, CSS, Javascript and JQuery
Backend: Node.js

# How it works
This is pretty simple. THe application is run on a linux system and host a HTML page using nginx to view and interact with file located on `/srv/files` on my server. The `/srv/files` directory is where I mounted a drive to stored all the files. 

# What it do
On the HTML page, you can upload (drag-n-drop), delete and download a file.
The Node.js Backend do the work for that.

# How to install
**Make sure to run using root**
```
git clone https://github.com/thisisveryfunny/Web-FileServer.git
cd Web-FileServer
chmod +x install.sh
sudo ./install.sh
```

# Quick information about this project
I made this on my own using what i learned at school during this semester. I could have used other Javascript Framework such as Svelte and SvelteKit or even ReactJS but i prefer to make simplier (i guess lol). I tried to limit the use of AI (instead for the installer because I was lazy lol).

Hope you use it for your home!

# To-Do
- Improve css
- Fix bugs
- Add preview of the content of the file
- Add logging for the backend.
- Add loading information when uploadng a file, Like : Uploading <filename>. Please Wait.
- ...
