/* Use in your app by simply adding to your app's index.js:

import "bridgetown-lit-renderer" */

import "@lit-labs/ssr-client/lit-element-hydrate-support.js"

class HydrateRootElement extends HTMLElement {
  connectedCallback() {
    const node = this.children[0]
    node.removeAttribute("defer-hydration")
  }
}

customElements.define("hydrate-root", HydrateRootElement)
