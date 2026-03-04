module day19;
import std::io;
import libc;

const MAXFILESIZE = 32768;

fn ulong count_ways(String[] towels, String pattern) {
    ulong[] ways = mem::new_array(ulong, pattern.len + 1);
    defer free(ways);

    ways[0] = 1;
    for (usz index = 0; index < pattern.len; index++) {
        foreach (towel : towels) {
            if (pattern[index ..].starts_with(towel)) {
                ways[index + towel.len] += ways[index];
            }
        }
    }

    return ways[pattern.len];
}

fn void main() {
    @pool() {
        char *raw_contents = tmalloc(MAXFILESIZE);
        CFile fp = libc::fopen("input19.txt", "r");
        usz inputlen = libc::fread((void *) raw_contents, 1, MAXFILESIZE, fp);
        libc::fclose(fp);
        raw_contents[inputlen] = '\0';

        String contents = ((ZString) raw_contents).str_view().trim();
        String[] lines = contents.tsplit("\n");

        String towels_line = lines[0];
        String[] towels = lines[0].tsplit(", ");

        uint total_1 = 0;
        ulong total_2 = 0;
        foreach (usz i, String pattern : lines[2 .. lines.len - 1]) {
            ulong res = count_ways(towels, pattern);
            total_1 += (uint) (res != 0);
            total_2 += res;
        }
        io::printn(total_1);
        io::printn(total_2);
    };
    return;
}
