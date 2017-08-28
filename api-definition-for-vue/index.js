#!/user/bin/env node

'use strict'
const createApiDefinitionFile = require('./backend2VueHttpService')

const fs = require('fs')

function getFileList (path) {
    const filesList = []
    readFile(path, filesList)
    return filesList
}

function readFile (path, filesList) {
    const files = fs.readdirSync(path)
    files.forEach(walk)

    function walk (file) {
        const states = fs.statSync(path + '/' + file)
        if (states.isDirectory()) {
            readFile(path + '/' + file, filesList)
        } else {
            const obj = {}
            obj.size = states.size
            obj.name = file
            obj.path = path + '/' + file
            filesList.push(obj)
        }
    }
}

getFileList('./source-java').forEach(item => {
    if (/Router\.java$/.test(item.name)) {
        createApiDefinitionFile.createApiDefinitionFile(item.name, item.path)
    }
})
