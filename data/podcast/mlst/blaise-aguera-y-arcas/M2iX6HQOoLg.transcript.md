---
title: What If Intelligence Didn't Evolve? It "Was There" From the Start! - Blaise Agüera y Arcas
duration: 3348
upload_date: 20260216
channel: Machine Learning Street Talk
url: "https://www.youtube.com/watch?v=M2iX6HQOoLg"
transcript_source: https://app.rescript.info/public/share/ff7gb6HpezOR3DF-gr9-rCoMFzzEgUjLQK6voV5XVWY
description: |
  Blaise Agüera y Arcas presenting at ALife 2025 — the most technically detailed public walkthrough of the ideas in his *What is Life?* and *What is Intelligence?* books that we've come across.
  He covers the BFF experiments (self-replicating programs emerging spontaneously from random noise), the mathematical framework connecting Lotka-Volterra population dynamics with Smoluchowski coagulation, eigenvalue analysis of cooperation matrices, and his central claim that symbiogenesis — not mutation — is the primary engine of evolutionary novelty.
  The experimental results are genuinely striking: complex self-replicating code arising from random byte strings with zero mutation, a sharp phase transition that looks like gelation, and a proof that blocking deep symbiogenetic ancestry trees prevents the transition entirely.
  A few things worth flagging for critical viewers:
  — The substrate is more carefully engineered than the framing sometimes suggests. The choice of language, tape length, interaction protocol, and step limits all shape what emerges. Their own SUBLEQ counterexample (where self-replicators *don't* arise despite being theoretically possible) highlights that these design choices matter substantially — and a general theory of which substrates support this transition is still missing.
  — The leap from "self-replicating programs on fixed-length tapes" to "life was computational and intelligent from the start" involves significant philosophical extrapolation beyond what the experiments directly demonstrate.
  — The Bedau et al. (2000) open problems paper he references at the start actually sets a higher bar for Challenge 3.2 than BFF currently meets: it asks that "the internal organization of these 'organisms' and the boundaries separating them from their environment arise and be sustained through the activities of lower-level primitives" — whereas BFF's tape boundaries are fixed by design, not emergent.
  ---
  TIMESTAMPS:
  00:00:00 Introduction: From Noise to Programs & ALife History
  00:03:15 Defining Life: Function as the "Spirit"
  00:05:45 Von Neumann's Insight: Life is Embodied Computation
  00:09:15 Physics of Computation: Irreversibility & Fallacies
  00:15:00 The BFF Experiment: Spontaneous Generation of Code
  00:23:45 The Mystery: Complexity Growth Without Mutation
  00:27:00 Symbiogenesis: The Engine of Novelty
  00:33:15 Mathematical Proof: Blocking Symbiosis Stops Life
  00:40:15 Evolutionary Implications: It's Symbiogenesis All The Way Down
  00:44:30 Intelligence as Modeling Others
  00:46:49 Q&A: Levels of Abstraction & Definitions
  ---
  REFERENCES:
  Paper:
  [00:01:16] Open Problems in Artificial Life
  https://direct.mit.edu/artl/article/6/4/363/2354/Open-Problems-in-Artificial-Life
  [00:09:30] When does a physical system compute?
  https://arxiv.org/abs/1309.7979
  [00:15:00] Computational Life
  https://arxiv.org/abs/2406.19108
  [00:27:30] On the Origin of Mitosing Cells
  https://pubmed.ncbi.nlm.nih.gov/11541392/
  [00:42:00] The Major Evolutionary Transitions
  https://www.nature.com/articles/374227a0
  [00:44:00] The ARC gene
  https://www.nih.gov/news-events/news-releases/memory-gene-goes-viral
  Person:
  [00:05:45] Alan Turing
  https://plato.stanford.edu/entries/turing/
  [00:07:30] John von Neumann
  https://en.wikipedia.org/wiki/John_von_Neumann
  [00:11:15] Hector Zenil
  https://hectorzenil.net/
  [00:12:00] Robert Sapolsky
  https://profiles.stanford.edu/robert-sapolsky
  [00:29:30] Marian Smoluchowski
  https://en.wikipedia.org/wiki/Marian_Smoluchowski
  Book:
  [00:06:15] What is Life?
  https://mitpress.mit.edu/9780262554091/what-is-life/
  [00:19:45] What is Life? How Chemistry Becomes Biology
  https://amazon.com/dp/0199641013
  Technical Concept:
  [00:15:45] Brainfuck
  https://esolangs.org/wiki/Brainfuck
  ---
  LINKS:
  RESCRIPT: https://app.rescript.info/public/share/ff7gb6HpezOR3DF-gr9-rCoMFzzEgUjLQK6voV5XVWY
---

## Table of Contents
- 0:00 – BFF Abiogenesis Experiment
- 0:00 – Origin of Life Problem
- 0:02 – Arrow of Complexity and Evolutionary Transitions
- 0:02 – Intelligence and Theory of Mind
- 0:03 – Life as Embodied Computation
- 0:24 – Population Dynamics and Mathematical Frameworks
- 0:27 – Symbiogenesis as Engine of Evolution

## BFF Abiogenesis Experiment

**Blaise Agüera y Arcas:** After a few million interactions, magic happens, which is that you go from noise to programs. You start to see complex programs appear on these tapes. This is the most exciting plot that I've made in the last few years and it's the 1 that's on the cover of [00:00:00]

## Origin of Life Problem

## Arrow of Complexity and Evolutionary Transitions

## Intelligence and Theory of Mind

## Life as Embodied Computation

the book. You can see that in the beginning, it's not very computational and then a sudden transition takes place here. It looks like a phase transition. This is the book that I hear is making the rounds at Sarkana, which I'm very happy to hear. The big 1 [00:00:15]

## Population Dynamics and Mathematical Frameworks

## Symbiogenesis as Engine of Evolution

on the right, What is Intelligence? Is sort of the Lord of the Rings and What is Life? On the left is kind of The Hobbit. So it's kind of the single and it's also chapter 1 of of what is intelligence. So it goes kind of inside the other 1. Mostly what I'll be talking about today [00:00:30]

is what's in these 2 books but with, with quite a bit more detail, more mathematical detail since I think this is a really good audience for that. And I'll also be connecting it, a bit with some of the bigger themes of the ALife conference and community [00:00:45]

and dare I dare I say even movement. You know, in particular, I I actually wanted to begin with this wonderful sort of open problems in artificial life, summary paper which, you know, has a number of of very illustrious co authors of, you know, [00:01:00]

at least 1 of whom we heard from yesterday and and more than 1 of whom are are are here at the conference. This is, you know, open problems, 14 open problems in artificial life in the year 2000. How does life arise from the non living? How does the transition to life in an [00:01:15]

artificial chemistry or in a silica environment can occur and why it occurs? I'm sure many of you know this was the the problem that bedeviled Darwin. You know, he made 1 of the most rich and and explanatorily powerful theories [00:01:30]

in ever in science in in discovering how evolution works, but he was unable to explain how evolution got started. He, at some point in 1 of his letters, said, you you might as well talk about the origin of matter. I think that the origin of matter and the origin of [00:01:45]

life might actually be 1 and the same thing and evolution might actually be the answer to that question but it's an evolution that includes a term that Darwin did not account for in his original formulation. In section b of these questions, determine what is inevitable [00:02:00]

in the open ended evolution of life. I'm I'm hoping to speak a little bit about that too. Create a formal framework for synthesizing dynamical hierarchies at all scales and develop a theory of information processing, information flow, and information generation [00:02:15]

for evolving systems. I won't be going into the information theory in any detail, but, but hopefully we'll we'll set up the problem in in a perhaps somewhat new way that that I I hope will help to do that. And [00:02:30]

finally, in section c, how is life related to mind, machines and culture? If I have time, I will get into this as well and talk a bit about the emergence of intelligence and mind in an artificial living system and, the influence of machines on the next major evolutionary [00:02:45]

transition of life. So, you know, it was really cool to to read this paper from 2020 and to see how much of the perspective, that that, that you had already been exploring then, you know, feels, you know, right [00:03:00]

and consistent with, you know, with with a sort of fresh look at this at these problems in 2025. Let me just begin with, with this question of souls. It used to be in the nineteenth century and and earlier, that we thought that, life had some vital force or spirit, that [00:03:15]

animated it and made it different from inanimate matter. In the nineteenth century, when we began to figure out organic chemistry and be able to synthesize urea and so on, the the idea that that no, we should really adopt a strictly materialist perspective because there's nothing special [00:03:30]

or different about the matter in us versus the matter anywhere else in the universe, took hold. And that's progress for sure, but, but it also, you know, when we when we embrace atoms and materialism fully, we're left with some, some questions about, [00:03:45]

you know, what differentiates life from non life then. You know, like, what can we even say about life? There are at least some biologists who who say, well, maybe it's not even meaningful to talk about about any difference between life and non life. But I I don't think that that's true. And I think that the answer to the to the conundrum [00:04:00]

is to invoke function. Function is the thing that life has, that non life doesn't have. In other words, if we, you know, just to to give you a little parable, if I were to come back from the future with this object and you ask me what it is, and I tell you it is an artificial [00:04:15]

kidney with 100 year lifespan. You can implant it in a body and it'll it'll, you know, it'll work the way your kidneys do. It'll it'll filter urea from the blood and so on. That's a really important piece of information, but it's not a material or a materialist piece of information. It's not something that you [00:04:30]

could read off from the atoms. And, you know, those atoms could be, I don't know, tungsten filaments or carbon nanotubes are made out of some technology we don't understand now, or it could be organic, it could be made out of cloned tissue. And and the point is that it working as a kidney [00:04:45]

doesn't depend on that matter. There is a kind of separation of concerns between the matter and the function. And so there's some real sense in which the function is like a spirit or like something like something immaterial, it's not material, and yet it also relies of course on [00:05:00]

the physics of what's going on. You can't have the spirit without the matter as it were. So function is really important and, and function is something that, you know, a rock on a non living planet, somewhere doesn't have. You know, if you if you [00:05:15]

break a rock on a non living planet, you now have 2 rocks. You don't have a broken rock. If you break a kidney, you now no longer have a working kidney. That's the difference between something functional and something non functional. This idea of function was formalized by Alan Turing, who never intended [00:05:30]

the Turing machine to actually be built, when he wrote it in 1936, but there is 1 that was built by Mike Davy in 2010. I don't need to review Turing machines with all of you, of course. You you all know how they how they work. But I do want to review briefly von [00:05:45]

Neumann's update to Turing's thinking about computation, which which he did a few years later. This was published posthumously after von Neumann died. But the idea behind behind von Neumann's thinking is he was trying to answer the same question that Schrodinger had quite [00:06:00]

had asked in his What is Life book? And in particular, he was trying to ask the question, if you have a robot that is swimming around, on a, you know, in a in a pond and the pond has lots of loose Legos around. There were no I don't know if there were Legos in 1950, but [00:06:15]

let's pretend there were Legos in 1950. And the job of the robot is to assemble those Legos into a new robot like itself. You know, there's something a little bit mysterious about that. It feels a little bit like pulling yourself up by your own bootstraps or like a paradox. And so he asked, what does it take for something to be able to make [00:06:30]

something like itself? Which seems, hard, almost paradoxical. And his conclusion was, well, you need to have instructions for how to make a mi. You need to have a tape with instructions for how to make a mi, and you need to have a universal constructor [00:06:45]

that will follow the, the instructions on that on that tape in order to assemble the necessary parts. You also need to have a tape copier, so that you can give your offspring, another copy of that tape. By the way, the tape has to also include the instructions for making the universal constructor and [00:07:00]

the tape copier. If those things all hold, then you have life. You have something that can build itself. And, what's what's so profound about about von Neumann's insight, I mean, first of all, he predicted all of this before we knew the structure and function of DNA, [00:07:15]

before we we understood what ribosomes were or discovered DNA polymerase. So he called it exactly right. Those all of those things really do exist, inside cells and he figured this out from pure theory, never having set foot in a bio lab. The the profound insight is that he said, by the way, a universal constructor [00:07:30]

is a universal Turing machine. Those are literally 1 and the same thing. And by by making that observation, what he discovered was that life is literally embodied computation. It is computational. You cannot have life without having computation. So [00:07:45]

obviously not everything that is alive reproduces, but everything that is alive has to be able to make itself. It has to be able to do some combination of healing, growing, maintaining itself, reproducing. All of that is autopoiesis. All of that involves self construction and all of that necessarily involves [00:08:00]

a universal constructor. Now, what do I mean by embodied computation? This is a really important distinction between Von Neumann and Turing. In Turing, the symbols that the that the head writes are different from the head itself and the tape [00:08:15]

and, and the table of rules that the that the head follows. Whereas in von Neumann, it's it's more like a 3 d printer. The the memory is atoms, not abstract symbols. In other words, you know, you could think about a Turing machine as like this laptop, you [00:08:30]

know, which can't extrude another laptop out the side. But a von Neumann replicator is like a combination of a laptop and a 3 d printer that can print another laptop. So its memory is actually atoms. That's what I mean by embodied. So I don't mean embodied in the ways that a lot of roboticists [00:08:45]

talk about embodied. I mean that that there is a closure between the the medium in which the computation happens and the thing that is actually doing the computation. That's the key. So computation that is embodied in that sense and that is autopoietic is alive. [00:09:00]

You can't reproduce non trivially, evolvably without without computation. No computation, no life. I do wanna say a word briefly about what I mean by computation and in this I'm following the the work of, Susan Stepney, Dominic Horseman, Rob Wagner, [00:09:15]

Viv Kendon. This is from a nice paper they wrote in 2023 relating, the evolution of a physical system and the computation that it does. So, you know, on top you have logical gates, on the bottom you have, you know, transistors [00:09:30]

in your computer. This is important because, you know, there's there are no bits in a computer, there are just voltages that go up and down. In fact, even the voltages are an abstraction of something further, you know, if we go further down. But, you know, the the point is that you have to coarse grain those voltages [00:09:45]

into bits and then you have to have a logical machine that talks about how those bits evolve, what are the what are the what are the computational processes that those bits undergo, and there's a mapping from the physical system to the logical system and vice versa. When we say something computes, [00:10:00]

what we mean is that it is possible to construct such a mapping and that therefore as the physical system evolves, that is equivalent to the logical system evolving. So, you know, there are some caveats. You can have stochastic computation in which there's a little bit of randomness injected so it doesn't [00:10:15]

have to be fully deterministic. Another really important caveat is that you don't want that description to be infinitely complex. Otherwise, you could have the trivial case of saying like, you know, the water in the SEN is a computer and the longer my computation, I just need to make my description longer and longer in order to match. No. That doesn't [00:10:30]

work either. You need a kind of a Occam's razor, description that, for it to be valid. But this is a good definition of computation, but it emphasizes that there's something subjective about computation. You need to have a model for how the, how the physical system [00:10:45]

translates into the logical system in order for any of this stuff to work. There are implications about entropy, free energy and heat and so on in this model. And in particular, you as you all know, we've talked already, you know, Hector Zenil in his very elegant, talk of a [00:11:00]

couple of days ago talked about, and actually Chris Kempis also talked about the Landauer limit, and the fact that in a computational system you're constantly reducing the entropy of of your state space and in doing so you therefore require free energy. So, you know, you need [00:11:15]

to have free energy available and you need to eject waste heat. The exception in a way only proves the rule which is reversible computation. In reversible computation you generate ansyllabits and, and that's equivalent to just saying there's no exhaust But, you know, then you either have [00:11:30]

to keep on making your computer bigger and bigger and bigger as you accumulate these ancillibits or you have to, shrink what you consider to be the computer and then you're back to reversible to to non reversible computation once again. 3 important fallacies that I wanna point out before continuing. 1 of them I will call [00:11:45]

the Sapolsky Era. Robert Sapolsky, you know, has written famously about, people not having free will, because we're built on physical systems. You know, the physics is is, you know, if you like deterministic, let's set aside quantum mechanics and stuff like this. [00:12:00]

Let's imagine we live in a Newtonian universe. It's fine. It's good enough. The point is that physics is reversible. All of the basic physics that we understand, whether that's Newton's equations, Maxwell's equations, Einstein's equations, quantum mechanics, all of those [00:12:15]

are essentially time reversible. So you can move them either forward or back. Computation is not reversible. When I add, you know, 3 plus 5 to get 8, once I've got the 8, and I've, you know, haven't kept my ancillips around, let's say, I no longer [00:12:30]

know what was added in order to make the 8. Computation is inherently irreversible. And so to say that what is true of the physical system is also true of the of the computational system or the logical system is is not is not the case. And, reversibility would be 1 trivial example of [00:12:45]

how that is not the case. Causation, by the way, only makes sense in the light of irreversibility. Right? So if you have a purely physical system, then, you know, to say that a causes b is equivalent to saying that b causes because everything is kind of a block universe, you like, in that [00:13:00]

kind of setup. But in computation, you can talk about causality because there are ifs and thens in there. And this once again connects with the way Hector was talking about how essentially nothing in nothing in causation makes sense except in the light of computation, [00:13:15]

which I fully agree with. Another fallacy, we could call the the early Wittgenstein error. If we say something like birds exist in the world, line 1 of the Tractatus Logical Philosophia, you didn't say birds, but whatever. You can't say birds exist or birds [00:13:30]

don't exist in a way that is independent of a model of the universe. There are no birds in physics. There are no birds in this underlying dynamical system. When we start talking about birds, we already are talking about having some kind of some kind of model. And once we start talking about models, you've [00:13:45]

got causality, reversibility, all kinds of other irreversibility, all kinds of other things in play, and none of these statements are are are airtight. They all rely on on an observer. This is kind of Kant as well, I [00:14:00]

guess. And this leads to the the early Leibniz error, or the same error that the good old fi the good old fashioned AI practitioners had, which is that intelligence could be carried out by just having a series of programs of strictly logical deductions [00:14:15]

or inductions. That doesn't work. This is why good old fashioned AI never panned out. The reason is that that you can't start out with, like in math, with propositions that are self sufficient. Even math is not self sufficient, but let's pretend [00:14:30]

for a moment and just move from there and kind of do an algebra in order to work various things out. When when your propositions are not airtight when and you're looking only at regularities and patterns, this good old fashioned AI idea simply cannot work. That's that's why we never got it to work. Let's move [00:14:45]

now to to some of the artificial life experiments that that that I began playing with in at the 2023 and my team and I published in June 2024, so just about a a year ago. I think some of you many of you perhaps have heard of these. They're in [00:15:00]

the What is Life books and I've talked about them a few times. The the basic setup here is to try and get self replication to get, you know, abiogenesis, the emergence of life from non life to happen in a purely artificial life system. Okay. [00:15:15]

So the setup is to begin with a minimal Turing complete language, I used brain fuck, because I I really liked the idea of being able to talk at a conference and say brain fuck over and over and I'm fundamentally 12 years old on the inside. [00:15:30]

But but also because it's it's, it it very closely models, the Turing machine. You know, it's it's a it's a minimal programming language. Only only 8 instructions that, that looks very Turing machine like and moves the head back and forth. I should say that in its original version, brain [00:15:45]

fuck is not embodied computation. It has basically a separate data tape and code tape, and that means that it cannot make a copy of itself. So I I made a couple of modifications to brain fuck that actually reduce it from 8 instructions to 7 in order to make it embodied, [00:16:00]

meaning that as it works on the tape, it is able to read its own code and write and write its own code on that tape as well. There's no separate console. There's no separation between the data tape and the, and the instruction tape. For those of you who are unfamiliar with Brainfuck, there is Hello World in it. [00:16:15]

I'm sure you've already figured out how it works by just looking at the program. I actually still haven't, I have to admit. By the way, this is actually the French brain fuck page because I thought it was better, but translated into English. It's funnier to read it that way. These are these are the 8 instructions. You know, the first 4 [00:16:30]

are move the head 1 step to the left, 1 step to the right, increment the bite at the head, decrement the bite at the head. We're already halfway through. There is an input and output instruction, which in this case really just copy from from 1 head to another. And there are jump instructions, open open bracket and close [00:16:45]

bracket in order to be able to be able to make loops. And that's it. That's all that's all brain fuck is. So how does how does the Alife experiment work? The Alife experiment is called BFF. The first BFF stand for brain fuck and the second F, you can draw your own conclusions. [00:17:00]

But, you start off with with a soup of of, I I actually generally use just 1,000, 1,024 tapes. That's enough for this experiment. So the tapes are of fixed length. They're of length 64, and [00:17:15]

they begin random. So just random bytes. Now, if a tape is random bytes, that means that only 1 in 32 of them or so are even valid instructions. Most of them are no ops. A no op will just be skipped over, like in most, programming languages. So, so [00:17:30]

this is what those tapes look like in the beginning and you can see that, you know, the, I'm not printing the no ops, right, so that's all the blank space. The the operations are quite sparse. On any given tape, you only have an average of 2 instructions or so. And then the procedure is to pluck 2 of these tapes out [00:17:45]

of the soup at random, concapenate them end to end so you have 1 28 bytes, and then run. And then after running, pull them back apart and put them back in the soup and repeat. That's it. So it's just that over and over. That's the entire [00:18:00]

experiment. So I'll show you what happens on my laptop. After a few million interactions, magic happens, which is that you go from noise to [00:18:15]

programs. You start to see complex programs appear on these tapes. This is quite wonderful, because these programs take, you know, they take real effort to reverse engineer. When you when you study them, you know, you you it's like studying that hello world program. You have [00:18:30]

to, know, they they're they're functional in the sense that they really do something, and it's not trivial to figure out how they work in order to do that. Okay. What are they doing? Well, they're definitely copying themselves or each other somehow. We know that because, if, you know, this is a histogram and you can see, you know, in this [00:18:45]

case there were 8,000 tapes, there are 5,000 of the top 1, 297 of the next 1 and so on. So there's clearly copying going on and there's this ecology of programs all copying each other, which is which is just wonderful to see. I mean, that's that's that, you know, emergence of of, of life in this [00:19:00]

very functional minimal sense from randomness. A part of this is very easy to understand. You know, why why do these things emerge? Well, because something that copies itself will be around forever and something that doesn't copy itself will be copied over by something that can copy [00:19:15]

itself. So inherently, something that can copy itself is more stable than something that cannot copy itself. So it's really just the second law of thermodynamics, but but doing something unexpected, which is creating something more complex because it's more stable, rather than something less complex [00:19:30]

which is less stable. This idea that stability doesn't necessarily mean, mean low complexity was worked out in some detail by Adi Pross, the organic chemist in another book called What is Life? He calls it dynamic kinetic stability, meaning usually we think of stability only [00:19:45]

in terms of fixed points in a phase space, but a cycle can be even more stable than a fixed point. Of course, for these cycles to work, need an input of free energy, but, you know, for reasons that we've already gone into. Okay. So mystery mostly solved, but actually mystery [00:20:00]

not fully solved, for reasons that I will that I will, show in a second. But but just to give you a sense of what of of what this transition looks like from non life to life, it's very dramatic. In the beginning, you know, these interactions, only involve know, there are only a few instructions in the soup. It's [00:20:15]

a Turing gas as Walter Fontana would have called it. When you do the join and you run, only 2 operations run-in any given interaction on average, as as you'd expect. And that's what it looks like by the end in this particular run, and 13 [00:20:30]

74 operations on average are running per interaction, so the soup has become intensely computational. There's been a transition here and there's a lot more code, than than 1 in 32, bytes as you can see. This is what that looks like visually. This is the most exciting [00:20:45]

plot that I've made in the last few years and it's the 1 that's on the cover of the book. So what I've drawn here are 10,000,000 dots. It's a scatter plot of interactions. The x axis is time and the y axis for every dot is how many computations took place, how many operations took place in [00:21:00]

that interaction. You can see that in the beginning, it's not very computational and then a sudden transition takes place here at 6,000,000 interactions and it becomes intensely computational. It looks like a phase transition. In fact, it is a phase transition. You can also see that [00:21:15]

in the the entropy of the soup. So here I'm just I'm just estimating the entropy of the soup by zipping it and looking at the size of the zip relative to the, to the whole thing. You can use any compression algorithm you like. In the beginning, it's uncompressible, so it's a gas, [00:21:30]

you know, in that Turing gas sense because all the bytes are random. And you can see that there's a dramatic change and suddenly it becomes extremely compressible right at that transition moment. And of course, this becomes compressible because there everything is copying, right, itself and each other, so if things are copying themselves, then they'll then [00:21:45]

we know that they'll become very compressible. But it's cool because if we think about what the phase of matter is on the left, it is just like a gas, nothing is correlated. What would we call the phase of matter on the right? It's not a liquid, it's not a solid. Right? It has structure and it has structure at every [00:22:00]

scale. I think you have to call that phase of matter life. That's it's a functional phase of matter. It means that that it it that its parts are different from its other parts and if you zoom in or out, you see more structure. It's what David Wolpert would [00:22:15]

call self dissimilar. It's not a fractal, it's more like a multifractal. I'll explain why in a moment. Okay. How long does it take this transition to happen? Well, the the answer is it looks more or less like an Erlang distribution or, a little bit more [00:22:30]

precisely like this distribution they call a lockpick distribution, which imagines that there are steps have to be undertaken and those steps have a long tail distribution of difficulty. And how many steps does it take? Well, the answer is 12. It takes 12 steps. Just like getting [00:22:45]

sober, I suppose. This is a fit of the empirical to the Erlang and the lockpick distributions. A little hard to see, but the lockpick is a bit better than Erlang. Erlang assumes Poisson, lockpick assumes long tailed. But it's a process phase distribution. And and what this tells you is that there [00:23:00]

are stepping stones here. You know, you can't get that transition to life immediately, so something interesting must be going on here on the left other than just randomness. It takes multiple things happening in order to get to that point. You know, in this case, you know, it happens somewhere between [00:23:15]

1,000,000 and, let's say, 7,000,000, interactions. Okay. So, this all suggests that pretty much any universe, by the way, that has a source of randomness, and can support computation, will evolve life, you [00:23:30]

know, for this simple dynamical stability reason. But the big mystery is why does why does it appear to continue to get more complex over time? You might have seen my little video that, you know, we saw some programs emerge and then we saw the pro we saw them sort of densify. More [00:23:45]

instructions appeared. And and even more fundamentally, why does this work even without mutation? I didn't mention, but, you know, in the original version of BFF, I added some random mutation because, you know, we're all taught in school that the way the way evolution works [00:24:00]

is chance and necessity. You know, you mutate things, you're sort of throwing spaghetti at the wall. Whatever sticks is what is what does better, and so you need a source of spaghetti. But if you do this entire experiment with the mutation rate cranked all the way down to 0, you still get the same exact phenomenon, [00:24:15]

and that is very mysterious. Because if you crank mutation down to 0, you should have no source of novelty, you should have no evolution. Why do you still get this apparent complexification even with 0 mutation? So let's let's go into some of the some of the theory of this. By [00:24:30]

the end, we have a replicating entity. It can engage in standard sort of population evolution dynamics. This is the kind of of differential equation that that 1 generally writes for this sort of thing. It's a very general ansatz. This is for, you know, species [00:24:45]

I. Let's say they're n species. They could be chemical species, they could be biological species, whatever. Here's a classic example of of such an ansatz. This is the the Lotka Volterra equations for predator and prey, which I'm sure, many of you are very familiar with. They were [00:25:00]

co invented or or invented independently by, Alfred Lotka and Vito Volterra near the beginning of the twentieth century. This is what the classic Lotka Volterra equations look like. There are 2 species. There is a prey species and a predator species. And those 4 terms are, reproduction, [00:25:15]

getting eaten, eating to reproduce and background death rate. So, if you've got those 4 terms, you get these nice oscillatory solutions, you know, between between your predators and your prey that arise. Okay. So this is a slightly more [00:25:30]

general form of those Lotka Volterra equations. There is a linear part which we'll call r x and, in Lotka Volterra that linear part is diagonal. So, you know, the the, the wolf can't turn into a rabbit, the rabbit can't turn into a wolf, so so the reproduction is diagonal. [00:25:45]

And then there's also a bilinear term, which is the the part where predation, competition and the fact that niches are finite, gets implemented. So the the the right part is suppressive. The left part makes things grow. The right part makes things, squish squish down, keeps [00:26:00]

them finite. But this can't be the whole story of evolution. Why can't it be the whole story of evolution? Well, of course, because it's closed ended. You know, we only have 2 species here. It doesn't matter how long you run this damn thing, you're not gonna get a third species. And and [00:26:15]

you're not going to change the design space either. You can have, you know, very complicated terms in here that allow finch beaks to adapt to different environments, but you have to have the space of finch beaks predefined before before this equation can [00:26:30]

even be made to work. So this doesn't, you know, this doesn't answer the question of how evolution gets started. It doesn't answer the question of what happens afterward other than optimization to niches. So now we bring in another Eastern [00:26:45]

European, Dmitry Sergeyevich Mereshkovsky. So he's the 1 who first came up with the idea that maybe mitochondria engaged in some kind of semogenetic event in order to end up inside other single celled organisms to make, to make eukaryotes. This [00:27:00]

was popularised and proven to actually be the case by Lin Margulis, in in 1968. 1 of the really great papers in biology from the twentieth from the twentieth century. I'm sure many of you are familiar with. This is that paper, sorry, 1966 on the [00:27:15]

origin of mitosing cells. So she's the 1 who proved, that eukaryotes were actually a fusion between 2 different kinds of prokaryotes and popularized this term that Medichevsky had invented, symbiogenesis. Okay. So could symbiogenesis be happening as a as a source of novelty [00:27:30]

in BFF? Yes. That is the source of novelty in BFF and indeed that is the source of novelty in evolution period. This is something that Lyn Margulis believed, but, that was not, that had not been widely accepted by the by the by the biology community [00:27:45]

even by the time of her death, in 2011. You know, so she she had a much more expansive idea about about why symbiogenesis was important. Only the particulars of chloroplasts and mitochondria had been accepted. So the way we can look for [00:28:00]

symbiogenesis in BFF is to look for replicators emerging before that phase transition. And if you look for them, if you just look for stretches of bytes that are getting copied during those interactions, you find such stretches of bytes. They begin short and [00:28:15]

kind of crappy, unreliable. But they're there from the beginning. Every time you have a single copy instruction after all, 1 byte is getting copied from somewhere to somewhere, so almost by definition, you have at least 1 byte long sequences that are getting copied right from the beginning. So [00:28:30]

let's just call them replicators. Right? There are replicators there from the beginning. Now, if you have these 1 byte replicators that are copying themselves back and forth now and then, once in a while, they will come into conjunction, and 2 of them will copy [00:28:45]

better as a group than the 2 of them copied on their own. When that happens, then they'll start to copy as a group and that is a symbiogenetic event. So basically, the reason that even without mutation you get these complex programs arising [00:29:00]

is because of these fusion events between smaller replicators. So can 1 build syngogenesis into an equation like like this 1 that, you know, for for Lotka Volterra? You can. This is our statistical physicist who came up with the [00:29:15]

right kind of term to write mathematically for describing how symbiogenesis works. He wrote down an equation for the coagulation of polymers. So this is Smolowski coagulation. This is what happens when clouds form. It's what happens when gelatin [00:29:30]

sets in the fridge. So the idea is that you have, let's say, polymers that begin, as monomers, you know, 1 monomer, another monomer, they they stick together, and now you have a dimer. And now the dimer and maybe another monomer stick together and you have a trimer. 2 trimers [00:29:45]

stick together and now you have a hexamer and so on. These are the equations for that. This is the mass balance equation. It's it's very simple. There's a merger gain term and a merger loss term. The merger gain term, which scales like the densities of the 2 things that are coming together, and [00:30:00]

the product of those with some merger kernel, k, is increasing the population of cluster k, which is of length I plus j. And then you have to do the balance of that every time you have 2 things coming together to make a new 1, you have to then subtract their populations I and j and that's [00:30:15]

what the right hand side is about, it's the loss of things that have merged. So you put those 2 things together and you get a stochastic differential equation for mergers in a solution. And by the way, there is a phase transition associated with [00:30:30]

small hosky coagulation. It's called gelation and it's exactly what happens when you put jello in the fridge and it sets. Basically, things are sticking together and if they stick together with a scaling exponent that is greater than 1, then you get this finite time singularity in which the [00:30:45]

the the things that stick together diverge to infinite size and the whole thing sets no matter how big it is. And that's that's how jello sets. Could that be gelation? Yes. The short answer is that is gelation. That phase transition, that we see of the emergence of life is [00:31:00]

a gelation phase transition according to a generalization of Smolhofky, coagulation to this case of BFF strings coming together. If you if you think about quote unquote inanimate and viral replicators as being replicators that, that are not [00:31:15]

self contained, in other words, where the code that runs is not fully within the code that is actually getting copied, then you you you notice something interesting. So what I'm calling here an inanimate replicator, and very much in scare quotes, is, is [00:31:30]

code that copies something fully outside itself. In other words, the code that runs in order to do the copy is disjoint from the thing that gets copied. Are there such replicators in the real world? Of course. That's what water is. Right? Water is a replicator of some kind. It gets made by stuff, but [00:31:45]

the stuff that it gets, that it gets made from, you know, like, water is not a part of the of the running process. I mean, it is a part of the running process to mix more water in some cases, but, right, it's it's it's it's not, it's not part of the code, let's say. Viral is the case in which the the code [00:32:00]

and the thing that is copied overlap. So in other words, some of the code that does the copying is actually some of the stuff that gets copied, but the, the code is not fully contained by what gets copied. So this is an incomplete replicator that would need to cooperate with [00:32:15]

another replicator in order to reproduce. So that's what I mean by viral. In the beginning of BFF, all of the replicators are inanimate and viral. The great majority are inanimate and a few of them are viral. A few of them happen to copy, you know, 1 of those, bytes [00:32:30]

that is actually an instruction that is doing the copying. But as you move toward, the time of jolation, which I've normalized to 1 here, you can see that cellular replicators suddenly emerge. So they can't emerge before, you know, about halfway through the run and they and they shoot [00:32:45]

upward at the end. And that's really interesting because that tells you that that the moment of a cellular replicator where the machinery for copying yourself is part of the thing that is copied, emerges through the symbiosis or the symbiogenesis of inanimate and viral, replicators. Okay. [00:33:00]

So a full equation would have 2 terms. It would have this reproduction and, you know, Laca Volterra type type term and it would have a merger or Smolchowski type term. 1 on the left is normal population dynamics, that's normal Darwinism, and the 1 on the right, you [00:33:15]

could think about the left as evolution and the right as revolution. Right? Those are the moments when things come together. Now, the population dynamics part for BFF looks like this. It's a little bit more complicated, but it has the same basic form as Lotka Volterra. There's a linear part on [00:33:30]

the left. I'm just writing that as a matrix, r I j, operating on the on the whole thing. And on the right, the reason that looks a little bit a little bit different from Lotka Volterra is that when something gets copied, it overwrites other stuff. So, so now we have to say, well, how does [00:33:45]

how does that suppress the populations of everything else in the soup? In order to figure that out, you have to look at niches. What are the bytes where something gets copied? And the overlap between the niches of 2 replicators tells you, you know, how much 1 thing getting copied, you know, how likely [00:34:00]

it is that that will overwrite, something else that shares its niche. Okay. The symbiogenesis part is a bit of a mess, so I'm not gonna go through it. I hope that's okay. But it looks just like Smolchowski, just gnarlier. The the reason that it's gnarlier is [00:34:15]

because Smolchowski has only binary fusion, between 2 parts. And in BFF, sometimes a bunch of things come together, so you have to take into account these kernels that have more than 2, parameters in them. Also, when things come together, they don't [00:34:30]

necessarily look like the sum, of of the things that came together. You could have something that is 3 bytes long or something 5 bytes long come together and the result that copies itself is only 2 bytes, 1 byte from each 1 or or anything, right along those lines. So to to account for those complexities, you end up with a a [00:34:45]

much more complicated k term, but it's essentially the same as as a small hovske coagulation. To prove that this kind of symbiogenesis is needed in order to get, these complex programs, you you can do a very simple intervention, which is, when [00:35:00]

you're interacting 2 tapes, you can sort of do it in a sandbox before committing. And in the sandbox you see whether, whether a new replicator arises, and if so, what replicators is it made out of. In other words, you know, when you look at the source, [00:35:15]

you can see what, you know, whether whether any of those, source bytes were actually the output the outputs of copies of some previous replicator. And if so, then you have a tree. You have an ancestry tree for that for that replicator. That means that you can think about the depth of such a tree, you know, how [00:35:30]

many things have come together, and you can limit the depth of that tree. You can say, if the tree depth exceeds 10 for a new replicator, then I'm gonna I'm gonna actually not not do this interaction. I'm gonna take them back apart, pretend it never happened, put it back in the soup, and try again. If you if you limit [00:35:45]

the depth of the tree to say 24, then the number of operations that you have to block, the number of interactions you have to block is actually very small. You only have to block 1 in 1000 operations, but that 1 in 1000 operations is really important as it turns out. If you block those, [00:36:00]

no gelation will happen. You need, at least 3 depths of 20 or so in order to get these complex, programs. So this is very nice proof that symbiogenesis is what what is needed in order to get to these complex tapes. When you do that blocking, [00:36:15]

you end up with sort of logistic curves for the populations of all the replicators in that soup. They they should they go up and then they saturate and stabilize. That's fun because it lets you do a little bit of math. So as you can see, you know, not only do things go up and saturate, but [00:36:30]

then there's some random, oscillations and those oscillations can be correlated. Sometimes you can see the 2 of those populations go up and down together, that so means that they they may be collaborating with each other, and sometimes they go in opposite directions, they're anti correlated, and that means that they're competing [00:36:45]

with each other because they're, you know, 1 is overwriting the other for instance. So that's what 1 would expect from, from off diagonal production and competition from those those equations I wrote earlier. And if you linearize the dynamics around that steady state, then you can sample the correlations in those population [00:37:00]

fluctuations and you can reconstruct the matrix r. I'll skip the details of how 1 does this, but this is a classic fluctuation analysis. You solve the Lyapunov equation and you get a Jacobian, and from that you get the matrix R. [00:37:15]

And the matrices R look really cool. First of all, they have a strong diagonal that tells you that by and large, things replicate themselves, just as you would expect from Lotka Volterra. But, there's some other stuff going on here as well. Aside from that [00:37:30]

dominant diagonal of self replication, there is some negative stuff off the diagonal and some positive stuff off the diagonal. The negative stuff off the diagonal you can see looks largely symmetric about the diagonal and that's as you would expect too. Basically, if a competes with b, [00:37:45]

then b competes with a. 2 things that are that are fighting for the same niche are are in a kind of 0 sum relationship with each other. But the cooperation part where where, where something helps something else is not symmetric, and that's as you would expect too. Just because [00:38:00]

a helps b or enables b doesn't mean that b enables a or at least not directly. Right? So there are complex cycles in this in this graph on the right of of of co dependency or enablement. So, negative component is symmetric, [00:38:15]

positive component is is asymmetric and there's this big diagonal. Do the submatrices that are about to undergo symbiogenesis have any special properties? They do. So in other words, if it's these, let's say, 4 rows and columns that are about to about to undergo [00:38:30]

symbiogenesis, you can ask, what are the what are the eigenvalues of that matrix, of that sub matrix? And it turns out that that they are generally cooperative. So essentially, if you if you were to pick random rows and columns from this matrix, then you get high dimensional picture of the [00:38:45]

rank of the matrix. But when you look at the ones that actually combine, it's much lower rank. They're already, working together. So in other words, there's a relationship between the r and k parts of this equation. Symbiogenesis happens among guys who are already working together. Not [00:39:00]

all the same, not independent, cooperative. Here's another really interesting thing. If you look not at the r matrix but at the Jacobian itself, then you can find the signs of imminent instability in it, of when it's about to pop, when it's about [00:39:15]

to go run away and gelate, or gel. You don't say gelate, say gel. Right? So in particular, if you block the depth of the possible trees to a low number, then the eigenvector the eigenvalues of the Jacobian are always negative, meaning that the [00:39:30]

system is stable. But as you look at larger depth ceilings, you find that more and more of this leading eigenvectors, or the real parts of those leading eigenvectors, pop positive and that means that the system is about to blow. You can keep it from blowing for a while [00:39:45]

by keeping that merger clamp on, but it tells you that essentially the more you evolve these things, the more they begin to cooperate with each other and the more incipient symbiogenesis is about to happen. And that's what leads to this phase transition. Alright. I I just wanna, put a little [00:40:00]

plug in for what I think could be a really beautiful missing link between the kind of algorithmic information theory that Hector Zenil was talking about and the assembly theory that he has somewhat slammed with a couple of papers that he has written. But, you know, as [00:40:15]

as those of you who have followed that might know or might might realize from what I've just talked about, there's a very close relationship between what I've just been describing in assembly theory. It's things coming together to make bigger things. But the assembly theory proponents have have not really talked about the computational nature of [00:40:30]

what they're doing. In this, I fully agree with with where Hector is coming from. And the way that those connect, I think is by starting to look at things like conditional Kolmogorov complexity of the things that are coming together. I think this is a construction point for us to maybe reconcile those 2 different pictures. Alright. [00:40:45]

So symbiogenesis is what gives you complexification. That in turn is what gives evolution its arrow of time. In classical evolution and Darwinian evolution, there's no reason that things should become more complex over time. You know, they might simplify, they might get more complex, it doesn't matter. But [00:41:00]

with symbiogenesis, we know that things get more complex because if a can replicate itself and and survive into the future and b can replicate itself and survive into the future, when they come together, you suddenly need a to replicate itself and b to [00:41:15]

replicate itself and there's some additional information that has been added, which is how the 2 fit together. And and those those extra bits of information that keep getting added to the program of what is the large replicator, they don't come from mutation. They come from the fact that things [00:41:30]

encounter each other randomly in order to possibly undergo that symbogenetic event. So it's actually the thermal randomness of the fact that we pluck 2 of these guys out of the soup at random, that's the the information source, if you like, or the noise source that is selectively turned into algorithmic information [00:41:45]

by the symbioteneic process. Jor Safmadi and John Maynard Smith have have, have written, you know, extensively about these major evolutionary transitions in which symbiogenesis results in large novel forms of life like eukaryotes, multicellularity [00:42:00]

and so on. And, I think this work is great, but, but the flaw is that they're only talking about 8 events or 12 events. And if if what I'm saying is true, then this is just the tip of a gigantic iceberg. Basically, it's symbiogenesis [00:42:15]

all the way down. Most of these symbogenic events are much more uneven. There may be just a little bit of something getting incorporated into something much bigger, but that is the source of novelty in all of evolution. These are just the most dramatic cases that involve, you know, really really big, visible stuff happening. [00:42:30]

So is there evidence for these smaller symbogenetic events in biology? Lots. There's lots of evidence for it. So, you know, I I don't have time to go into it in any detail but if you look at at just the human genome, you find that, you know, only 1 and a half percent of it codes for our [00:42:45]

proteins and lots of the rest of it is transposons and, other endogenous, retroviral elements of various kinds that involve viruses whose, whose ecology is our own genomes and that reproduce inside our genomes and sometimes jump species [00:43:00]

resulting in weird shit like, a quarter of the cow genome being a retrotransposon that also lives in lizards and salamanders and stuff. And so, you know, when you start to look at that, you you realize that that genomes are fractal and it's replicators made of replicators [00:43:15]

made of replicators just as I've as I've described, not these kind of, you know, fixed design space and evolution only happening in its usual way. It's not just horizontal gene transfer in bacteria. This single genetic picture, think, is is the engine, that produces novelty, throughout [00:43:30]

all of life, including including big complex animals like ours, like us. There's more and more evidence in the in the last decade of of things like this going on. You know, for instance, the ARC virus, was endogenized, in in the mammal lineage and you can find it in our brains [00:43:45]

and it turns out that if you knock out the ARC virus in mice, they stop being able to form new memories. So clearly, the ARC virus is doing something important for and that's a source of novelty that that was an endogenized virus. Similar, the mammalian placenta, was, is formed by [00:44:00]

an endogenized virus that fuses cell membranes together, and so on. Okay. So there's a definition of life that comes out of this. Life, and I I said this, you know, in the panel yesterday, is an embodied autopoietic computation arising and complexifying through symbiogenesis. It's [00:44:15]

not just neuroscience that's computational. Life was computational from the beginning. And it gets more computationally complex over time through symbiogenesis at many scales. Because remember, if life is a computer from the start, then [00:44:30]

every time things fuse together, you're making a more and more parallel computer. Those computers have to be not only running the code that model themselves and reproduce themselves, but that also do something about modeling the other and figuring out how they interact or work with the other. And [00:44:45]

this means that an ecology of functions is building up through massively parallel computation that becomes, if you like, more and more intelligent with every 1 of these of these fusions. And since symbiogenesis makes the computation massively parallel, that implies that intelligence and life [00:45:00]

are very, closely connected, which is why, you know, I ended up with the book What is Life? As part of the book What is Intelligence? When you're not only using that intelligence to model yourself, but also to model your environment, which by the way includes others most [00:45:15]

importantly, then that's intelligence and that means that life was intelligent from the start. And the moment that that modeling of others begins, what we call in in larger, more complex animals, theory of mind becomes fundamental to the way intelligence develops. [00:45:30]

So, you know, these are really simple simulations that show how, you know, just persistence allows, you know, the modeling of of of of an environment to turn into learning chemotaxis in these fake bacteria. But of course, you know, in [00:45:45]

real life, you're not only learning about an environment that that exists in isolation like the like the sugar crystal, but actually all of your friends. Right? The moment you're reproducing, the greater part of your environment is is actually all of your all of the other things that that, you know, even your own reproduction [00:46:00]

is creating. Life is never a single player. Things like intelligence explosions in our lineage in the hominins and in cetaceans, and in bats and in a variety of other species are exactly this kind of runaway modeling of others resulting [00:46:15]

in, growth of brains and growth of of groups and and therefore that, you know, when we think about the growth of advanced intelligence, you know, in in in, you know, human societies or human brains, it's it's really that same sort of of symbiotic process happening at a [00:46:30]

much at a much higher level. Let's end there and and switch to, questions. [00:46:45]

**Audience Questioner 1:** I think there are, multiple different ways to represent the symbiotic. I think in the real biology, we maintain those hierarchical structures and that there are fundamental mathematical differences, how how you [00:46:49]

treat those embryos. And do you have any insight how we can implement that? [00:47:00]

**Blaise Agüera y Arcas:** Yes. In biology we often, sort of reify 1 particular level of detail and we say, you know, these are the life forms and, you know, maybe there's a symbiosis between, you know, let's [00:47:05]

say, you know, algae and a sea slug, but we still think of the algae and the sea slug as as separate and we think about population dynamics within that rather than modeling them separately, is there a reason to prefer 1 scale or another? You know, for me, 1 of the lessons, the reason that I spent so much time on the relationship [00:47:15]

between R and K is that you can always move something from 1 from from R to K and back. You know, Lin Margulis famously said we're just colonies of bacteria, you know, some of which live inside each other. And that's true. You know, you could describe us as just [00:47:30]

colonies of bacteria. But the reason that it's useful to to move up a level of detail is because, you know, humans also, you know, reproduce as a unit, you know, hence the METs, and and there are a lot of things that you can you can learn about when you study at that higher level, a [00:47:45]

lot of abstractions you can make from a computational perspective that are hard if you're only modelling at the lower level. So I don't think that there's any there's any 1 layered layer level that is true. And we have lots of boundary cases like lichen or like, colony insects, right, where you can model the entire colony or [00:48:00]

you can model the individuals. I don't think there's a right answer to those 2. So, you know, do you do you keep a block of rows and columns in R that are that are that are in, you know, that always end up or mostly end up getting copied together, or do you add a new row? You know, it's it's it's [00:48:15]

actually a a coarse graining choice and you can make either 1. [00:48:30]

**Audience Questioner 2:** Symbiosis is not symbiogenesis. Like, you know, what is the thing that you would claim is kind of like, you know, a good insight for how, you know, A and B solve being [00:48:32]

A and B in symbiosis and they become something else. [00:48:45]

**Blaise Agüera y Arcas:** The fact that that phase transitions don't come from R alone, you know, but but you have to look at k. Now you you do you do get these these runaway modes, right, which which tell you that something is about to is about to happen. But in [00:48:48]

order to understand that phase transition, right, in other words, in order to see that a major evolutionary transition has occurred, right, to put it in biological terms, you you actually have to understand the physics of k. It's only by understanding the physics of k that you can do the [00:49:00]

theory that lets you, you know, predict and understand what is going on right here. So, you know, if you model a body as just a bunch of bacteria, then it's not wrong, but but then, you know, it's invisible to you that, you know, that something amazing happened when we became [00:49:15]

multicellular, or when eukaryotes formed out of out of out of bacteria. So this allows higher order modeling. And and in particular, by the way, that higher order modeling, you know, if we just take the subjective perspective for a moment, if you are 1 of those bodies, if you are 1 of those people, then, you know, you're [00:49:30]

not gonna survive very well if you're only modeling other people as collections of bacteria. Right? You have to build higher order models of them because that becomes an essential part of your umwelt, and you have to simplify or coarse grain the world in order to build a model that is that is ecologically [00:49:45]

relevant to you. So, you know, I'm I'm kind of mixing here a a subjective and an and an objective perspective, but the subjective perspective ultimately is super important. You know, it's a little bit similar to like why do we need temperature and pressure in physics? You know, those don't exist if [00:50:00]

we just look at the microscopics, but it's only by by coarse graining and looking at the larger scale that you can understand thermodynamics. And in the same way, it's only by zooming out and looking at the symbiogenesis that you can understand the dynamics of transitions, of phase transitions, METs, [00:50:15]

and smaller and coarser grained models that, you know, where where higher orders of things emerge. [00:50:30]

**Audience Questioner 1:** Well, actually, that's exactly what I was doing like 30 years ago. [00:50:35]

**Blaise Agüera y Arcas:** Exactly. That's that's why I began with your nearly 30 years ago paper. [00:50:39]

**Audience Questioner 1:** There was a big problem, like, [00:50:43]

it's always, you know, the symbiotic is impossible, like, you know, we burn wood, then it becomes complicated, like, coupling with each other. However, the function itself is not becoming complex or become high order thing. So the function itself is just [00:50:45]

stay there. [00:51:00]

**Blaise Agüera y Arcas:** I have 3 answers, suppose, depending on depending on which way we we talk about it. So first answer actually comes from software engineering. So composition or or from mathematics for that matter, composition of functions is, [00:51:01]

symbiogenesis, as as I've described it. And when you compose, you know, 2 functions to make a a higher order function, you are making something more complex, than than the than the primitives. You know, and and and, you know, the what I hinted at with, you know, the Eric [00:51:15]

Eric El Mussenino's, you know, beginnings of conditional Kolmogorov complexity can quantify that sort of compositional complexity. You could find signatures of it in you know, if you don't want to look in DNA, you could look in GitHub at the way, you know, every time somebody writes some code, right, it begins by [00:51:30]

importing a bunch of other things and combining them and and and and you you do see a tendency toward toward complexity. Now, that is constrained by energy. You know, the more complex a thing you make, the the more, free energy it has to use. But, [00:51:45]

now you get, some of Chris Kempis' beautiful work in which you see that there are energetic benefits to teamwork. Right? So so the the the way the scaling laws work for this, which are also environmentally dependent, I mean, I don't know, Chris, if you got to like the snow the [00:52:00]

snowball earth type stuff, but there were certain very specific conditions at certain points in the earth's history that became favorable for eukaryogenesis, if I'm remembering correctly. So there are some external conditions as well. But the other cool thing is that when you start to have [00:52:15]

more complexity in the computers, when you start to have massively parallel computation, that greater intelligence also unlocks new energy sources. And and that gives you a bigger budget to play with, which which in turn allows the [00:52:30]

next MET to take place. So I think there's an energetic perspective, there's a compositional perspective, a Kolmogorov perspective, there's a scaling law perspective that that can all come to rescue that that that question. But we should talk more about it. I'd I'd love to I'd [00:52:45]

love to get into this in more detail. [00:53:00]

**Audience Questioner 3:** It's essential for life to have some functionality. In 2019, the family of the Braveback programs, their strings, in which gain their functionality by its external goal, aka the CPU. [00:53:01]

**Blaise Agüera y Arcas:** I agree. So I made claims that [00:53:13]

maybe sound contradictory, you know, 1 of which was that Von Neumann is embodied computation and different from Turing in that sense, but on the other hand that BFF looks like, you know, very much like a Turing machine, and yet I also said it was embodied because I made 1 tape. [00:53:15]

Know, even the question of whether something is embodied or not is a little bit perspective dependent as well. Because in a in a Von Neumann system, for instance, there's of course the same rule operating at every pixel. You know, you can ask yourself the question, is a computer the thing that I make? You [00:53:30]

know, with lots of parts, right, you know, the kinds that von Neumann designed, or is it just the operation of a single pixel? The usual answer is to say what happens at a single pixel is just the physics of that world. But what constitutes the physics and what constitutes the computation is actually [00:53:45]

a movable boundary. So, you know, embodiment is is is essential in a very minimal sense that you need to be able to, to operate on the the thing that is going to that you need to be able to make quines essentially. Right? And and and [00:54:00]

and in ordinary brain fuck, you you can't make a quine because the data tape is separate from the from the program tape. But you bring them together, you're now in the same realm as as a as a cellular automaton, albeit with a different coarse graining of what you consider to be the physics and what you [00:54:15]

consider to be the the code. Now, I mean, in our world, we know that it's possible to build computers or else we wouldn't be able to build computers and we wouldn't be here either. But what constitutes the physics, if you like, the physics that makes up computers itself had to evolve. We [00:54:30]

began as, I guess, nothing but a quantum field theory and then things came together into particles, and the particles come together into atoms, the atoms come together into molecules and so on. Those are essentially what I would call the inanimate replicators, [00:54:45]

right, in in the system. And and there's an important phase transition when those suddenly are rich, form a rich enough set that not only do you have an autocatalytic system as Walter Fontana would have said, but also that that you can form [00:55:00]

a Turing complete instruction set and and therefore, you know, open the door to generality of of computing. I hope that I hope that makes some sense. Alright. And I think we're And, yeah, I'm afraid we have to [00:55:15]

**Audience Questioner 1:** wrap up. So let's thank, please, once again. [00:55:26]

Thank you so much. It was amazing. It was amazing talk. Great questions too. [00:55:30]
