Advent of Code 2024
===================
Is another 25 programming languages even possible? Let's find out. (That said, I'm not sure last year's solving-by-hand counts as a language, and writing programs in a dozen nearly-identical dialects of LISP is hardly evidence of polyglottery!)

Day 01: [ALGOL 68](https://jmvdeer.home.xs4all.nl/en.algol-68-genie.html)
-------------------------------------------------------------------------
Writing this program is how I realised that I have been mollycoddled by years of short-circuited boolean operations. It's very nice to be able to write `if (p != NULL && p->data) {...}` in C-like languages; but in ALGOL, the construction `IF p ISNT REF NODE(NIL) AND data OF p THEN ... FI` will try to evaluate both sides of the boolean operation, potentially segfault-ing when it attempts `data OF p`. In writing the sorting function for this program, my initial efforts to write quicksort were stymied by my list indices running out of bounds, despite my belief that I was bounds-checking. Eventually, I gave up and just wrote bubblesort, but after completing part 1, tried shellsort instead. It was at this point I realised that ALGOL's `AND` doesn't short circuit, and instead resorted to the somewhat awkwardly-named GNU extension `ANDTH`. Of course, this meant I could go back and fix quicksort, but I've left the shellsort implementation in for reference.

Another little annoyance was that although statements within a block are separated by semicolons (which makes sense in analogy to English grammar), the last statement in a block doesn't require a trailing one (which also makes sense in analogy to English grammar). This means that adding a cheeky debug print statement at the end of a block will make the compiler complain if you don't modify your semicolons accordingly. I suspect this influenced later language design!

I can see similarities between ALGOL and other roughly cotemporaneous languages, like FORTRAN, Pascal and perhaps even BASIC. I've read that C's most direct ancestor is BCPL, which descended from ALGOL 60 (rather than ALGOL 68), but there's certainly a family resemblance.

Strictly speaking, it wasn't necessary to implement a frequency table to solve part 2 of this problem. However, it's (in theory) a little more time efficient, reducing the solution from $O(n^2)$ to $O(n\log n)$-ish (assuming traversal of the frequency table doesn't take $O(n)$ every time). It could be made more efficient with a tree-like structure or hash table instead. I just thought I'd mess around with pointers a little, since I probably won't ever be coming back to this language.

**ALGOL 68**: the great-uncle of the famous C.

**Syntax Highlight**: `OF` to lookup a field within a structure (or structure reference) -- very English-like!

Day 02: [헐 (Heol)](https://wiki.xxiivv.com/site/heol.html)
-----------------------------------------------------------
This is my third time writing a program for the [Varvara](https://wiki.xxiivv.com/site/varvara.html) virtual machine. (The first two times were in uxntal assembly [2022, Day 6] and UF [2023, Day 16]. Will I have to use the Sunflower BASIC port next time???) The Heol interpreter is very much a built-for-fun (or proof-of-concept) project, and still has a lot of rough edges. The way it utilises the Varvara machine's return stack means that there's a limit to how far recursion can take the program. The stack can contain up to 256 bytes (so 128 addresses); most of my functions go 5 or 6 nested brackets deep, each of which pushes an address to the stack; so even with a little bit of tail optimisation, that's only 25 or so nested function calls. This is fine for some languages, but a bit limiting for a LISP (which will often use recursion to map a function across a list, or fold a list into an accumulator, etc.). I made an attempt to modify the language's source to allow for tail-optimisation of recursive user functions, but didn't get very far. (In retrospect, perhaps I should have modified the language to keep track of return addresses elsewhere in memory, rather than the native uxn return address stack. This approach worked for UF, after all.)

The language also lacks garbage collection, so having the runtime, program, input and program variables in memory all at once is a tight squeeze. The input contains 6521 integers, each of which costs 4 bytes of memory; and if each one is placed inside a 4-byte cons cell, and those cells are organised inside a thousand-element list (1000 more 4-byte cons cells), that's a total of 56168 bytes (a little more than 85% of the available 65536 bytes of memory). The runtime of ~2200 bytes still fits within the remaining memory, but the program allocates up to 16 more bytes per "unsafe" input sequence (and once allocated, that memory can't be freed or modified). My first attempt to solve this problem used a `fold` function to recursively accumulate the sum of the values, but this ran into stack overflow issues; the second used `define` to repeatedly re-define (and repeatedly allocate) the value of the solution, but this ran into memory issues. (Check the history of `day02.sh` and `day02.heol` for a taste of what this was like.)

In the end, I didn't calculate the output in Heol. Instead, I hacked together a bash script to handle input and output (so I guess this is technically a two-language solution): I wrote an AWK script to change e.g. `1 2 3` to `(solve '(1 2 3))` and piped the entire resulting file into the program. For part 1, I was able to actually compute the output within the program, but there wasn't enough memory to solve part 2 this way. The solution I ended up using pipes the input into the program, then sums the ouptut with a line of AWK (`{ p1 += $1; p2 += $2 } END { print p1; print p2 }`). (I think that given the language doesn't yet have a way to even read or write external files, this approach is fair enough for now.) At one point, this program ran a separate instance of Heol _per line of input_, but it turns out that was massive overkill for the amount of memory actually required!

Heol doesn't support macros yet. If it ever does, it'll make setting up keywords like `cond` and `let` much easier.

One logic bug I had to deal with (i.e. not relating to memory or recursion!) was deciding how to modify a list for Part 2 of the problem. Initially I tried removing only the first offending value from the list, but then an input like `46 43 44 43 42` couldn't be solved. (The first `43` should be removed, but my program saw it as a "safe" transition.) I found this bug by modifying my Python solution to compare each of its results to the Heol result (using something like `os.system("echo (safeish? '($vals)) | heol 2>temp.txt")`).

**헐**: don't let your memory limits define you!

**Syntax Highlight**: `eq?` to check equality (not very surprising at first, until you learn you'll need it to equate numbers -- there's no `=` operator)

Day 03: [HolyC](https://holyc-lang.com)
---------------------------------------
The nth "C but better" language I've used. HolyC has some interesting quirks: a string literal on its own is interpreted as a `printf` command (which feels nicer than you'd expect); a `switch` command can be given its argument in square brackets to disable bounds-checking (i.e. no `default` case, and segfault on a case that isn't covered); a `case` can span a range of values; no default `int` type (the signed-ness and width must be specified). These changes from C take advantage of gaps in the language, or slightly improve its efficiency; I can see why its author, Terry Davis, made these changes.

The language is very close to C, and I imagine anyone familiar with C would find it easy to write HolyC (especially now that it has been ported beyond its original environment of TempleOS). The different library bindings might be a minor hiccough. The original intent of the language was to be a hybrid scripting/systems language; HolyC is the language of the TempleOS shell, and programs and functions can be written and called directly from the shell. I'm not convinced of its usefulness for scripting, but writing a program like this one felt just a little nicer than writing in C. (Perhaps I should have delayed using this language for a harder task!)

After initially solving this problem using Python's regex library, I wanted to try a lower-level approach. Hence, a finite-state automaton. (HolyC doesn't have a regex library, but technically I could have used the C Standard Library version.) The language's `FileRead` function is extraordinarily useful for this specific task -- it simply loads the entire contents of a file into memory, as a contiguous range of eight-bit unsigned integers/characters. (This allocates memory which must be `Free`d later.) Then it's just a matter of traversing the data and keeping track of state. (States are stored as multiples of 128 to accomodate table lookups of state + ASCII value. HolyC doesn't appear to have `enum`s, so I've `#define`d the values instead.)

**HolyC**: a little nicer than C.

**Syntax Highlight**: `U0` (i.e. unsigned integer of 0 bits; HolyC's `void` type)

Day 04: [Gleam](https://gleam.run)
----------------------------------
I had high hopes for Gleam, but it didn't quite live up to the hype. I've actually attempted to complete a task from a previous year in Gleam, but the language wasn't really ready to solvec puzzles at that point in its development (or perhaps I gave up too soon). Don't get me wrong; it's a nice language with ML-like syntax and conveniences like pattern-matching and type-checking. But it comes with its fair share of annoyances, too.

The first annoyance was that program files can't be run like scripts; they must be part of a project, complete with `gleam.toml`, `manifest.toml` and `README.md` files. (Incidently, build instructions for my program: set up a new project with `gleam new <project name>`; copy the contents of my .gleam file into `<project name>/src/<project name>.gleam`; copy the puzzle input to `<project name>/input04.txt`; then run the program with `gleam run`.) I understand it's bad practice to set up an application as a hodge-podge mix of random program files, but sometimes you just need to run a tiny program! A second annoyance was that function names cannot contain uppercase letters (as I discovered when attempting to name a function something like `searchXMAS`). I can understand not _starting_ the function name with capital letters -- ML-like languages sometimes reserve Title Case for types -- but removing them altogether (and incidentally preventing the use of camelCase) seems weird. A third annoyance is the lack of string interpolation; to write to stdout the value of an integer, one must first `import gleam/int`, so that the `int.to_string` function can be used. (I should mention, however, that `echo` is also available for debugging purposes.)

The type-checker seems to do a good job inferring types without too many annotations, which is nice. (If the type-checker can't manage, it'll let you know not with `Please add type annotations` but `Please add some type annotations so we can continue`. I'm not sure whether I feel condescended to.)

The program itself is pretty straightforward. For every possible starting position, check for the target in every possible orientation. I was hoping that the program would take advantage of the data structures' immutability and the massive parallelisation that the BEAM virtual machine allows -- the reason I chose Gleam for this task in the first place -- and based on the "user time" output of `time`, this is taking place to some extent. It's difficult to tell how well it's working, though, or how to improve how parallelisable the program is.

**Gleam**: it's not bad, but it could be better.

**Syntax Highlight**: `<>` (string concatenation)

Day 05: [Berry](https://berry-lang.github.io)
---------------------------------------------
Berry is a cool little scripting language. It feels like a cross between Python and... Lua, perhaps? It has many of Python's object-method conveniences, but also syntax sugar for for-loops, ranges, anonymous functions, and so on. It's a little light on functional-programming conveniences, like map/reduce, but first-class functions make them easy to implement. One thing I found confusing is that `string.find` returns `-1` on failure, but `list.find` returns `nil`.

One of Berry's big "selling points" is its embeddability within low-power devices (and therefore its ability to interface with C), but I haven't tested this aspect of the language.

My Python solution for this task uses the `cmp_to_key` function from the `functools` module, which makes sorting the list so easy it almost feels like cheating! The Berry solution uses shell sort instead (and runs a little slower).

**Berry**: it's pretty neat.

**Syntax Highlight**: `:` (seen in range-based `for` loops, as in C++11)

Day 06: [V](https://vlang.io)
-----------------------------
V feels like all the good parts of Go and all the good parts of Rust wrapped up together. (It's like a better version of a better version of C.) Threads are a built-in type, like in Go, and can be spawned with the `spawn` keyword. The type system can handle complicated composite types, like in Rust, and the compiler will similarly ensure type-correctness. It also has conveniences like anonymous functions, `enum` types and immutability by default. It's purportedly only version 0.5.0, but it seems a lot more capable and mature than many of the other languages I've used in the past.

The version of the program I've uploaded is multithreaded and can be compiled with `v -prod -cc gcc -cflags "-march=native -O2" day06.v` (or similar). It takes just 10 seconds to run on my VM's 2-core CPU -- much faster than the 110s of my Python implementation! -- and should scale up with CPU cores. The compiler also has the ability to e.g. compile with debugging information, or to output a C file.

All that said, the language is not perfect (nor completely finished), and I managed to trigger a compiler bug or two when introducing optional types into my solution. This language seems very solid and a good option for any kind of systems programming that involves threads (or that doesn't).

The day 6 part 2 task is one of those "embarrassingly parallelisable" ones, which is the reason I chose to use the thread-friendly V for it. My V solution uses a string to internally represent the puzzle, instead of converting it to a hashmap like my Python solution.

**V**: only half-finished, but already better than Go.

**Syntax Highlight**: `<<` (append element to array, or concatenate two arrays)

Day 07: [Amber](https://amber-lang.com)
---------------------------------------
A language that compiles to Bash? Sure, why not? I mean, it'll be slow, obviously, but my Python solution for this puzzle runs in under a second; so it won't be that bad, right?

Oh, how naive I was. Don't get me wrong -- the ability to transpile Amber programs to Bash is a great convenience and makes the programs very portable -- but the program runs more slowly than I could ever have imagined. The language is currently a work-in-progress, and is at version 0.5, and having just used V, I assumed that the language would be pretty useable. Unfortunately, I seem to have picked the wrong problem to try to solve with it. The problem is easiest to solve with recursion, but Amber does not yet support recursion (even though bash does)! Well, that's not too bad, right? Just emulate a call stack, with an array that keeps track of each call's arguments. Well, that won't work either, since the language doesn't support nested arrays. So, my solution emulates the call stack with an array of _strings_. Every integer must be repeatedly cast and un-cast from a string, making the program very slow to run (over an hour for the actual input). There's nothing offensive about the syntax; in fact, there are a number of conveniences that make it pretty comfortable to write in, like the way its `if` can double as a `switch`.

At almost 25 minutes, this is one of my slowest programs that solves the problem using a "fast" method. (Two even slower programs are my Kitten program [2023, Day 11] and solving by hand [2023, Day 6].) Judging by the pull requests on GitHub, version 0.6 of Amber is likely to support recursion, so I might eventually re-implement this solution and see if it runs any faster. (It might also solve the weird bug of the program attempting to pop from an empty array even after `while len(args) > 0`...)

**Amber**: built for comfort, not for speed.

**Syntax Highlight**: `if { cond: a cond: b }` ("if-chain" statement behaves like switch/case)
