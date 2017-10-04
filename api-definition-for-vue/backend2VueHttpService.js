#!/user/bin/env node
const fs = require("fs")

process.stdin.setEncoding('utf8')

let moduleName
let className
let isFillRequestParams = false
let currRequestParamArray = []

const replaceRegArray = [
    /\s+\*\s<p>/,
    /\s+\*\s<\/?blockquote>/,
    /\s+\*\s<\/?pre>/
]
const resultArray = []

function getTargetString (targetStr) {
    let isExist = false
    replaceRegArray.forEach(item => {
        if (item.test(targetStr)) {
            isExist = true
        }
    })
    return isExist ? '' : targetStr.replace(/^\t/, '')
}

exports.createApiDefinitionFile = function (filename, filePath) {
    let moduleName = filename.replace('Router.java', '')
    className = moduleName + 'Api'
    moduleName = moduleName.toLowerCase()
    const headerStr = `import * as request from './base/request'
import { createGETParams } from './base/utils'
import { AppConfig } from '../config/config'

export class ${className} {
  static serverURL = AppConfig.serverURL

  static get (path, params = {}) {
    return request.get(path, createGETParams(params))
  }

  static post (path, params = {}) {
    return request.post(path, params)
  }`
    const footerStr = `}`
    const resultArray = [ headerStr ]
    const fileContent = fs.readFileSync(filePath, 'utf-8')
    fileContent.split(/[\n\r]/).forEach(line => {
        if (/^\s+\/\*{2}$/.test(line) || /^\s+\*/.test(line)) {
            if (line.indexOf('返回数组结构') !== -1) {
                resultArray.push('* @returns object 服务器相应数据')
            } else if (line.indexOf('请求') !== -1) {
                resultArray.push('* 请求参数')
                isFillRequestParams = true
            } else {
                const targetStr = getTargetString(line)
                if (targetStr && isFillRequestParams && /^\s+\*\s+\{/.test(targetStr)) {
                    // 请求参数开始
                } else if (targetStr && isFillRequestParams && /^\s+\*\s+\}/.test(targetStr)) {
                    // 请求参数结束
                    isFillRequestParams = false
                } else if (targetStr && isFillRequestParams) {
                    let paramStr = targetStr.replace(/^\s+\*\s+"/, '').replace(/":\s+#/, ' ')
                    resultArray.push(`* @param ${paramStr}`)
                    const a = /^(\w+)/.test(paramStr)
                    currRequestParamArray.push(RegExp.$1)
                } else if (targetStr) {
                    resultArray.push(targetStr)
                }
            }
        } else if (/^\s+public\sstatic\sRoute\s(function\d+)/.test(line)) {
            resultArray.push(`static ${RegExp.$1} (${currRequestParamArray.join(', ')}) {
    return ${className}.post(this.serverURL + "${moduleName}/${RegExp.$1}", { ${currRequestParamArray.join(', ')} })
  }`)
            currRequestParamArray = []
        }
    })
    resultArray.push(footerStr)
    fs.writeFileSync(`./dist/${moduleName}.api.js`, resultArray.join('\n'))
}