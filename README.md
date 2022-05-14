# Bridgetown Lit Renderer

[![lit][lit]][lit-url]
[![gem][gem]][gem-url]
[![npm][npm]][npm-url]
[![Demo Site](https://img.shields.io/badge/Demo%20Site-teal?style=for-the-badge&logo=safari)](https://bridgetown-lit-renderer.onrender.com)

This [Bridgetown](https://www.bridgetownrb.com) plugin provides you with an easy-to-use pipeline for SSR + hydration of Lit components. Create "islands" of interactivity using Lit-based web components which are fully supported in all major browsers, and take full advantage of scoped component styling via the shadow DOM.

[Check out the demo site repo](https://github.com/bridgetownrb/lit-renderer-example), or keep reading to get started.

## Installation

Starting in Bridgetown v1.1, you can install this plugin via a bundled configuration:

```shell
$ bin/bridgetown configure lit
```

Keep reading for a manual installation overview, or [skip this section](#take-lit-for-a-spin) to continue reading about plugin usage.

Run this command to add this plugin to your site's Gemfile, along with Lit and SSR support:

```shell
$ bundle add bridgetown-lit-renderer -g bridgetown_plugins

$ yarn add bridgetown-lit-renderer lit @lit-labs/ssr
```

Create a file in `config/lit-ssr.config.js` with the following:

```js
const build = require("bridgetown-lit-renderer/build")
const { plugins } = require("./esbuild-plugins.js")

const esbuildOptions = { plugins }

build(esbuildOptions)
```

and `config/esbuild-plugins.js`:

```js
// You can add esbuild plugins here you wish to share between the frontend bundles and Lit SSR:
module.exports = {
  plugins: []
}
```

and if you're using esbuild for your Bridgetown site, modify `esbuild.config.js``:

```js
// at the top of your file:
const { plugins } = require("./config/esbuild-plugins.js")

const esbuildOptions = {
  // other options

  plugins: [...plugins]
}
```

To ensure all `.lit.js`/`.lit.js.rb` files in your `src/_components` are automatically made available to the Lit SSR process, create the following `config/lit-components-entry.js` file:

```js
import components from "bridgetownComponents/**/*.{lit.js,lit.js.rb}"
```

Now add the following to the top of your `frontend/javascript/index.js` file:

```js
import "bridgetown-lit-renderer"
```

### Take Lit for a Spin

For the purposes of testing your install, create the `src/_components/happy-days.lit.js` file:

```js
import "lit/experimental-hydrate-support.js"
import { LitElement, html, css } from "lit"

export class HappyDaysElement extends LitElement {
  static styles = css`
    :host {
      display: block;
      border: 2px dashed gray;
      padding: 20px;
      max-width: 300px;
    }
  `

  static properties = {
    hello: { type: String }
  }

  render() {
    return html`
      <p>Hello ${this.hello}! ${Date.now()}</p>
    `;
  }
}

customElements.define('happy-days', HappyDaysElement)
```

Finally, create a new `.erb` page somewhere in `src`, and add this to your template:

```erb
<%= lit :happy_days, hello: "there" %>
```

(The helper will know how to convert the tag name and attribute keywords to HTML output.)

Now start up your Bridgetown site, visit the page, and if all goes well, you should see a box containing "Hello there!" and a timestamp when the page was first rendered.

You can reload the page several times and see that the timestamp doesn't change, because Lit's SSR + Hydration support knows not to re-render the component. However, if you change the `hello` attribute, you'll get a re-render and thus see a new timestamp. _How cool is that?!_

### Lit Helper Options

The `lit` helper works in any Ruby template language and let's you pass data down to the Lit SSR build process. Any value that's not alreadey a string will be converted to JSON (via Ruby's `to_json`). You can use a symbol or string for the tag name and underscores are automatically converted to dashes.

```erb
<%= lit :page_header, title: resource.data.title %>
```

(Remember, all custom elements always must have at least one dash within the HTML.)

If you pass a block to `lit`, it will add that additional HTML into the Lit template output:

```erb
<%= lit :ui_sidebar do %>
  <h2 slot="title">Nice Sidebar</h2>
<% end %>
```

You can also pass page/resource front matter and other data along via the `data` keyword, which then can be used in the block. In addition, if a tag name isn't present, you can add it yourself in within the block.

```erb
<%= lit data: resource.data do %>
  <page-header>
    <h1>${data.title}</h1>
  </page-header>
<% end %>
```

When the component is hydrated, it will utilize the same data that was passed at build time and avoid a client-side re-render. However, from that point forward you're free to mutate component attribute/properties to trigger re-renders as normal. [Check out Lit's `firstUpdated` method](https://lit.dev/docs/components/lifecycle/#reactive-update-cycle-completing) as a good place to start.

You also have the option of choosing a different entry point (aka your JS file that contains or imports one or more Lit components). The default is `./config/lit-components-entry.js`, but you can specify any other file you wish (the path should be relative to your project root).

```erb
<%= lit data: resource.data, entry: "./frontend/javascript/components/headers.js" do %>
  <page-header title="${data.title}"></page-header>
<% end %>
```

This would typically coincide with a strategy of having multiple esbuild/Webpack entry points, and loading different entry points on different parts of your site. An exercise left for the reader…

### Sidecar CSS Files

The "default" manner in which you author styles in Lit components is to use `css` tagged template literals (as you saw in the `happy-days` example above). However, some people prefer authoring styles in dedicated CSS files.

The [esbuild-plugin-lit-css](https://github.com/bennypowers/lit-css/tree/main/packages/esbuild-plugin-lit-css) plugin allows you to author perfectly vanilla CSS files alongside your component files and import them. 

In order to separate the "globally-accessible" stylesheets you may have in `src/_components` from the Lit component-specific stylesheets (which we only want to get instantiated within component shadow roots), we'll use the following file conventions:

* For global stylesheets, use a `.global.css` suffix.
* For Lit component stylesheets, use a `.lit.css` suffix.

If you used Bridgetown v1.1 or later's Lit bundled configuration, this is already installed and configured for you. Otherwise, you'll need to do just a bit of manual setup to get things working.

TBD

### Technical and Performance Considerations

The Bridgetown Lit render helper works by compiling your entry point together with your code block via esbuild and caching the resulting JS snippet. A second pass combines your `data` with the snippet and executes it via a temporary "sidecar" Node server which utilizes Lit's SSR rendering pipeline.

This for performance reasons. If you have added a Lit template to a layout used by, say, a thousand products, your first build will indeed execute Lit SSR for those thousand products, but thereafter it will be cached. If you change the data for one product, such as a price, Lit SSR will reexecute _only_ for that one product. In addition, for a data-only change the previously compiled JS snippet via esbuild _won't_ need to be recompiled. Of course if you also modify either the HTML markup within the helper block or the entry point itself, recompilation must take place.

It's also recommended you don't include any Ruby template code _within_ the helper code block (e.g., using `<%= %>` tags) which results in constantly changing output, as that would necessitate recompiling with esbuild on a regular basis.

In v2.0 of this plugin, we only persist these caches during the build process and then the cache is cleared. To cache in a way which persists on-disk for use across builds, you can add `enable_lit_caching: true` to your Bridgetown config. For instance, if you're mainly working on content or other aspects of the site and not directly modifying Lit component code, you'll gain back some build performance by enabling full caching.

In summary—with a bit of careful planning of which entry point(s) you create, the data you provide, and the structure of your HTML markup within the `lit` helper, you can achieve good Lit SSR performance while still taking full advantage of the Ruby templates and components you know and love.

**A note about Lit templates:** in case you're wondering, the markup within the `lit` helper is actually executed inside Lit's `html` tagged template literal, and [all the usual rules of Lit templates apply](https://lit.dev/docs/templates/overview/). It's recommended you keep the markup within the helper block brief, and let the web component itself do most of the heavy lifting.

**Use only one root element.** Because of how the provided `hydrate-root` element works, which will wrap your markup in each `lit` code block, you should only have _one_ root element, and it should be a Lit component. For example, instead of doing this:

```erb
<%= lit do %>
  <div>
    <h2>Hmm...</h2>
    <my-component>This doesn't seem right.</my-component>
  </div>
  <p>Huh.</p>
<% end %>
```

you should be doing this:

```erb
<%= lit do %>
  <wrapper-component>
    <div>
      <h2>Hmm...</h2>
      <my-component>This doesn't seem right.</my-component>
    </div>
    <p>Huh.</p>
  </wrapper-component>
<% end %>
```

**Disabling hydration?** If for some reason you can't permit a `hydrate-root` element to wrap a Lit code block, you can pass a `hydrate_root: false` argument to the `lit` helper. This breaks hydration however, and likewise the [Declarative Shadow DOM (DSD)](https://web.dev/declarative-shadow-dom/) polyfill won't be loaded. (Currently DSD is only supported natively in Chromium-based browsers such as Chrome, Edge, and Brave.) It will thus be up to you to manage those features as you see fit.

## Testing

* Run `bundle exec rake test` to run the test suite
* Or run `script/cibuild` to validate with Rubocop and Minitest together.

## Contributing

1. Fork it (https://github.com/bridgetownrb/bridgetown-lit-renderer/fork)
2. Clone the fork using `git clone` to your local development machine.
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

[lit]: https://img.shields.io/badge/-Lit-324FFF?style=for-the-badge&logo=lit&logoColor=white"
[lit-url]: https://lit.dev
[gem]: https://img.shields.io/gem/v/bridgetown-lit-renderer.svg?style=for-the-badge&color=red
[gem-url]: https://rubygems.org/gems/bridgetown-lit-renderer
[npm]: https://img.shields.io/npm/v/bridgetown-lit-renderer.svg?style=for-the-badge
[npm-url]: https://npmjs.com/package/bridgetown-lit-renderer