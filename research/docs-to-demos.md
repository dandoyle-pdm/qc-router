Everyone thinks PRDs reduce risk.

At Anthropic, they've eliminated them for most features.
Not because they're reckless. Because specs are now the risk.

Here's what they figured out that most companies haven't:

Catherine Wu (product lead at Anthropic) calls it "docs to demos."

They skip the PRD. Build a working prototype with Claude Code in hours. Ship it internally to everyone. Learn from real usage.

That's it. That's the whole process.

This sounds like "move fast and break things" but it's not.

It's a recognition that something fundamental changed:

When AI makes creation cheap, the bottleneck moves to verification.

And specs don't verify anything. Usage does.

Think about what a PRD actually is: a prediction.

"We think users want X. We think it should work like Y. We think these edge cases matter."

Then you spend weeks building to spec. Then you learn whether your predictions were right.

Anthropic flipped this.

Build the thing in hours. Ship it internally. Watch what actually happens.

The prototype becomes the spec. The usage becomes the research. The feedback becomes the roadmap.

Predictions replaced by observations.

Here's the part that makes this work:

70-80% of their technical staff ("ants") use Claude Code daily.
Not a beta group of 5 people. Everyone.
That's not dogfooding. That's distributed verification infrastructure.

Most companies have verification bottlenecks—a few reviewers, limited test capacity.

Anthropic turned their entire technical org into a verification system.

Every new hire increases validation throughput.

And here's where it gets recursive:

They build Claude Code features using Claude Code.

Every improvement to the tool improves how they build the next improvement.

That's not linear progress. That's compounding.

Artifacts? Started as a scrappy prototype demoed on "WIP Wednesdays."
Claude Code itself? Evolved from an internal tool (originally called Clyde/Clide) that got high adoption.
Neither was planned as a flagship product. Usage signal promoted them.

This inverts how most companies prioritize:
Traditional: Leadership decides what's important → Build it
Anthropic: Build many things → Adoption reveals what's important

The org reshapes around demonstrated value, not predicted value.

(Important caveat: They still use rigorous specs for safety evaluations, core model training, and enterprise deployments.
This isn't "move fast" everywhere. It's knowing which things need verification by building vs. verification by specification.)

Why can't you just copy this?

Because the process isn't the moat. The verification infrastructure is.

You need:

AI tools that make hour-scale prototypes good enough to learn from
Culture where everyone actually uses internal tools aggressively
Sophisticated users who generate signal, not noise

Most "dogfooding" is verification theater.
"Looks good in Slack" → check the box → ship

Real antfooding means production workloads on internal prototypes, daily, with continuous quantitative and qualitative feedback loops.

The companies that will win the next decade aren't the ones writing better PRDs.

They're the ones who've figured out that creation got commoditized and reorganized entirely around verification capacity.

Anthropic just showed us what that looks like.

The question to ask yourself:

Are you optimizing creation (better specs, faster writing, clearer requirements)?
Or are you optimizing verification (faster prototypes, more usage signal, tighter iteration)?
One of these is the old bottleneck. One is the new one.

Next exploratory feature, skip the spec. Build a working prototype in a day using whatever AI tools you have. Ship it to 10 internal people who will actually use it.

Watch what you learn in 48 hours vs. 2 weeks of planning.
