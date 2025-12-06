Advent of Code 2024
===================
Is another 25 programming languages even possible? Let's find out. (That said, I'm not sure last year's solving-by-hand counts as a language, and writing programs in a dozen nearly-identical dialects of LISP is hardly evidence of polyglottery!)

Day 01: [ALGOL 68](https://jmvdeer.home.xs4all.nl/en.algol-68-genie.html)
-------------------------------------------------------------------------
Writing this program is how I realised that I have been mollycoddled by years of short-circuited boolean operations. It's very nice to be able to write `if (p != NULL && p->data) {...}` in C-like languages; but in ALGOL, the construction `IF p ISNT REF NODE(NIL) AND data OF p THEN ... FI` will try to evaluate both sides of the boolean operation, potentially segfault-ing when it attempts `data OF p`. In writing the sorting function for this program, my initial efforts to write quicksort were stymied by my list indices running out of bounds, despite my belief that I was bounds-checking. Eventually, I gave up and just wrote bubblesort, but after completing part 1, tried shellsort instead. It was at this point I realised that ALGOL's `AND` doesn't short circuit, and instead resorted to the somewhat awkwardly-named GNU extension `ANDTH`. Of course, this meant I could go back and fix quicksort, but I've left the shellsort implementation in for reference.

Another little annoyance was that although statements within a block are separated by semicolons (which makes sense in analogy to English grammar), the last statement in a block doesn't require a trailing one (which also makes sense in analogy to English grammar). This means that adding a cheeky debug print statement at the end of a block will make the compiler complain if you don't modify your semicolons accordingly. I suspect this influenced later language design!

I can see similarities between ALGOL and other roughly cotemporaneous languages, like FORTRAN, Pascal and perhaps even BASIC. I've read that C's most direct ancestor is BCPL, which descended from ALGOL 60 (rather than ALGOL 68), but there's certainly a family resemblance.

Strictly speaking, it wasn't necessary to implement a frequency table to solve part 2 of this problem. However, it's (in theory) a little more time efficient, reducing the solution from $O(n^2)$ to $O(n\log n)$-ish (assuming traversal of the frequency table doesn't take $O(n)$ every time). It could be made more efficient with a tree-like structure or hash table instead. I just thought I'd mess around with pointers a little, since I probalby won't ever be coming back to this language.

**ALGOL 68**: the great-uncle of the famous C.

**Syntax Highlight**: `OF` to lookup a field within a structure (or structure reference) -- very English-like!
