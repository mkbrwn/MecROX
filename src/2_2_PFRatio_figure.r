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
        breaks = c(-12, seq(0, 120, by = 24)),
        expand = expansion(mult = c(0, 0))
    ) +
    labs(
        x = "Time since randomisation (hours)",
        y = "PF ratio (kPa)",
    ) +
    theme_bw(base_size = 16) +
    theme(
        legend.position = "inside", legend.position.inside = c(0.85, 0.40), legend.justification = c(1, 1),
        legend.background = element_rect(fill = alpha("white", 0)),
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 12),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 14),
        panel.border = element_blank(),
        axis.line = element_line(colour = "black"),
        plot.margin = margin(5.5, 20, 5.5, 5.5)
    )

ggsave("output/figures/lowess_pfratio_split.png", plot = lowess_split_plot_pfratio, width = 8, height = 5, dpi = 300)
