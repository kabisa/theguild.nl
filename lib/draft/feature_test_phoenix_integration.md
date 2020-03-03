# Using Feature Tests to Maximize Business Value

Keeping focus on providing value for the business is a crucial part in making sure stakeholders have confidence in you and your development team. In other words, if you want to keep your job, you better provide some value! The flipside of this is that I want to keep my development team happy so they'll keep on writing quality code they are proud of. Let's find out how to use our favorite tools (Elixir & Phoenix) and see how to make sure we deliver the value our stakeholders expect...

## User Story

I am a big proponent of using the scrum process to deliver software that adds value in small iterations. A tool that is used in this process is the concept of a user story. Writing a good user story should reveal what the business wants and should also indicate why the business needs certain functionality.

The form of a user story is mostly this: _As a [user of the application] I would like to [do a certain thing (mostly in the application)] in order to [provide certain value or solve a certain problem]_
Writing good and clear user stories is not a trivial task and once you have a good user story the next step might even be harder... Translating that user story into the code you are going to write as a developer. Luckily there are already great concepts and methods in the software industry that try to bridge that gap. One such process is the process of BDD (Behaviour Driven Development). Which basically means we build features from the outside In, meaning we start with a high level of what the app needs to do and granually start to fill in more details as we are building the feature.

## Acceptance Criteria using Gherkin

