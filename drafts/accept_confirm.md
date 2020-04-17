# You're not stubbing, stupid!

Recently, in a [Ruby on Rails](https://rubyonrails.org/) project, I was writing a [Cucumber](https://cucumber.netlify.app/docs/installation/ruby/) scenario that was deleting a resource by having the user clicking a 'Delete' button. Before the action was executed, the user had to confirm a message shown in a confirmation dialog. You may have seen this dozens of times when scaffolding a Rails application.  
Oh and upon deleting, I also had to do a request to an external API (to be more precise: the use case was that of a user unsubscribing, so I had to send a `DELETE` request to a [Mollie API](https://docs.mollie.com/reference/v2/subscriptions-api/cancel-subscription)).

So, "nothing new here", I thought. I knew about [WebMock](https://github.com/bblimke/webmock), since I wanted to stub the external API request and my test suite was set up to test [JavaScript](https://github.com/teamcapybara/capybara#setup), so I knew I could use the [`accept_confirm`](https://www.rubydoc.info/github/jnicklas/capybara/Capybara%2FSession:accept_confirm) method here that Capybara offers. 

Stubbing the request was defined in a support file:

```ruby
# features/support/webmock.rb

require 'webmock/cucumber'

WebMock.disable_net_connect!(allow_localhost: true)

Before do |_scenario|
  stub_request(
    :delete, 
    %r{https://api.mollie.com/v2/customers/\w+/subscriptions/\w+}
  )
    .to_return(body: {}.to_json)
end

```

My step implementation looked like this:

```ruby
# features/step_definitions/general_steps.rb

When('I delete the resource') do
  accept_confirm { click_on 'Destroy' }
end
```

The test failed! It was telling me that I should stub the DELETE request.

```
  Real HTTP connections are disabled. Unregistered request: DELETE https://api.mollie.com/v2/customers/...

  You can stub this request with the following snippet:

  stub_request(:delete, "https://api.mollie.com/v2/customers/...").
    ...
    to_return(status: 200, body: "", headers: {})
```

Wasn't I doing this?

After many (!!!) hours of trying rewriting the stub, rubber ducking with colleagues, writing alternative scenarios, I decided to get rid of the confirmation dialog that was shown to the user. This way I didn't need the `accept_confirm` and... tadaaa: it worked! My test was passing.

My theory was that `accept_confirm` executes in a different thread or something in which the stub is not defined (I know a theory can be proven wrong, but this one worked for me).  
One way to work around this is, instead of using `accept_confirm`, is 'overriding' the JavaScript's `confirm` function:

```ruby
# features/step_definitions/general_steps.rb

When('I delete the resource') do
  page.evaluate_script('window.confirm = function() { return true; }')
  click_on 'Destroy'
end
```


This way the DELETE request _is_ being stubbed, you can still show a nice confirmation dialog and your test will pass.  
(Of course you can, and probably _should_, recover the `confirm` function in this step after clicking 'Destroy', but I kept the code simple.)
