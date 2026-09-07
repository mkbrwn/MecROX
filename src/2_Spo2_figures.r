#run previous script for cleaning data

source("src/1_clean_data.r")

common_plot_theme <- theme_bw(base_size = 16) +
    theme(
        legend.position = "inside",
        legend.position.inside = c(0.97, 0.97),
        legend.justification = c(1, 1),
        legend.background = element_rect(fill = alpha("white", 0)),
        legend.key = element_rect(fill = NA),
        legend.title = element_text(size = 14),
        legend.text = element_text(size = 12),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 14),
        panel.border = element_blank(),
        axis.line = element_line(colour = "black"),
        plot.margin = margin(5.5, 20, 5.5, 5.5)
    )

# produce a Lowess curve of SpO2 values over time since randomisation
lowess_plot_dot <- ggplot(data, aes(x = TimeSinceRandomisation, y = SpO2Value, colour = factor(Treatment))) +
    geom_point(alpha = 0.2, size = 0.5) +
    geom_smooth(data = data %>% filter(TimeSinceRandomisation >= 0), method = "loess", se = TRUE, span = 0.75) +
    scale_colour_brewer(palette = "Set1", name = "Treatment") +
    labs(
        x = "Time Since Randomisation (hours)",
        y = "SpO2 (%)"
    ) + 
    common_plot_theme + 
    theme(legend.position = "right", legend.justification = "center") +
    ylim(85, 100) +
    coord_cartesian()

ggsave("output/figures/lowess_spo2_dot.png", plot = lowess_plot_dot, width = 10, height = 5, dpi = 300)

# produce a Lowess curve with separate pre- and post-randomisation segments
lowess_split_dots_plot <- ggplot(data, aes(x = TimeSinceRandomisation, y = SpO2Value)) +
    geom_point(data = data %>% filter(TimeSinceRandomisation < 0), colour = "grey70", alpha = 0.2, size = 0.5) +
    geom_point(data = data %>% filter(TimeSinceRandomisation >= 0), aes(colour = factor(Treatment)), alpha = 0.2, size = 0.5) +
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
        method = "loess", se = TRUE, span = 0.75
    ) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40") +
    scale_colour_manual(
        name = "Treatment",
        values = c(
            "Pre-randomisation" = "grey40",
            setNames(
                RColorBrewer::brewer.pal(max(3, length(unique(data$Treatment))), "Set1")[seq_len(length(unique(data$Treatment)))],
                levels(factor(data$Treatment))
            )
        )
    ) +
    scale_x_continuous(breaks = seq(floor(min(data$TimeSinceRandomisation, na.rm = TRUE) / 24) * 24, 120, by = 24)) +
    labs(
        x = "Time Since Randomisation (hours)",
        y = "SpO2 (%)"
    ) + 
    common_plot_theme + 
    theme(legend.position = "right", legend.justification = "center") +
    ylim(85, 100) +
    coord_cartesian()

ggsave("output/figures/lowess_spo2_dots_split.png", plot = lowess_split_dots_plot, width = 10, height = 5, dpi = 300)

# produce a Lowess curve of SpO2 values over time since randomisation
lowess_plot <- ggplot(data, aes(x = TimeSinceRandomisation, y = SpO2Value, colour = factor(Treatment))) +
    geom_smooth(  data = data %>% filter(TimeSinceRandomisation >= 0),method = "loess", se = TRUE, span = 0.75) +
    scale_colour_brewer(palette = "Set1", name = "Treatment") +
    labs(
        x = "Time Since Randomisation (hours)",
        y = "SpO2 (%)"
    ) +
    common_plot_theme +
    scale_y_continuous(limits = c(88, 100), breaks = seq(88, 100, by = 2)) +
    coord_cartesian() +
    scale_x_continuous(limits = c(NA, 120), breaks = seq(0, 120, by = 24))

ggsave("output/figures/lowess_spo2.png", plot = lowess_plot, width = 8, height = 5, dpi = 300)



# produce a GAM curve of SpO2 values over time since randomisation
gam_plot <- ggplot(data %>% filter(TimeSinceRandomisation >= 0), aes(x = TimeSinceRandomisation, y = SpO2Value, colour = factor(Treatment))) +
    geom_smooth(method = "gam", formula = y ~ s(x), se = TRUE) +
    scale_colour_brewer(palette = "Set1", name = "Treatment") +
    labs(
        x = "Time Since Randomisation (hours)",
        y = "SpO2 (%)"
    ) +
    common_plot_theme +
    coord_cartesian()

ggsave("output/figures/gam_spo2.png", plot = gam_plot, width = 8, height = 5, dpi = 300)

# produce a mixed effects GAM with random intercept and slope for MECROXStudy
library(mgcv)

gamm_fit <- gamm(
    SpO2Value ~ s(TimeSinceRandomisation, by = factor(Treatment)) + factor(Treatment),
    random = list(MECROXStudy = ~1 + TimeSinceRandomisation),
    data = data %>% filter(TimeSinceRandomisation >= 0)
)

# generate predictions over a grid of time points for each treatment group
pred_data <- expand.grid(
    TimeSinceRandomisation = seq(
        0,
        max(data$TimeSinceRandomisation, na.rm = TRUE),
        length.out = 200
    ),
    Treatment = unique(data$Treatment)
)

preds <- predict(gamm_fit$gam, newdata = pred_data, se.fit = TRUE)
pred_data$SpO2Value <- preds$fit
pred_data$se <- preds$se.fit

gam_me_plot <- ggplot(pred_data, aes(x = TimeSinceRandomisation, y = SpO2Value, colour = factor(Treatment), fill = factor(Treatment))) +
    geom_ribbon(aes(ymin = SpO2Value - 1.96 * se, ymax = SpO2Value + 1.96 * se), alpha = 0.2, colour = NA) +
    geom_line(linewidth = 1) +
    scale_colour_brewer(palette = "Set1", name = "Treatment") +
    scale_fill_brewer(palette = "Set1", name = "Treatment") +
    labs(
        x = "Time Since Randomisation (hours)",
        y = "SpO2 (%)"
    ) +
    common_plot_theme +
    coord_cartesian()

ggsave("output/figures/gam_me_spo2.png", plot = gam_me_plot, width = 8, height = 5, dpi = 300)


