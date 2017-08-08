#!/user/bin/env node
var rf = require("fs")

// 参数是 Java 文件名

process.stdin.setEncoding('utf8')

const headerStr = `
import { Injectable } from '@angular/core'

import { SettingsService } from '../../core/settings/settings.service'
import { HttpService } from '../../core/http/http.service'

@Injectable()
export class OrderService {
  constructor (private httpService: HttpService, private settingsService: SettingsService) {
  }

  private post (url: string, body: any) {
    return new Promise((resolve, reject) => {
      const successFn = (resp) => {
        resolve(resp)
      }
      const errorFn = (resp) => {
        reject(resp)
      }
      this.httpService.post(this.settingsService.serverURL + url, body, successFn, errorFn)
    })
  }
`

const footerStr = `

}
`

const filename = process.argv.slice(2)[0];

const replaceRegArray = [
    /\s+\*\s<p>/,
    /\s+\*\s<\/?blockquote>/,
    /\s+\*\s<\/?pre>/
]

const serviceResult = []

const requestParamArray = [ '' ]
let addItemToRequestParamArray = false

const moduleName = filename.replace('Router.java', '').toLowerCase()

serviceResult.push(headerStr)
rf.readFile('./' + filename, 'utf-8', function (err, data) {
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
