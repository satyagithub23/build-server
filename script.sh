#!/bin/bash

set -o allexport
source .env
set +o allexport

export GIT_REPOSITORY_URL="$GIT_REPOSITORY_URL"
echo "$GIT_REPOSITORY_URL"

git clone "$GIT_REPOSITORY_URL" /home/app/output

cd /home/app/output || exit

npm install

entry_point=$(node -e "
    const fs = require('fs')
    const path = './package.json'
    if(fs.existsSync(path)) {
        const pkg = JSON.parse(fs.readFileSync(path), 'utf-8')
        console.log(pkg.main)
    } else {
        console.log('Error finding entry point')
        process.exit(1)
    }
")

echo "Entry point: $entry_point"

has_build=$(node -e "
    const fs = require('fs')
    const path = './package.json'
    if(fs.existsSync(path)) {
        const pkg = JSON.parse(fs.readFileSync(path), 'utf-8')
        console.log(pkg.scripts && pkg.scripts.build ? 'yes' : 'no')
    } else {
        console.log('Error finding package.json')
        process.exit(1)
    }
")

has_start=$(node -e "
    const fs = require('fs')
    const path = './package.json'
    if(fs.existsSync(path)) {
        const pkg = JSON.parse(fs.readFileSync(path), 'utf-8')
        console.log(pkg.scripts && pkg.scripts.start ? 'yes' : 'no')
    } else {
        console.log('Error finding package.json')
        process.exit(1)
    }
")

if [ "$has_build" == "no" ]; then
    echo "Adding 'build' script to package.json"
    node -e '
        const fs = require("fs");
        const path = "./package.json";
        if (fs.existsSync(path)) {
            const pkg = JSON.parse(fs.readFileSync(path, "utf-8"));
            pkg.scripts = pkg.scripts || {};
            pkg.scripts.build = `node ${pkg.main || "index.js"}`;
            fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
            console.log("Build script added successfully");
        } else {
            console.error("Error: package.json not found");
            process.exit(1);
        }
    '
else
    echo "Build script already exists"
fi


if [ "$has_start" == "no" ]; then
    echo "Adding 'start' script to package.json"
    node -e '
        const fs = require("fs");
        const path = "./package.json";
        if (fs.existsSync(path)) {
            const pkg = JSON.parse(fs.readFileSync(path, "utf-8"));
            pkg.scripts = pkg.scripts || {};
            pkg.scripts.start = `node ${pkg.main || "index.js"}`;
            fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
            console.log("Start script added successfully");
        } else {
            console.error("Error: package.json not found");
            process.exit(1);
        }
    '
else
    echo "Start script already exists"
fi


exec node app.js