#!/usr/bin/env Rscript
# install library with `install.packages("igraph")` (and some patience)
library("igraph")

edge_data <- read.delim("input23.txt", header = FALSE, sep = "-")
lan_party <- make_graph(unlist(t(edge_data)), directed = FALSE)

# This counts the number of triangles at each vertex.
# Hence, each unique triangle gets triple-counted.
all_trigs   <- sum(count_triangles(lan_party)) / 3
tless_party <- induced_subgraph(
    lan_party,
    V(lan_party)[!startsWith(V(lan_party)$name, "t")]
)
non_t_trigs <- sum(count_triangles(tless_party)) / 3
write(all_trigs - non_t_trigs, stdout())

clique <- largest_cliques(lan_party)[[1]]
write(paste(sort(clique$name), collapse = ","), stdout())
