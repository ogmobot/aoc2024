Grid := Object clone do(
    rows := list()
    robot := nil
    appendRow := method(s,
        // Objects are initialised in a second pass
        rows append(s asList mapInPlace(chr,
            obj := asWarehouseObject(chr)
            (chr at(0) == 64) ifTrue(robot = obj) // @ 64
            obj)
        )
    )
    initObjs := method(
        rows foreach(r, row,
            row foreach(c, obj,
                obj init(self, r, c)
                if(obj isKindOf(LargeBox), do(
                    obj init(self, r, c - 1)
                    row atPut(c - 1, obj)
                ))
            )
        )
    )
    appendStretch := method(s,
        appendRow(s asList mapInPlace(switch(
            "@", "@.",
            "#", "##",
            "O", "[]",
            ".", "..")
        ) join)
    )
    solve := method(moves,
        moves foreach(move, robot tryMove(move))
        gpsSum
    )
    at := method(r, c, rows at(r) at(c))
    gpsSum := method(rows flatten select(hasSlot("gps")) unique mapInPlace(gps) sum)
)

Wall := Object clone do(
    warehouse := nil
    row := nil
    col := nil
    init := method(w, r, c,
        warehouse = w
        row = r
        col = c
        self
    )
    canMove := method(_, _, false)
)

SmallBox := Wall clone do(
    affectedObjects := method(dr, dc,
        // Some "Objects" might be nil
        list(warehouse at(row + dr, col + dc))
    )
    canMove := method(dr, dc,
        affectedObjects(dr, dc) \
            remove(nil) \
            mapInPlace(canMove(dr, dc)) \
            reduce(x, y, x and y, true)
    )
    doMove := method(dr, dc,
        // Move adj
        affectedObjects(dr, dc) remove(nil) foreach(doMove(dr, dc))
        // Move self
        warehouse rows at(row) atPut(col, nil)
        row = row + dr
        col = col + dc
        warehouse rows at(row) atPut(col, self)
    )
    gps := method((100 * row) + col)
)

LargeBox := SmallBox clone do(
    affectedObjects := method(dr, dc,
        if(dc == 0,
            return list(
                warehouse at(row + dr, col),
                warehouse at(row + dr, col + 1)
            ) unique,
            if (dc == 1,
                return list(warehouse at(row, col + 2)),
                return list(warehouse at(row, col - 1))
            )
        )
    )
    doMove := method(dr, dc,
        // Move adj
        affectedObjects(dr, dc) remove(nil) foreach(doMove(dr, dc))
        // Move self
        warehouse rows at(row) atPut(col, nil)
        warehouse rows at(row) atPut(col + 1, nil)
        row = row + dr
        col = col + dc
        warehouse rows at(row) atPut(col, self)
        warehouse rows at(row) atPut(col + 1, self)
    )
)

Robot := SmallBox clone do(
    tryMove := method(chr,
        // <  60
        // >  62
        // ^  94
        // v 118
        dr := chr switch (
            60,  0,
            62,  0,
            94, -1,
            118, 1
        )
        dc := chr switch (
            60, -1,
            62,  1,
            94,  0,
            118, 0
        )
        canMove(dr, dc) ifTrue(doMove(dr, dc))
    )
    gps := method(0)
)

asWarehouseObject := method(s,
    s switch(
        "@", Robot,
        "#", Wall,
        "O", SmallBox,
        "[", nil, // A pointer to LargeBox is placed here instead
        "]", LargeBox,
        ".", nil
    ) clone
)

main := method(fname,
    // parse text
    fp := File clone openForReading(fname)
    sections := fp contents split("\n\n")
    fp close
    moves := sections at(1) split join

    // part 1
    shortgrid := Grid clone
    sections at(0) split("\n") foreach(line, shortgrid appendRow(line))
    shortgrid initObjs

    // part 2
    longgrid := Grid clone
    longgrid rows = list()
    sections at(0) split("\n") foreach(line, longgrid appendStretch(line))
    longgrid initObjs

    solns := list(shortgrid, longgrid) mapInPlace(@ solve(moves))
    writeln("#{solns at(0)}\n#{solns at(1)}" interpolate)
)

main("input15.txt")
