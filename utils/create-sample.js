#!/usr/bin/env node

'use strict';

const fs = require('fs');

const articleName = process.argv[2];

if (!articleName) {
	throw new Error('Не указан заголовок статьи');
}

const dirName = articleName.toLowerCase().replace(/[.,:;=+()*&^%$#@!"'\/?|{}<>~`\[\]]/g, '').split(' ').join('-');
const articleDir = `./articles/${dirName}`;
fs.mkdirSync(articleDir);

const sampleArticle = fs.readFileSync('./assets/sample.md', 'utf-8');
fs.writeFileSync(`${articleDir}/README.md`, sampleArticle);

console.log(`Образец для перевода создан -> '${articleDir}/README.md'.`);