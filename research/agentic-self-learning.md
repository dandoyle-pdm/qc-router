Everyone says LLMs can't do true reasoning—they just pattern-match and hallucinate code.

So why did our system just solve abstract reasoning puzzles that are specifically designed to be unsolvable by pattern matching?

Let me show you what happens when you stop asking AI for answers and start asking it to think.

🧵

First, what even is ARC-AGI?

It's a benchmark that looks deceptively simple: You get 2-4 examples of colored grids transforming (input → output), and you have to figure out the rule.

But here's the catch: These aren't IQ test patterns. They're designed to require genuine abstraction.

(Why This Is Hard)

Humans solve these by forming mental models:

"Oh, it's mirroring across the diagonal"

"It's finding the bounding box of blue pixels"

"It's rotating each object independently"

Traditional ML? Useless. You'd need millions of examples to learn each rule.

LLMs? They hallucinate plausible-sounding nonsense.

But we had a wild idea:

What if instead of asking the LLM to predict the answer, we asked it to write Python code that transforms the grid?

Suddenly, the problem shifts from "memorize patterns" to "reason about transformations and implement them."

Code is a language of logic.

Here's the basic algorithm:

Show the LLM examples: "Write a transform(grid) function"

LLM writes code

Run it against examples

If wrong → show exactly where it failed

Repeat with feedback

Sounds simple, right?
But that's not even the most interesting part.

When the code fails, we don't just say "wrong."
We show the LLM a visual diff of what it predicted vs. what was correct:

Your output:
1 2/3 4 ← "2/3" means "you said 2, correct was 3"
5 6/7 8

Plus a score: "Output accuracy: 0.75"

It's like a teacher marking your work in red ink.

With each iteration, the LLM sees:

Its previous failed attempts

Exactly what went wrong
The accuracy score
It's not guessing. It's debugging.
And here's where it gets wild: We give it up to 10 tries to refine its logic.
Most problems? Solved by iteration 3-5.

But wait, it gets crazier.

We don't just run this once. We run it with 8 independent "experts"—same prompt, different random seeds.

Why? Because the order you see examples matters. Shuffling them causes different insights.

Then we use voting to pick the best answer.

After all experts finish, we group solutions by their outputs.
If 5 experts produce solution A and 3 produce solution B, we rank A higher.

Why does this work? Because wrong answers are usually unique. Correct answers converge.

It's wisdom of crowds, but for AI reasoning.

Each expert gets a different random seed, which affects:

Example order (we shuffle them)

Which previous solutions to include in feedback

The "creativity" of the response

Same prompt. Same model. Wildly different exploration paths.

One expert might focus on colors. Another on geometry.

Our prompts are elaborate.

We don't just say "solve this." We teach the LLM how to approach reasoning:

Analyze objects and relationships

Form hypotheses (start simple!)

Test rigorously

Refine based on failures

It's like giving it a graduate-level course in problem-solving.

Here's why code matters:
When you write:

def transform(grid):
return np.flip(grid)

You're forced to be precise. You can't hand-wave.

Code doesn't tolerate ambiguity. It either works or it doesn't.

This constraint makes the LLM think harder.

Oh, and we execute all this code in a sandboxed subprocess with timeouts.

Because yeah, the LLM will occasionally write infinite loops or try to import libraries that don't exist.

Safety first. But also: fast failure = faster learning.

ARC-AGI isn't about knowledge. It's about:
Abstraction (seeing the pattern behind the pattern)

Generalization (applying a rule to new cases)

Reasoning (logical step-by-step thinking)

We're not teaching the AI facts. We're teaching it how to think.

So did it work?
We shattered the state-of-the-art on ARC-AGI-2.
Not by a little. By a lot.
Problems that stumped every other system? Solved.
And the solutions are readable, debuggable Python functions.

You can literally see the AI's reasoning process.

This isn't just about solving puzzles.

It's proof that LLMs can do genuine reasoning if you frame the problem correctly.

Don't ask for answers. Ask for logic.
Don't accept vague outputs. Demand executable precision.
Don't settle for one attempt. Iterate and ensemble.

Which makes you wonder:

What else are we getting wrong about AI capabilities because we're asking the wrong questions?

Maybe the limit isn't the models. Maybe it's our imagination about how to use them.

Here's what you can steal from this:
When working with LLMs on hard problems:
Ask for code/structure, not raw answers
Give detailed feedback on failures
Let it iterate
Run multiple attempts with variation
Use voting/consensus to filter noise
Precision beats creativity.

The most powerful pattern here?

Treating the LLM like a reasoning partner, not an oracle.

We're not extracting pre-trained knowledge. We're creating a thought process—prompt → code → test → feedback → refined thought.

That loop is where the magic lives.

If you're working on hard AI problems, stop asking:
"Can the model do X?"

Start asking:
"How can I design a process that lets the model discover X?"

The future of AI isn't smarter models. It's smarter prompts, loops, and systems around them.
