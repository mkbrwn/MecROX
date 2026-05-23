#run previous script for cleaning data

source("src/1_clean_data.r")


# produce a Lowess curve with separate pre- and post-randomisation segments
lowess_split_plot <- ggplot(data, aes(x = TimeSinceRandomisation, y = SpO2Value)) +
    # single combined linear trend pre-randomisation
    geom_smooth(
        data = data %>% filter(TimeSinceRandomisation < 0),
        aes(colour = "Pre-randomisation"),
        method = "lm", se = TRUE, fill = "grey70"
    ) +
    # separate curves per treatment post-randomisation
    geom_smooth(
        data = data %>% filter(TimeSinceRandomisation >= 0),
        aes(colour = factor(Treatment)),
        method = "loess", se = TRUE, span = 0.75, fill = "grey70"   
    ) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40") +
    scale_colour_manual(
        name = "Treatment group",
        values = c(
            "Pre-randomisation" = "grey40",
            setNames(
                RColorBrewer::brewer.pal(max(3, length(unique(data$Treatment))), "Set1")[seq_len(length(unique(data$Treatment)))],
                levels(factor(data$Treatment))
            )
        )
    ) +
    scale_x_continuous(
        limits = c(-12, 120),
        breaks = c(-12, seq(floor(min(data$TimeSinceRandomisation, na.rm = TRUE) / 24) * 24, 120, by = 24)),
        labels = c("-12", seq(floor(min(data$TimeSinceRandomisation, na.rm = TRUE) / 24) * 24, 120, by = 24)),
        expand = expansion(mult = c(0, 0))
    ) +
    labs(
        x = "Time since randomisation (hours)",
        y = "SpO2 (%)",
    ) +
    theme_bw(base_size = 16) +
    theme(legend.position = "inside", legend.position.inside = c(0.97, 0.97), legend.justification = c(1, 1),
          legend.background = element_rect(fill = alpha("white", 0)),
          legend.key = element_rect(fill = NA),
          panel.border = element_blank(),
          axis.line = element_line(colour = "black")) +
    scale_y_continuous(limits = c(88, 100), breaks = seq(88, 100, by = 2), expand = expansion(mult = c(0, 0)))

ggsave("output/figures/lowess_spo2_split.png", plot = lowess_split_plot, width = 8, height = 5, dpi = 300)
