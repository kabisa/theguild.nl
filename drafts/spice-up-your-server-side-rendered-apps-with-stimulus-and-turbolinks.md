# 🌶 Spice up your server-side rendered apps with Stimulus and Turbolinks

These days, SPA's (Single Page Applications) are an undeniable trend on the web. However, I personally think there are many use cases where a 'traditional' server-side rendered application still makes sense, for example for CRUD-style / admin applications or in general when your application doesn't require highly interactive features.

For use cases like these, it's generally more convenient and faster to use server side rendering. Still, also these kinds of applications can benefit from small bits of interactivity like a `copy to clipboard` feature, selecting multiple checkboxes in a table at once etc.

[Stimulus](https://stimulusjs.org) is a relatively new Javascript framework designed specifically to be used with server-side rendered applications. It provides tools to bind Javascript to your server-side rendered HTML. It's modest in feature set, but provides just the right tools, abstractions and conventions to add these little nuggests of interactivity to your application in a sane way.

For example implementing a `Copy to clipboard` button looks something like this:

1. Render your HTML on the server.

```html
<div data-controller="clipboard">
  PIN: <input data-target="clipboard.source" type="text" value="1234" readonly>
  <button data-action="clipboard#copy">Copy to Clipboard</button>
</div>
```

2. Create a Javascript controller file that will handle this action.

```javascript
import { Controller } from "stimulus";

export default class ClipboardController extends Controller {
  static targets = [ "source" ];

  copy() {
    this.sourceTarget.select();
    document.execCommand("copy");
  }
}
```

That's it! Now if you want to add a `Copy to clipboard` feature anywhere in your app, all you have to do is add these few `data` attributes to your HTML.

### Turbolinks

Stimulus also works very well combined with [Turbolinks](https://github.com/turbolinks/turbolinks/). Turbolinks is a small library you can drop into your page which will massively speed up your app, with hardly any work required on your part. It does this by applying a [neat trick](https://github.com/turbolinks/turbolinks/#navigating-with-turbolinks); it fetches subsequent pages in your app via Ajax and merges the new page into the current page. This reduces the work the browsers have to do for each navigation greatly.

Combining Turbolinks and Stimulus will make your app feel very responsive, interactive where it needs to be and best of all you don't have to re-architect your app to achieve this.

Note that Turbolinks originated from Ruby on Rails, but works with any server side rendering technology. At Kabisa we've used Turbolinks together with Elixir Phoenix for example.

If you want to learn more about Stimulus be sure to check out its [handbook](https://stimulusjs.org/handbook/introduction). Refer to the [Turbolinks docs](https://github.com/turbolinks/turbolinks/#attaching-behavior-with-stimulus) for more information about using Turbolinks and Stimilus together.

Happy coding!