const path = require("path");
const fs = require("fs");

var dev_filename = path.resolve("C:\\HaxeToolkit\\haxe\\lib\\openfl\\.dev");
var exists = fs.existsSync(dev_filename);
if (exists) {
    fs.unlinkSync(dev_filename);
} else {
    fs.writeFileSync(dev_filename, "C:\\Projects\\openfl\n", "utf-8");
}