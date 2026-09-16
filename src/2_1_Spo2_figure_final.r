#run previous script for cleaning data

source("src/1_clean_data.r")

# manually fit a per-treatment loess (rather than using geom_smooth's
# fullrange, which extrapolates using the whole panel's x range, including
# into the pre-randomisation segment) so extrapolation runs from time 0 to
# the panel's right edge, regardless of each group's own observed range.
# degree = 1 + surface = "direct" makes loess locally linear, so the
# extrapolated segments are a straight continuation of the boundary trend,
# with the SE (and so the ribbon) widening accordingly
post_rand_smooth <- data %>%
    ungroup() %>%
    filter(TimeSinceRandomisation >= 0) %>%
    group_by(Treatment) %>%
    group_modify(~ {
        fit <- loess(
            SpO2Value ~ TimeSinceRandomisation, data = .x,
            span = 0.75, degree = 1,
            control = loess.control(surface = "direct")
        )
        xseq <- seq(0, 120, length.out = 100)
        pred <- predict(fit, newdata = data.frame(TimeSinceRandomisation = xseq), se = TRUE)
        tibble(
            TimeSinceRandomisation = xseq,
            SpO2Value = pred$fit,
            se = pred$se.fit,
            df = pred$df
        )
    }) %>%
    ungroup() %>%
    mutate(
        ymin = SpO2Value - qt(0.975, df) * se,
        ymax = SpO2Value + qt(0.975, df) * se
    )

# produce a Lowess curve with separate pre- and post-randomisation segments
lowess_split_plot <- ggplot(data, aes(x = TimeSinceRandomisation, y = SpO2Value)) +
    # single combined linear trend pre-randomisation
    geom_smooth(
        data = data %>% filter(TimeSinceRandomisation < 0),
        aes(colour = "Pre-randomisation"),
        method = "lm", se = TRUE, fill = "grey70"
    ) +
    # separate curves per treatment post-randomisation
    geom_ribbon(
        data = post_rand_smooth,
        aes(x = TimeSinceRandomisation, y = NULL, ymin = ymin, ymax = ymax, group = Treatment),
        fill = "grey70", inherit.aes = FALSE
    ) +
    geom_line(
        data = post_rand_smooth,
        aes(x = TimeSinceRandomisation, y = SpO2Value, colour = Treatment),
        inherit.aes = FALSE, linewidth = 1
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
            legend.title = element_text(size = 14),
            legend.text = element_text(size = 12),
            axis.title = element_text(size = 16),
            axis.text = element_text(size = 14),
            panel.border = element_blank(),
            axis.line = element_line(colour = "black"),
            plot.margin = margin(5.5, 20, 5.5, 5.5)) +
    scale_y_continuous(limits = c(88, 100), breaks = seq(88, 100, by = 2), expand = expansion(mult = c(0, 0))) +
    coord_cartesian()

ggsave("output/figures/lowess_spo2_split.png", plot = lowess_split_plot, width = 8, height = 5, dpi = 300)