The way that I like to tackle the process of translating a user story into managable chunks to build is by defining a good set of acceptance criteria. It is often a good idea to write these with a product owner or stakeholder from the business, as they are the ones that are going to be accepting the story in the end. It is a feature that they have requested, right? I really like the [Gherkin language](https://en.wikipedia.org/wiki/Cucumber_(software)#Gherkin_language) to write up my acceptance criteria. If you have used the Cucumber testing framework in Rails land this will look very familiar.
This is the syntax Gherkin uses:

```gherkin
  GIVEN I have a certain state of the app
  AND also something else is true
  WHEN I do something
  AND I do something else
  THEN I expect this to happen
  AND also I expect this to have happened
```

Now let's get a practical example of this going so we can see this process in action. In the rest of this post I'll guide you through a practical example of building out a feature in Phoenix using this BDD approach.

## The Feature we are going to build

We'll build a feature for an app I'm working on at the moment. It is an app that provides tooling around supporting music teachers in teaching and managing their lessons. To make sure a teacher get's paid for teaching there is always some sort of agreement between a teacher and a student. In this lesson agreement there is a lot of detail about what kind of lessons a student will get (ie. private or in a group) and what the cost will be for a certain amount of lessons. So let's see if we can tackle this.

## A Bad User Story

Let's see an example of a really bad written user story first and see what we can do to improve this. You might find this example funny and unrealistic, but I can tell you that I have seen many occassions of user stories that have been thrown on a board that look similar to this one...

> Create contracts for everyone

So there is very little detail in this story and the main problem with that is the fact that it is widely interpretable to basically develop something that totally misses the intended feature a business needs. So let's improve.

> As a teacher I would like to be able to create contracts for my students so there is a mutual understanding of the agreed terms of me providing lessons to them

So let's review this. There is a lot of detail in this story. Let's evaluate the different parts:

```
* Is it clear who the intended target user is for this feature? => YES
* Is it clear what that user wants to be able to do? => YES
* Is it clear what the main purpose is of this feature?  => PARTLY
```

It might seem like this is a very good story, and in many aspects it is. But although the last part is written in great detail, let's take a step back and think about this. What is the goal a teacher has when creating a contract. Or, in a more general sense, what is the goal of a contract? Is that goal really to have a mutual understanding? That is not really the goal, but more of an aspect of a contract. So what is the real end goal? If you really think this through, there is a simpler and more concise end goal that is actually the essence of why contracts are needed. Check the story below and you'll see what I mean:

> As a teacher I would like to be able to create contracts for my students so that I don't have to worry about getting paid

## So why is this distinction important?

The main reason I think this distinction is important is this. When we know the true intent of what we are trying to solve, we might find other ways to solve that particular problem. To use this example, if the problem a teacher has is getting paid because they are constantly chasing their money, we could also solve that problem by creating a subscription based system. So the business owner asked for contracts because that is what teachers normally do when teaching, however that might not be the only option. For now I am going with this as I think it is the more simple approach to solve this problem. Building a subscription system is something I will probably tackle in the future, but I'd like to make sure we provide business value in small iterations and the first iteration for now will be about creating these contracts.

## Let's write some Gherkin

With one user story I often find myself writing a whole range of acceptance criteria using Gherkin. Let's start here with defining a few to get us going.

```gherkin
# Contract Listing
GIVEN I have a teacher account at studentmanager
AND I log in
AND I have an existing student
AND that student has a contract
WHEN I visit the page for this student
THEN I should see a list of contracts for this student
AND should see the specific contract for this student

# Adding a contract
GIVEN I am looking at the details for a student
WHEN I click on "Add Contract"
THEN I should be able to enter all the details needed to create a contract 

# Contract created flow
GIVEN I have entered all the details for a contract for a student
WHEN I create the entered contract
THEN I should be back at to the students overview page
AND I will see the contract just created
AND the students parent should receive an email with the details of this new contract

# Contract approval flow
GIVEN I am a parent of a student
AND I have received an email indicating there is a new contract
WHEN I click the link provided in the email
AND I log in after following that link
THEN I see a page where I can view the contract details
AND I'll be able to accept and approve the contract
```

So that's a good start. If you notice (like above here) that you have a lot of acceptance criteria for one story, it is usually a sign that it's probably best to split it up into more user stories. This way the original user story can become an Epic and you can add all the more fine-grained stories as part of this Epic. So the Epic would be: `Managing Student Contracts` and the stories below could be about `Listing COntracts`, `Adding a contract`, `Contract Created Flow` and `Contract Approval Flow`. Of course by now you would know how to make great user stories out of these short descriptions, right?

## Let's talk about tools 🧰

Let's find out how we can incorporate these user stories as tests in our project. On the Phoenix side I have been a huge fan of [Wallaby](https://github.com/elixir-wallaby/wallaby) for writing feature tests. However, I have experienced that when you have a lot of feature tests, your test suite can become a bit slow to run. So I use Wallaby when there is javascript in the frontent that needs to be executed. For server-side rendered content I have been meaning to try another project that recently got a significant update as well and that is [Phoenix Integration](https://github.com/boydm/phoenix_integration). When you don't need to execute javascript on the frontend, Phoenix Integration can be a great tool, because it tightly integrates with `Phoenix.ConnTest`, which means it is basically really fast for testing. I like!


## Let's BDD

Let's quickly setup `phoenix_integration` and get our first feature shipped using a BDD process!

Add package to `mix.exs`

```elixir
defp deps do
  [
    # ...
    {:phoenix_integration, "~> 0.6", only: :test}
    # ...
  ]
end
```

Setup our endpoint in `config/test.exs`

```elixir
config :phoenix_integration,
  endpoint: StudentManagerWeb.Endpoint
```

Add some boilerplate in `test/support/integration_case.ex`

```elixir
defmodule StudentManagerWeb.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use StudentManagerWeb.ConnCase
      use PhoenixIntegration
    end
  end
end
```

And let's write our first test. Notice I use the `@moduledoc` attribute here to add the acceptance criteria we wrote above. That is a nice way to document what you are actually testing here. You could also do the same for the individual tests by using the `@doc` attribute.

```elixir
defmodule StudentManagerWeb.ContractListingTest do
  @moduledoc """
  GIVEN I have a teacher account at studentmanager
  AND I log in
  AND I have an existing student
  AND that student has a contract
  WHEN I visit the page for this student
  THEN I should see a list of contracts for this student
  AND should see the specific contract for this student
  """
  use StudentManagerWeb.IntegrationCase, async: true
  alias StudentManager.Accounts
  alias StudentManager.Repo

  setup do
   {:ok, user} = create_teacher()
    Accounts.add_student(user.teacher, %{first_name: "Awesome", last_name: "student"})
    teacher = Repo.preload(user, teacher: :students).teacher
    student = teacher.students |> List.first()

    {:ok, lesson_type} =
      Accounts.create_lesson_type(teacher, %{
        name: "Private",
        group_size: 1,
        duration: 30,
        frequency: "weekly"
      })

    {:ok, contract} =
      Accounts.add_contract(
        student.id,
        teacher.id,
        %{start_date: ~D[2020-01-01], minutes: 300, lesson_type_id: lesson_type.id}
      )

    {:ok, conn: build_conn(), student: student, contract: contract, user: user}
  end

  test "View student contract listing", %{
    conn: conn,
    student: student,
    contract: contract,
    user: user
  } do
    conn
    |> get(Routes.pow_session_path(conn, :new))
    |> follow_form(%{
      user: %{
        email: user.email,
        password: user.password
      }
    })
    |> get(Routes.student_path(conn, :index))
    |> follow_link(student.first_name)
    |> assert_response(
      status: 200,
      path: Routes.student_path(conn, :show, student),
      html: "Contracts",
      body: contract.start_date |> to_string
    )
  end
end
```

So let's see what is going on here. You'll notice that my setup is pretty extensive. That is basically because this test is about seeing the list of contracts on the student detail page. Which means we'll need to have some content to be able to see it. In addition to this test, we could also make some variations that test that we'll show a message to indicate that there are no contracts when there are none added yet.

## Testing with authenticated users

I wanted to add a sidenote regarding testing with authenticated users. When I tested features with [Wallaby](https://github.com/elixir-wallaby/wallaby) I always used the method provided by [Pow](https://github.com/danschultzer/pow#testing-with-authenticated-users) to set the current user in the assigns like this:

```elixir
setup %{conn: conn} do
  user = %User{email: "test@example.com"}
  conn = Pow.Plug.assign_current_user(conn, user, otp_app: :my_app)

  {:ok, conn: conn}
end
```

Now I started out that same way and couldn't get this to work. Apparently when I made two consequent requests in my test pipeline, the assigns would get wiped. At first I was unsure if it was a bug or if it was just something I was doing wrong. So I added an issue to discuss it with Boyd(the creator of Phoenix Integration), and he did some digging and explained fully what was happening. You can see that discussion [here](https://github.com/boydm/phoenix_integration/issues/38). So the reason that just setting the current assign won't work, is because `Phoenix.ConnTest` actually wipes the assigns between each request. Basically mimicing stateless browser request behaviour. They call this recycling and is explained [here](https://github.com/phoenixframework/phoenix/blob/9f703bfec83a2f35102af7c9489ebb4a01c35f6a/lib/phoenix/test/conn_test.ex#L79). They do however carry over cookies that are set, so basically the solution was to actually login through the browser in my test.

In the example above I am login in directly in the pipeline, but you really don't want to do this all over the place if you add a lot of tests. In the [github issue](https://github.com/boydm/phoenix_integration/issues/38#issuecomment-593679075) Boyd also gives an example of how he does this mostly. Basically you can add a helper function in `ConnCase` you can call to sign in different types of users easily. For my example I'll leave it as for now.

## Conclusion

This was my first experience with the [Phoenix Integration](https://github.com/boydm/phoenix_integration/) library and I must say it is really nice to write integration tests like this. Did I mention it is extremely fast! I'm glad I finally got a chance to try it out and I want to shout out to [Boyd](https://github.com/boydm/) for his really fast and thorough help with my issue and for all his contributions to the Elixir community.

Hope you learned something new! (I sure did!)

Until next time!
