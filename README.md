# Bridgetown Lit Renderer

[![lit][lit]][lit-url]
[![gem][gem]][gem-url]
[![npm][npm]][npm-url]
[![Demo Site](https://img.shields.io/badge/Demo%20Site-teal?style=for-the-badge&logo=safari)](https://bridgetown-lit-renderer.onrender.com)

Simple pipeline for SSR + hydration of Lit components in your [Bridgetown](https://www.bridgetownrb.com) site.

[Check out the demo site repo](https://github.com/bridgetownrb/lit-renderer-example), or keep reading to get started.

## Installation

Run this command to add this plugin to your site's Gemfile, along with Lit 2 and Lit's SSR support:

```shell
$ bundle add bridgetown-lit-renderer -g bridgetown_plugins

$ yarn add bridgetown-lit-renderer lit @lit-labs/ssr
```

Create a file in `config/lit-ssr.config.js` with the following:

```js
const build = require("bridgetown-lit-renderer/build")

// You can customize this as you wish, perhaps add new esbuild plugins
const esbuildOptions = {}

build(esbuildOptions)
```

Add the following to the top of your `frontend/javascript/index.js` file:

```js
import "bridgetown-lit-renderer"
import "./lit-components"
```

For the purposes of testing your install, add the following to `frontend/javascript/lit-components.js`:

```js
import "lit/experimental-hydrate-support.js"
import { LitElement, html, css } from "lit"

export class HappyDaysElement extends LitElement {
  static styles = css`
    :host {
      display: block;
      border: 2px dashed gray;
      margin: 4px;
      padding: 4px;
      width: 20vw;
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

Finally, create a new `.erb` page somewhere in `src`, and add this somewhere in your template:

```erb
<%= lit data: {hello: "there"} do %>
  <happy-days hello="${data.hello}"></happy-days>
<% end %>
```

Now start up your Bridgetown site, visit the page, and if all goes well, you should see a box containing "Hello there!" and a timestamp when the page was first rendered.

You can reload the page several times and see that the timestamp doesn't change, because Lit's SSR + Hydration support knows not to re-render the component. However, if you change the `hello` attribute in the HTML, you'll get a re-render and thus see a new timestamp. _How cool is that?!_

### Configuration options

_More docs forthcoming..._

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