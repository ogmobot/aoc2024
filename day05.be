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

def read_number_lists(fp, sep)
    result = []
    line = fp.readline()
    while line != "" && line != "\n"
        result.push(map1(number, string.split(line, sep)))
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
        # basically shell sort
        gaps = [701, 301, 132, 57, 23, 10, 4, 1]
        for gap : gaps
            for i : gap .. xs.size() - 1
                tmp = xs[i]
                j = i
                while j >= gap && (!is_ordered(sub_rules, [xs[j - gap], tmp]))
                    xs[j] = xs[j - gap]
                    j -= gap
                end
                xs[j] = tmp
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
