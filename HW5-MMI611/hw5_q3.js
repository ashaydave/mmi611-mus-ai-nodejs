// Copyright Tom Collins, 21.1.2024
// Pre-processing MIDI files, calculating their mean MIDI note number, and
// writing them to file.

// Requires
const argv = require('minimist')(process.argv.slice(2))
const fs = require("fs")
const path = require("path")
const plotlib = require("nodeplotlib")
const mm = require("maia-markov")
const mu = require("maia-util")
const an = new mm.Analyzer()

// Individual user paths
const mainPaths = {
  "ashay": {
    "inDir": path.join(
      "/Users", "ashay", "source", "repos", "HW5-MMI611", "josquin_bach_midi"
    ),
    "outDir": path.join(
      "/Users", "ashay", "source", "repos", "HW5-MMI611", "josquin_bach_midi",
      "harmAnResults"
    ),
    "outFileName": "josquin_bach_harmAn"
  },
  "anotherUser": {
    // ...
  }
}

// Parameters
const param = {
  "ontimeIndex": 0,
  "mnnIndex": 1,
  "durIndex": 2
}

// Import and analyze the MIDI files.
const mainPath = mainPaths[argv.u];
console.log("Here we go!");
let files = fs.readdirSync(mainPath["inDir"]);
files = files.filter(function(file){
  return path.extname(file) === ".mid";
});
console.log("files.length:", files.length);

// Iterate
files.forEach(function(file, ithFile){
  console.log("Processing file", ithFile + 1, "of", files.length);
  const fid = file.split(".mid")[0];
  console.log("File:", fid);
  try {
    const mi = new mm.MidiImport(path.join(mainPath["inDir"], file));
    const seg = mu.segment(mi.points, true, param.ontimeIndex, param.durIndex);

    const harmAnResult = mu.harman_forward(seg, mu.chord_templates_pbmin7ths, mu.chord_lookup_pbmin7ths);

    // Write the HarmAn result to file
    const outputFileName = path.join(mainPath["outDir"], `${fid}_${mainPath["outFileName"]}.txt`);
    fs.writeFileSync(outputFileName, JSON.stringify(harmAnResult));

    console.log("HarmAn result:", harmAnResult);
  }
  catch (e) {
    console.log("Error processing file", fid, ":", e);
  }
});
