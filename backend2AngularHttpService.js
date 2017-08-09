#!/user/bin/env node
var rf = require("fs")

// 参数1 是 Java 文件名

process.stdin.setEncoding('utf8')

const argument = process.argv.slice(2);
const filename = argument[0];

const lastIndexOfSlash = filename.lastIndexOf('/');
let className = filename.replace('Router.java', 'Api');
let moduleName = filename.replace('Router.java', '').toLowerCase()
className = className.slice(lastIndexOfSlash + 1);
moduleName = moduleName.slice(lastIndexOfSlash + 1);

const headerStr = `
import { Injectable } from '@angular/core'

import { SettingService } from '../core/setting/setting.service'
import { HttpService } from '../core/http/http.service'

@Injectable()
export class ${className}Service {
  constructor (private httpService: HttpService, private settingService: SettingService) {
  }

  private post (url: string, body: any) {
    return new Promise((resolve, reject) => {
      const successFn = (resp) => {
        resolve(resp)
      }
      const errorFn = (resp) => {
        reject(resp)
      }
      this.httpService.post(this.settingService.getServerURL() + url, body, successFn, errorFn)
    })
  }
`

const footerStr = `

}
`
const replaceRegArray = [
    /\s+\*\s<p>/,
    /\s+\*\s<\/?blockquote>/,
    /\s+\*\s<\/?pre>/
]

const serviceResult = []

const requestParamArray = [ '' ]
let addItemToRequestParamArray = false

serviceResult.push(headerStr)
rf.readFile(filename, 'utf-8', function (err, data) {
    if (err) {
        console.log("error")
    } else {
        const sourceArray = data.split(/[\n\r]/)
        sourceArray.forEach(item => {
            if (/^\s{2,}\/?\*+/.test(item)) {
                for (let p of replaceRegArray) {
                    item = item.replace(p, '')
                }
                if (item) {
                    if (item.indexOf('* 请求') !== -1) {
                        addItemToRequestParamArray = true
                    } else if (item.indexOf('* 返回') !== -1) {
                        requestParamArray.push('')
                        addItemToRequestParamArray = false
                    } else if (addItemToRequestParamArray && /^\s+\*\s+"(\w+)"/.test(item)) {
                        /^\s+\*\s+"(\w+)"/.exec(item)
                        requestParamArray[ requestParamArray.length - 1] += (requestParamArray[ requestParamArray.length - 1] ? ',' : '') + RegExp.$1
                    }
                    const lineBreak = /\s+\*\//.test(item) ? '' : '\n'
                    serviceResult.push(item + lineBreak)
                }
            } else if (/^\s+public\sstatic\sRoute/.test(item)) {
                const getFunctionNoReg = /Route\s(function\d+)/
                getFunctionNoReg.exec(item)
                const oneFuncDef = `
                public ${RegExp.$1} (##requestParam##) {
                    return this.post('${moduleName}/${RegExp.$1}', { ##requestParam## })
                }
                `
                serviceResult.push(oneFuncDef)
            }
        })
        serviceResult.push(footerStr)
        serviceResult.forEach((item, index) => {
            if (/##requestParam##/.test(item)) {
                const params = requestParamArray.shift() || ''
                serviceResult[index] = item.replace(/##requestParam##/g, params)
            }
        })
        console.log(serviceResult.join(''))
    }
})
