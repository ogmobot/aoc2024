#!/usr/bin/env berry
import string

def map1(fn, xs)
    ys = []
    for x : xs
        ys.push(fn(x))
    end
    return ys
end

def fold(fn, acc, xs)
    for x : xs
        acc = fn(x, acc)
    end
    return acc
end

def middle(xs)
    return xs[xs.size()/2]
end

def swap(xs, i, j)
    tmp = xs[i]
    xs[i] = xs[j]
    xs[j] = tmp
end

def read_number_lists(fp, sep)
    result = []
    line = fp.readline()
    while line != "" && line != "\n"
        result.push(map1(number, (string.split(line, sep))))
        line = fp.readline()
    end
    return result
end

def is_ordered(rules, xs)
    for rule : rules
        a = rule[0]
        b = rule[1]
        if xs.find(a) == nil || xs.find(b) == nil
            continue
        end
        if xs.find(a) > xs.find(b)
            return false
        end
    end
    return true
end

def make_sorter(rules)
    return def (xs)
        sub_rules = []
        for rule : rules
            if xs.find(rule[0]) != nil && xs.find(rule[1]) != nil
                sub_rules.push(rule)
            end
        end
        # basically bubble sort
        done = false
        while !done
            done = true
            for j : xs.keys()
                for i : 0 .. j - 1
                    if sub_rules.find([xs[j], xs[i]]) != nil
                        swap(xs, i, j)
                        done = false
                        break
                    end
                end
            end
        end
        return xs
    end
end

def main()
    input_file = open("input05.txt", "r")
    rules      = read_number_lists(input_file, "|")
    page_lists = read_number_lists(input_file, ",")
    input_file.close()
    _rules = [
        [47,53],
        [97,13],
        [97,61],
        [97,47],
        [75,29],
        [61,13],
        [75,53],
        [29,13],
        [97,29],
        [53,29],
        [61,53],
        [97,53],
        [61,29],
        [47,13],
        [75,47],
        [97,75],
        [47,61],
        [75,61],
        [47,29],
        [75,13],
        [53,13]
    ]
    _page_lists = [
        [75,47,61,53,29],
        [97,61,53,29,13],
        [75,29,13],
        [75,97,47,61,53],
        [61,13,29],
        [97,13,75,29,47]
    ]
 
    sortie = make_sorter(rules)
    soln =
        fold(
            def (pair, acc)
                return [pair[0] + acc[0], pair[1] + acc[1]]
            end,
            [0, 0],
            map1(
                def (xs)
                    if is_ordered(rules, xs)
                        return [middle(xs), 0]
                    else
                        return [0, middle(sortie(xs))]
                    end
                end,
                page_lists)
        )
    print(string.format("%d\n%d", soln[0], soln[1]))
end

main()
