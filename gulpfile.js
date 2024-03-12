const gulp = require('gulp');
const svgo = require('gulp-svgo');
const iconfont = require('gulp-iconfont');
const Table = require('cli-table3'); // Note: cli-table2 might be outdated, consider using cli-table3
const fontmin = require('gulp-fontmin');
const cheerio = require('gulp-cheerio');
const pug = require('gulp-pug');
const svg2png = require('gulp-svg2png');

// Helper function to resize SVGs for PNG conversion
function resizeForPng($, file) {
  let $svg = $('svg');
  $svg.attr({ height: 500, width: 500, preserveAspectRatio: 'xMidYMid' });
}

// Helper function to clean up SVGs coming from Figma
function cleanUpFigmaSVG($, file) {
  $('use').each(function() {
    let $use = $(this);
    let transform = $use.attr('transform');
    let selector = $use.attr('xlink:href');
    let $target = $(selector);

    $target.attr('transform', transform);
    $use.replaceWith($target);
  });

  $('[figma\\:type]').removeAttr('figma:type');
  $('[fill="#FFFFFF"]').remove();
}

// Build task
function build() {
  let glyphList = [];
  let options = {
    fontName: 'DIn pIqaD',
    prependUnicode: true,
    ascent: 588.235,
    descent: 235.294,
    fontHeight: 1000
  };

  let svgoPlugins = [
    { transformsWithOnePath: true, removeEditorsNSData: true, removeDesc: true, removeTitle: true, collapseGroups: true }
  ];

  return gulp.src('svg/*.svg')
    .pipe(cheerio(cleanUpFigmaSVG))
    .pipe(svgo({ plugins: svgoPlugins }))
    .pipe(gulp.dest('processed-svg'))
    .pipe(iconfont(options))
    .on('glyphs', (glyphs, options) => {
      console.log(`Create font "${options.fontName}"`);
      let table = new Table({ head: ['NAME', 'UNICODE'] });
      
      glyphs.forEach(glyph => {
        table.push([glyph.name, glyph.unicode[0]]);
        glyphList.push([glyph.name, glyph.unicode[0]]);
      });

      console.log(table.toString());

      let pugOpts = { locals: { glyphs: glyphList } };
      gulp.src('demo.pug').pipe(pug(pugOpts)).pipe(gulp.dest('demo'));
    })
    .pipe(gulp.dest('dist'))
    .on('end', () => {
      gulp.src('svg/*.svg')
        .pipe(cheerio(resizeForPng))
        .pipe(svg2png())
        .pipe(gulp.dest('./png'));
    });
}

// Watch task
function watch() {
  gulp.watch('svg/*.svg', build);
  gulp.watch('demo.pug', build);
}

// Default task
exports.default = gulp.series(build, watch);
