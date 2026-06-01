# run previous script for cleaning data
source("src/1_clean_data.r")
library(patchwork)

# compute distinct patient counts per 12-hour bin per treatment
pfratio_counts <- data_pfratio %>%
    mutate(interval = case_when(
        TimeSinceRandomisation < 0 ~ -12,
        TRUE ~ floor(TimeSinceRandomisation / 12) * 12
    )) %>%
    group_by(Treatment, interval) %>%
    summarise(n = n_distinct(MECROXStudy), .groups = "drop")

# produce a Lowess curve with separate pre- and post-randomisation segments
lowess_split_plot_pfratio <- ggplot(data_pfratio, aes(x = TimeSinceRandomisation, y = PFRatioValue)) +
    # single combined linear trend pre-randomisation
    geom_smooth(
        data = data_pfratio %>% filter(TimeSinceRandomisation < 0),
        aes(colour = "Pre-randomisation"),
        method = "lm", se = TRUE, fill = "grey70"
    ) +
    # separate curves per treatment post-randomisation
    geom_smooth(
        data = data_pfratio %>% filter(TimeSinceRandomisation >= 0),
        aes(colour = factor(Treatment)),
        method = "loess", se = TRUE, span = 0.75, fill = "grey70"
    ) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40") +
    scale_colour_manual(
        name = "Treatment group",
        values = c(
            "Pre-randomisation" = "grey40",
            setNames(
                RColorBrewer::brewer.pal(max(3, length(unique(data_pfratio$Treatment))), "Set1")[seq_len(length(unique(data_pfratio$Treatment)))],
                levels(factor(data_pfratio$Treatment))
            )
        )
    ) +
    scale_x_continuous(
        limits = c(-12, 120),
        breaks = seq(-12, 120, by = 12),
        expand = expansion(mult = c(0, 0))
    ) +
    labs(
        x = NULL,
        y = "PF ratio (kPa)",
    ) +
    theme_bw(base_size = 16) +
    theme(
        legend.position = "inside", legend.position.inside = c(0.97, 0.97),
        legend.justification = c(1, 1),
        legend.background = element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(fill = NA),
        panel.border = element_blank(),
        axis.line = element_line(colour = "black"),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        plot.margin = margin(5.5, 20, 0, 5.5)
    )

# count table panel
count_panel <- ggplot(pfratio_counts, aes(x = interval, y = fct_rev(factor(Treatment)), label = n)) +
    geom_text(size = 3.5) +
    scale_x_continuous(
        limits = c(-12, 120),
        breaks = seq(-12, 120, by = 12),
        expand = expansion(mult = c(0, 0))
    ) +
    labs(x = "Time since randomisation (hours)", y = NULL) +
    theme_bw(base_size = 16) +
    theme(
        panel.grid = element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(colour = "black"),
        axis.ticks.y = element_blank(),
        plot.margin = margin(0, 20, 5.5, 5.5)
    )

combined_plot <- lowess_split_plot_pfratio / count_panel +
    plot_layout(heights = c(4, 1))

ggsave("output/figures/lowess_pfratio_split.png", plot = combined_plot, width = 10, height = 6, dpi = 300)
