const { src, dest } = require('gulp');
const fs = require('fs');
const rename = require('gulp-rename');

const sass = require('gulp-sass')(require('sass'));

const handlebars = require('gulp-compile-handlebars');

const pegjs = require("pegjs");

const markdownit = require('markdown-it');
const md = markdownit();

/**
 * Parse a file using a specific PEG.js grammar.
 * 
 * @param {*} fileName Full path to the file
 * @param {*} syntax   Name of the grammar to be used (file name without an extension)
 * @returns            AST as defined by the grammar.
 */
const parseFile = function(fileName, syntax) {

    const grammar = fs.readFileSync('./src/parsers/' + syntax + '.pegjs', 'utf8');
    const parser = pegjs.generate(grammar);
    const fileContents = fs.readFileSync(fileName, 'utf8');

    return parser.parse(fileContents);
};

exports.dictionary = function() {

    const dictionary = parseFile('./src/data/romani.dictionary', 'dictionary');

    // Process all markdown chunks within the dictionary:
    dictionary.entries.forEach(function(entry) {
        if (entry.text) {
            entry.text = md.render(entry.text);
        }
    });

    return src('./src/templates/dictionary.handlebars')
        .pipe(handlebars(dictionary, {}))
        .pipe(rename('dictionary.html'))
        .pipe(dest('./dist'));
};

exports.glossed = function() {

    const dictionary = parseFile('./src/data/romani.dictionary', 'dictionary');
    const glossed = parseFile('./src/data/sar-me-phiravas-andre-skola.glossed', 'glossed');

    // Process all markdown chunks within the glossed text:
    glossed.blocks.forEach(function(block) {
        if (block.text) {
            block.text = md.render(block.text);
        }
    });

    return src('./src/templates/glossed.handlebars')
        .pipe(handlebars(glossed, {
            batch: ['./src/templates/partials'],
            helpers: {
                lemma: function(morph) {
                    return dictionary.entries.find(function(entry) {
                        return (entry.headword && entry.headword.key == morph.refs[0]);
                    });
                }
            }
        }))
        .pipe(rename('sar-me-phiravas-andre-skola.html'))
        .pipe(dest('./dist'));
};

exports.styles = function() {
    return src('./src/styles/*.scss')
        .pipe(sass().on('error', sass.logError))
        .pipe(dest('./dist/css'));
};

//exports.watch = function () {
//    gulp.watch('./sass/**/*.scss', ['sass']);
//};


exports.default = function(cb) {
    // place code for your default task here
    cb();
};
