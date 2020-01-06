# Generating CSS from scratch with PostCSS

For a soon-to-be open-sourced project I had to generate a CSS stylesheet based on user input.

Initially I started out with good 'ol string templating and interpolation but it soon became pretty complex, as I needed to conditionally add certain properties and declarations.

It occurred to me that what I wanted was a representation of the CSS structure in code, an Abstract Syntax Tree (AST). That would allow me to build up the CSS tree structure in code and turn it into a string later on.

I decided to see if I could use [PostCSS](https://postcss.org/), since I figured it must be turning CSS into an AST already.

<!-- excerpt -->

### PostCSS

[PostCSS](https://postcss.org/) is "A tool for transforming CSS with JavaScript". It's widely use in the industry for things like [auto-prefixing CSS](https://autoprefixer.github.io/).

As the tag line says, PostCSS main business is *transforming* CSS, not generating it from scratch as I wanted to do. Looking at the PostCSS codebase I noticed [a test](https://github.com/postcss/postcss/blob/master/test/postcss.test.js#L116) named `it allows to build own CSS` so I figured it should be possible!

Fast forward a couple of hours diving through the PostCSS codebase, reading the API docs and several PostCSS plugins, I had a working solution.

### Generating CSS from scratch

To generate CSS with PostCSS you first need to build up an AST:

```js
const postcss = require("postcss");

const fontFamily = "My Family";
const root = postcss.root();

const bodyRule = postcss.rule({ selector: "body" }).append(
  postcss.decl({
    prop: "font-family",
    value: `"${fontFamily}"`
  })
);

const fontFace = postcss.atRule({ name: "font-face" }).append([
   postcss.decl({ prop: "font-family", value: `"${fontFamily}"` }),
   postcss.decl({ prop: "src", value: "url(./fonts/myfont.woff2)" })
]);

root.append([
  fontFace,
  bodyRule
]);
```

The CSS code can then be generated from the CSS with `root.toString()`, resulting in this:

```css
@font-face {
    font-family: "My Family";
    src: url(./fonts/myfont.woff2)
}
body {
    font-family: "My Family"
}
```

A couple of things to note:

* PostCSS does not provide much help in generating proper declaration values [out of the box](https://github.com/TrySound/postcss-value-parser). For example quoting a `font-family` value in case it contains multiple words is not handled by PostCSS automatically.
* It's easy to conditionally generate properties, rules, declarations etc. The API follows a typical builder pattern, which makes it easy to conditionally call `append`, or not.
* The CSS output is opinionated. There are no semicolons after the last declaration and no newlines between rules.

Fortunately, PostCSS is architected quite well and allows you to provide your own ["Stringifier"](http://api.postcss.org/global.html#stringifier). I didn't find much documentation or guidance on this though, but after a bit of code diving I settled on this:

```js
const Stringifier = require("postcss/lib/stringifier");

class PrettyStringifier extends Stringifier {
  static new() {
    return (node, builder) => {
      let str = new this(builder);
      str.stringify(node);
    };
  }

  constructor(builder) {
    super(builder);
  }

  rule(node) {
    if (node.prev()) {
      // Add a newline after a rule, if it's preceded by another rule.
      this.builder("\n", node);
    }

    return super.rule(node);
  }

  decl(node) {
    return super.decl(node, true /* force semicolon */);
  }
}
```

As you can see, this is inheriting most of the default behaviour except around rules and declarations.

The custom `Stringifier` can be used like this:

```js
root.toString(PrettyStringifier.new());
```

### Conclusion

All in all I achieved what I had to do, but it didn't feel like PostCSS was particularly well suited for this use-case as everything in PostCSS is geared towards *transforming* CSS.

Nevertheless it was nice experiment. Having used PostCSS a lot via Autoprefixer it was interesting to dig into internals of PostCSS to see how everything works!

If you have any tips on using PostCSS for this purpose, or perhaps other tools that might be better suited for this, please let me know!
