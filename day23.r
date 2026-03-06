#!/usr/bin/env Rscript

# install library with `install.packages("igraph")` (and some patience)
library("igraph")

edge_data <- read.delim("input23.txt", header = FALSE, sep = "-")
lan_party <- make_graph(unlist(t(edge_data)), directed = FALSE)

cpus <- V(lan_party)
t_cpus <- cpus[startsWith(cpus$name, "t")]
lan_party <- set_vertex_attr(lan_party, "starts_with_t", V(lan_party), sapply(
    V(lan_party)$name,
    function (x) {startsWith(x, "t")}
))

trigs <- triangles(lan_party)
message(
    sum(
        sapply(
            seq(length(trigs) / 3),
            function (i) {
                trig <- trigs[(3*i-2):(3*i)]
                any(trig$starts_with_t)
            }
        )
    )
)

clique <- largest_cliques(lan_party)[[1]]
cpu_names <- sapply(clique, function (x) {vertex_attr(lan_party, "name", x)})
message(paste(sort(cpu_names), collapse = ","))
