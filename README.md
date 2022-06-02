# Bridgetown Lit Renderer

[![lit][lit]][lit-url]
[![gem][gem]][gem-url]
[![npm][npm]][npm-url]
[![Demo Site](https://img.shields.io/badge/Demo%20Site-teal?style=for-the-badge&logo=safari)](https://bridgetown-lit-renderer.onrender.com)

This [Bridgetown](https://www.bridgetownrb.com) plugin provides you with an easy-to-use pipeline for SSR + hydration of Lit components. Create "islands" of interactivity using Lit-based web components which are fully supported in all major browsers, and take full advantage of scoped component styling via the shadow DOM.

## Documentation

**[The official documentation is now available on the Bridgetown website.](https://edge.bridgetownrb.com/docs/components/list)**

[Check out the demo site repo.](https://github.com/bridgetownrb/lit-renderer-example)

## Installation

Starting in Bridgetown v1.1, you can install this plugin via a bundled configuration:

```shell
$ bin/bridgetown configure lit
```

For a manual installation overview:

Run this command to add this plugin to your site's Gemfile, along with Lit and SSR support:

```shell
$ bundle add bridgetown-lit-renderer -g bridgetown_plugins

$ yarn add lit bridgetown-lit-renderer
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