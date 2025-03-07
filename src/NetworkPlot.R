# For the equal-dose effects model network plot, you must load the dataset
# "np_28-30d-mortality_equal-dose_model.csv".
#
# The code branches in Step 4 into two sections:
#   - Step 4-a: Exchangeable dose effects model
#   - Step 4-b: Equal-dose effects model
#
# If you load "np_28-30d-mortality_equal-dose_model.csv", please uncomment the
# code from Step 4-b onward to run the equal-dose effects model.

# Automatically install and load required packages
required_packages <- c("dplyr", "tidyr", "purrr", "igraph", "ggraph", "ggplot2", "ggview")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# ---------------------------
# Data Loading and Cleaning
# ---------------------------
# Read CSV file into a data frame
df <- read.csv("data/np_28-30d-mortality_exchangeable-dose_model.csv")

# Remove the column "na.." if it exists
if ("na.." %in% names(df)) {
  df <- df %>% select(-`na..`)
}

# ---------------------------
# Step 1: Convert to Long Format
# ---------------------------
# Pivot treatment columns into a long format
df_t <- df %>%
  select(study, starts_with("t..")) %>%
  pivot_longer(
    cols = starts_with("t.."),
    names_to = "arm_id",
    values_to = "treatment",
    names_pattern = "t\\.\\.(\\d+)\\."
  )

# Pivot sample size columns into a long format
df_n <- df %>%
  select(study, starts_with("n..")) %>%
  pivot_longer(
    cols = starts_with("n.."),
    names_to = "arm_id",
    values_to = "n",
    names_pattern = "n\\.\\.(\\d+)\\."
  )

# Pivot responder columns into a long format
df_r <- df %>%
  select(study, starts_with("r..")) %>%
  pivot_longer(
    cols = starts_with("r.."),
    names_to = "arm_id",
    values_to = "r",
    names_pattern = "r\\.\\.(\\d+)\\."
  )

# Merge the long data sets by study and arm_id, filtering out missing values
long_df <- df_t %>%
  left_join(df_n, by = c("study", "arm_id")) %>%
  left_join(df_r, by = c("study", "arm_id")) %>%
  filter(!is.na(treatment) & !is.na(n))

# ---------------------------
# Step 2: Aggregate Data by Study and Treatment
# ---------------------------
# Sum 'n' and 'r' for each study and treatment to avoid duplicates
long_df <- long_df %>%
  group_by(study, treatment) %>%
  summarise(
    n = sum(n, na.rm = TRUE),
    r = sum(r, na.rm = TRUE),
    .groups = "drop"
  )

# ---------------------------
# Step 3: Create Edge and Node Summaries for the Network Graph
# ---------------------------
# Generate pairwise combinations within each study to create edges
edges <- long_df %>%
  group_by(study) %>%
  summarise(
    pairs   = list(combn(treatment, 2, simplify = FALSE)),
    pairs_n = list(combn(n, 2, simplify = FALSE)),
    .groups = "drop"
  ) %>%
  unnest(cols = c(pairs, pairs_n)) %>%
  mutate(
    t1 = map_chr(pairs, 1),
    t2 = map_chr(pairs, 2),
    n1 = map_int(pairs_n, 1),
    n2 = map_int(pairs_n, 2),
    edge = paste(sort(c(t1, t2)), collapse = "--"),
    total_n_edge = n1 + n2
  ) %>%
  select(-pairs, -pairs_n)

# Summarize edges across studies
edges_summary <- edges %>%
  group_by(t1, t2) %>%
  summarise(
    k = n(), # Number of occurrences (studies)
    n_sum = sum(total_n_edge),
    .groups = "drop"
  )

# Summarize node information by aggregating total sample size for each treatment
nodes_summary <- long_df %>%
  group_by(treatment) %>%
  summarise(n_total = sum(n), .groups = "drop")

# ---------------------------
# Step 4-a: Specify Custom Node Order
# ---------------------------
# Define desired treatment order for node display
desired_order <- c(
  "Placebo", "mPSL 4.0 mg/kg", "mPSL 5.0 mg/kg", "mPSL 19.6 mg/kg",
  "mPSL 22.4 mg/kg", "mPSL 37.8 mg/kg", "mPSL 41.6 mg/kg",
  "DEX 60 mg", "DEX 120 mg", "DEX 150 mg",
  "HC 600 mg", "HC 1400 mg", "HC 1500 mg"
)

nodes_summary <- nodes_summary %>%
  mutate(
    treatment = factor(treatment, levels = desired_order)
  ) %>%
  arrange(treatment)

