const fs = require('fs');
const path = require('path');
const vm = require('vm');
const [project, sdk] = process.argv.slice(2);
const script = path.join(project, 'hvigor/update-sdk-interface.js');
const source = fs.readFileSync(script, 'utf8').replace(/updateSdkInterface\(\);\s*$/, `
globalThis.manifest = { copy: copyOHPathFileArray, replace: replaceOHPathFileArray, remove: removeOHPathFileArray };`);
const context = {require, __dirname: path.dirname(script), process: {argv: ['node', script, sdk]}, console};
vm.createContext(context);
vm.runInContext(source, context, {filename: script});
const report = {};
for (const [operation, entries] of Object.entries(context.manifest)) {
    report[operation] = entries.map(entry => ({
        source: entry.file ? path.resolve(path.dirname(script), entry.file) : null,
        destination: path.resolve(sdk, entry.path, entry.file ? path.basename(entry.file) : ''),
        sourceExists: entry.file ? fs.existsSync(path.resolve(path.dirname(script), entry.file)) : null,
        destinationExists: fs.existsSync(path.resolve(sdk, entry.path, entry.file ? path.basename(entry.file) : ''))
    }));
}
console.log(JSON.stringify(report, null, 2));
