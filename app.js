const { exec } = require('child_process')
const path = require('path')
const fs = require('fs')
const mime = require('mime-types')

const PROJECT_ID = process.env.PROJECT_ID

async function init() {
    console.log("Executing app.js");
    const outDirPath = path.join(__dirname, 'output')

    const p = exec(`cd ${outDirPath} && npm install && npm run build`)

    p.stdout.on('data', function(data) {
        console.log(data.toString());
    })
    p.stdout.on('error', function(error) {
        console.log(error.toString());
    })
    p.on('close', async function() {
        console.log('Build complete');
        const distFolderPath = path.join(__dirname, 'output', 'dist')
        const distFolderContents = fs.readdirSync(distFolderPath, { recursive: true })
        for(const file of distFolderContents) {
            const filePath = path.join(distFolderPath, file)
            if(fs.lstatSync(filePath).isDirectory()) continue;

            console.log('uploading ', filePath);
            
            const formData = new FormData()
            formData.append('file', fs.createReadStream(filePath))
            let putObject = await fetch(`https://s3.automateandlearn.site/upload`, {
                method: 'POST',
                headers: {
                    'Content-Type': `${mime.lookup(filePath)}`,
                    'projectname': `${PROJECT_ID}`,
                },
                body: formData,
            })
            let response = await putObject.json()
            console.log(response);
        }
        console.log('Done!');
    })
}

init()