# ---------------------------
# Step 5-a: Assign Color Groups Based on Treatment Prefix
# ---------------------------
nodes_summary <- nodes_summary %>%
  mutate(color_group = case_when(
    startsWith(as.character(treatment), "mPSL") ~ "mPSL",
    startsWith(as.character(treatment), "DEX") ~ "DEX",
    startsWith(as.character(treatment), "HC") ~ "HC",
    treatment == "Placebo" ~ "Placebo",
    TRUE ~ "Other"
  ))

# Create an undirected graph from the edge and node summaries
g <- graph_from_data_frame(d = edges_summary, vertices = nodes_summary, directed = FALSE)

# ---------------------------
# Step 6-a: Plot the Network Graph
# ---------------------------
p <- ggraph(g, layout = "igraph", algorithm = "circle") +
  geom_edge_link(
    aes(
      label = paste0("k = ", k, "\nn = ", n_sum),
      width = k
    ),
    angle_calc = "along",
    label_dodge = unit(0, "lines"),
    label_size = 3,
    color = "#314f56",
    alpha = 0.99,
    show.legend = FALSE
  ) +
  # Plot nodes with size based on total patients and fill color by group
  geom_node_point(aes(size = (n_total) / 100, fill = color_group),
    color = "#525252", shape = 21, stroke = 0.5
  ) +
  # Add node labels with treatment name and patient count
  geom_node_text(
    aes(
      label = paste0(name, "\n", n_total, " patients"),
      x = x * 1.4, y = y * 1.4
    ),
    size = 4, color = "black",
    repel = TRUE, point.padding = unit(-300, "lines")
  ) +
  scale_size_continuous(range = c(2, 40)) +
  scale_edge_width_continuous(range = c(0.25, 3)) +
  # Manually set colors for each group
  scale_fill_manual(
    values = c(
      "mPSL"    = "#b3e2cd",
      "DEX"     = "#fdcdac",
      "HC"      = "#cbd5e8",
      "Placebo" = "#cccccc",
      "Other"   = "#f0f0f0"
    )
  ) +
  theme_void() +
  theme(
    legend.position = "none",
    plot.margin = unit(c(1, 1, 1, 1), "cm")
  ) +
  coord_cartesian(clip = "off") +
  canvas(7, 7)

# Display the graph
print(p)


# # ---------------------------
# # Step 4-b: Equaldose Section: Reorder Nodes for a Different Visualization
# # ---------------------------
# # Specify a new custom order for the equaldose view
# desired_order <- c("Placebo", "mPSL", "DEX", "DEX_2", "HC")
# nodes_summary <- nodes_summary %>%
#   mutate(
#     treatment = factor(treatment, levels = desired_order)
#   ) %>%
#   arrange(treatment)
#
# # Reassign color groups (if needed) for the equaldose view
# nodes_summary <- nodes_summary %>%
#   mutate(color_group = case_when(
#     startsWith(as.character(treatment), "mPSL") ~ "mPSL",
#     startsWith(as.character(treatment), "DEX")  ~ "DEX",
#     startsWith(as.character(treatment), "HC")   ~ "HC",
#     treatment == "Placebo"                      ~ "Placebo",
#     TRUE                                        ~ "Other"
#   ))
#
# # Recreate the graph with the updated node order
# g <- graph_from_data_frame(d = edges_summary, vertices = nodes_summary, directed = FALSE)
#
# # Plot the equaldose network graph with updated node positions and style
# p <- ggraph(g, layout = "igraph", algorithm = "circle") +
#   geom_edge_link(aes(label = paste0("k = ", k, "\nn = ", n_sum),
#                      width = k),
#                  angle_calc = "along",
#                  label_dodge = unit(0, "lines"),
#                  label_size = 3,
#                  color = "#314f56",
#                  alpha = 0.99,
#                  show.legend = FALSE) +
#   geom_node_point(aes(size = (n_total) / 100, fill = color_group),
#                   color = "#525252", shape = 21, stroke = 0.5) +
#   geom_node_text(aes(label = paste0(name, "\n", n_total, " patients"),
#                      x = x * 1.3, y = y * 1.3),
#                  size = 4, color = "black",
#                  repel = TRUE, point.padding = unit(-300, "lines")) +
#   scale_size_continuous(range = c(15, 40)) +
#   scale_edge_width_continuous(range = c(0.25, 3)) +
#   scale_fill_manual(
#     values = c(
#       "mPSL"    = "#b3e2cd",
#       "DEX"     = "#fdcdac",
#       "HC"      = "#cbd5e8",
#       "Placebo" = "#cccccc",
#       "Other"   = "#f0f0f0"
#     )
#   ) +
#   theme_void() +
#   theme(
#     legend.position = "none",
#     plot.margin = unit(c(1, 1, 1, 1), "cm")
#   ) +
#   coord_cartesian(clip = "off") +
#   canvas(7, 7)
#
# # Display the updated equaldose graph
# print(p)
