#!/usr/bin/env Rscript

# install library with `install.packages("igraph")` (and some patience)
library("igraph")

edge_data <- read.delim("input23.txt", header = FALSE, sep = "-")
lan_party <- make_graph(unlist(t(edge_data)), directed = FALSE)

clique <- largest_cliques(lan_party)[[1]]
cpu_names <- sapply(clique, function (x) {vertex_attr(lan_party, "name", x)})
message(paste(sort(cpu_names), collapse = ","))
