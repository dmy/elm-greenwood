#!/usr/bin/env node

function usage() {
    console.log("Usage: elm-deps-rss [path/to/elm.json]");
    process.exit(1);
}

if (process.argv[2] === "--help" || process.argv[2] === "-h") {
    usage();
}

const fs = require("fs");
const elmJsonPath = process.argv[2] || "elm.json";

if (!fs.existsSync(elmJsonPath)) {
    console.log(elmJsonPath + " file not found\n");
    usage();
}

const elmJson = JSON.parse(fs.readFileSync(elmJsonPath));

let deps = [];
if (elmJson.type == "package") {
    deps = Object.keys(elmJson.dependencies);
} else {
    deps = Object.keys(elmJson.dependencies.direct)
        .concat(Object.keys(elmJson.dependencies.indirect));
}

let queryMap = {};
deps.forEach(dep => {
    let [author, pkg] = dep.split("/");
    if (author in queryMap) {
        queryMap[author] += "+" + pkg;
    } else {
        queryMap[author] = pkg;
    }
});

let query = []
for (const [author,name] of Object.entries(queryMap)) {
    query.push(author + "=" + name); 
}
query = query.join("&");

console.log("Web feed:");
console.log("https://elm-greenwood.com?" + query);

console.log("\nRSS feed:");
console.log("https://elm-greenwood.com/.rss?" + query);
