Grid := Object clone do(
    rows := List clone
    robot := nil
    addRow := method(s,
        rows append(s asList map(col, chr,
            obj := asWarehouseObject(chr)
            (chr at(0) == 64) ifTrue(robot = obj)
            obj init(self, rows size, col))
        )
    )
    at := method(r, c,
        rows at(r) at(c)
    )
    moveObj := method(r, c, dr, dc,
        obj := self at(r, c)
        rows at(r) atPut(c, nil)
        rows at(r + dr) atPut(c + dc, obj)
    )
    gpsSum := method(
        rows reduce(total, row,
            row reduce(subtotal, obj,
                subtotal + if(obj isNil, 0, obj gps),
            0) + total,
        0)
    )
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
    canMove := method(_, _,
        return false
    )
    gps := method(return 0)
)

SmallBox := Wall clone do(
    canMove := method(dr, dc,
        adj := warehouse at(row + dr, col + dc)
        adj ifNil(return true)
        adj canMove(dr, dc)
    )
    doMove := method(dr, dc,
        // Move adj
        adj := warehouse at(row + dr, col + dc)
        adj ifNonNil(adj doMove(dr, dc))
        // Move self
        warehouse moveObj(row, col, dr, dc)
        row = row + dr
        col = col + dc
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
    gps := method(return 0)
)

asWarehouseObject := method(s,
    s switch(
        "@", Robot,
        "#", Wall,
        "O", SmallBox,
        ".", nil
    ) clone
)

SmallBox gps := method((100 * row) + col)

main := method(fname,
    // parse text
    grid := Grid clone
    fp := File clone openForReading(fname)
    parts := fp contents split("\n\n")
    fp close
    parts at(0) split("\n") foreach(line, grid addRow(line))
    moves := parts at(1) split join

    // simulate robot
    moves foreach(move, grid robot tryMove(move))
    writeln(grid gpsSum)
)

main("input15.txt")
