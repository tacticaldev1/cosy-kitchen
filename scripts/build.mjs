// Builds the game from src/ into dist/.
//   dist/index.html        – a normal, standalone web page (open it in any browser, upload it anywhere)
//   dist/artifact.html     – the same game without <!doctype>/<head>/<body>, for pasting into a Claude artifact
// No dependencies: run with `node scripts/build.mjs` (or `npm run build`).
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const src = join(root, 'src');
const shell = readFileSync(join(src, 'shell.html'), 'utf8');
// JS files are concatenated in filename order (01-, 02-, …) inside one closure.
const files = readdirSync(src).filter(f => f.endsWith('.js')).sort();
const js = files.map(f => `// ---- ${f} ----\n` + readFileSync(join(src, f), 'utf8')).join('\n');
const script = `<script>\n(() => {\n${js}\n})();\n</script>\n`;

const artifact = shell + script;
const [head, rest] = shell.split('<style>');
const page = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, user-scalable=no">
${head.replace('<meta name="claude:viewport-fit-sides" content="cover">\n', '')}<style>
:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:border-box;height:100%}
body{margin:0}
[hidden]{display:none!important}
${rest.replace('</style>\n', '</style>\n</head>\n<body>\n')}${script}</body>
</html>
`;
mkdirSync(join(root, 'dist'), { recursive: true });
writeFileSync(join(root, 'dist', 'artifact.html'), artifact);
writeFileSync(join(root, 'dist', 'index.html'), page);
console.log(`Built dist/index.html (${(page.length / 1024).toFixed(0)} KB) from ${files.length} source files.`);
